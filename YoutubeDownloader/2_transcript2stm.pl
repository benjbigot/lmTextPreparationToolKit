#!/usr/bin/perl -w
use strict;
use Data::Dumper;

#~ Usage
#~ $0 inDir/srtFile srtExt outputDir/stmFile stm Ext
#~ collection=MIT_Oppenheim/ ;  for i in $( find $collection/download/ -name "*.en.srt"); do perl 2_transcript2stm.pl $(dirname $i)/$(basename $i .en.srt) .en.srt $collection/transcripts/ ; done

#~  Description
#~ prepare a stm file from youtube transcription files

#~ -----------------------------------
# TODO: prepare the optargs sequence for argument disambiguation
my $inStem  = $ARGV[0];
my $inExt   = $ARGV[1];
my $outDir  = $ARGV[2];
if ($outDir eq ''){$outDir='.';}

$inStem  =~ s/\.$//;
$inExt   =~ s/^\.//;

my $inFile     = $inStem . '.'. $inExt;
if ( ! -e $inFile ){die "CHECK FILE NAME: unable to find $inFile\n";}

my $videoName  = (split(/\//, $inStem))[-1];
my $outFile    = $outDir . '/' . $videoName . '.stm' ;
if ( -e $outFile){print "ERROR: $outFile already exists\n;"}

print "video      : $videoName\n";
print "output file: $outFile\n";
print "output dir : $outDir\n";

#~ -----------------------------------

open(IN, $inFile) or die "unable to open $inFile\n";
my @trans = <IN>;
chomp(@trans);
close(IN);

#~ -----------------------------------

my %trans=();
for (my $item = 0; $item <= $#trans; $item++){
	next if ($trans[$item] eq '');
	
	if (($trans[$item] =~ m/^[0-9]+$/) and ($trans[$item+1] =~ m/[0-9:,]+ --> [0-9:,]+/)){
		# === get new segment === 
		my $segId     = $trans[$item];
		my $startTag  = (split(/-->/, $trans[$item+1]))[0];
		$startTag     =~ s/,/:/;
		my @startTime = split(/:/, $startTag);
		my $startTime = sprintf( "%0.3f", $startTime[0] * 3600.0 + $startTime[1] * 60.0 + $startTime[2] + $startTime[3] /1000.0);
		my $endTag    = (split(/-->/, $trans[$item+1]))[1];
		$endTag       =~ s/,/:/;
		my @endTime   = split(/:/, $endTag);
		my $endTime   = sprintf( "%0.3f", $endTime[0] * 3600.0 + $endTime[1] * 60.0 + $endTime[2] + $endTime[3] /1000.0);
		
		my @textContent = ();
		# === get text ===
		for (my $item2 = $item+2 ; $item2 <= $#trans; $item2++){
			last if (($trans[$item2] =~ m/^[0-9]+$/) and ($trans[$item2+1] =~ m/[0-9:,]+ --> [0-9:,]+/));
			push @textContent, $trans[$item2];
		}
		my $textContent = join(' ', @textContent);
		
		# === get speaker name in the text === 
		my $speaker      = 'unknown';
		if ($textContent =~ m/^[A-Z. ]+:/){
			my @temp     = split(/:/, $textContent);
			$speaker     = $temp[0];
			$textContent = join(' ', @temp[1 .. $#temp]);
		}
		$textContent =~ s/^ +//g;
		$textContent =~ s/ +$//g;
		$textContent =~ s/ +/ /g;
		$speaker     =~ s/ +/ /g;
		$speaker     =~ s/ /_/g;
		
		$trans{$segId}{'speaker'} = $speaker;
		$trans{$segId}{'text'}    = $textContent;
		$trans{$segId}{'start'}   = $startTime;
		$trans{$segId}{'end'}     = $endTime;
		
	}
}

## step 2: propagation of speaker name
my $currentSpeaker = 'unknown';
foreach my $id (sort {$a<=>$b} keys %trans){
	# speaker change
	if ($trans{$id}{'speaker'} ne $currentSpeaker){
		if ($trans{$id}{'speaker'} ne 'unknown'){
			$currentSpeaker = $trans{$id}{'speaker'};			
		}
		if ( ($currentSpeaker ne 'unknown') and ($trans{$id}{'speaker'} eq 'unknown')) {
			$trans{$id}{'speaker'} = $currentSpeaker ;
		}
	}	
}

# ================ step 3: concatenate sentence ============ #
my @segmentList = ();
my $segNumber =  scalar (keys %trans);

for (my $item = 0; $item <= $segNumber; $item++){
	next if (not exists $trans{$item});
	next if ($trans{$item}{'text'} eq '' );
	next if ($trans{$item}{'text'} =~ m/^\[[A-Z, -]+\]$/ );
	if ( ($trans{$item}{'text'} =~ m/^[A-Z]/) and  ($trans{$item}{'text'} =~ m/[.?!--]$/ )){
		push @segmentList, "$item $item $trans{$item}{'speaker'} S_E";
	}
	elsif ( ($trans{$item}{'text'} =~ m/^[A-Z]/) and ( $trans{$item}{'text'} !~ m/[.?!--]$/ )){
		push @segmentList, "$item $item $trans{$item}{'speaker'} S";
	}
	elsif ( ($trans{$item}{'text'} !~ m/^[A-Z]/) and ($trans{$item}{'text'} =~ m/[.?!--]$/ )){
		push @segmentList, "$item $item $trans{$item}{'speaker'} E";
	}
	elsif ( ($trans{$item}{'text'} !~ m/^[A-Z]/) and ($trans{$item}{'text'} !~ m/[.?!--]$/ )){
		push @segmentList, "$item $item $trans{$item}{'speaker'} C";
	}
	else{
		push @segmentList, "$item $item $trans{$item}{'speaker'} U";
		die "problem $item $item $trans{$item}{'speaker'} U";
	}
}
print "number of segment " . (scalar @segmentList) . "\n";

# === Giving an segment number to each sentence ==== #
my $counter = 0;
#~  idea segment index a incrementer
for (my $item = 0 ; $item < $#segmentList; $item++){
	#~ 
	my @currentLine = split(/ +/, $segmentList[$item]);
	my @nextLine = split(/ +/, $segmentList[$item+1]);
	my $currentSpeaker = $currentLine[2];
	my $nextSpeaker    = $nextLine[2];
	my $currentState   = $currentLine[3];
	my $nextState      = $nextLine[3];
	#~ 
	if ($currentSpeaker eq $nextSpeaker){
		if ($currentState eq 'S' and  $nextState eq 'S_E'){
			push @currentLine, $counter ;
			push @nextLine , $counter;
		}
		elsif($currentState eq 'S_E' and  $nextState ne 'E') {
			push @currentLine, $counter++ ;
			push @nextLine , $counter;
		}
		elsif($currentState eq 'S_E' and  $nextState eq 'E') {
			push @currentLine, $counter ;
			push @nextLine , $counter;
		}
		elsif($currentState eq 'C' and  $nextState eq 'C') {
			push @currentLine, $counter ;
			push @nextLine , $counter;
		}
		elsif($currentState eq 'C' and  $nextState eq 'E') {
			push @currentLine, $counter ;
			push @nextLine , $counter;
		}
		elsif($currentState eq 'C' and  $nextState eq 'S') {
			push @currentLine, $counter ;
			push @nextLine , $counter;
		}
		elsif($currentState eq 'C' and  $nextState eq 'S_E') {
			push @currentLine, $counter ;
			push @nextLine , $counter;
		}
		elsif($currentState eq 'S' and  $nextState eq 'E') {
			push @currentLine, $counter ;
			push @nextLine , $counter;
		}
		elsif($currentState eq 'S' and  $nextState eq 'S') {
			push @currentLine, $counter ;
			push @nextLine , $counter;
		}
		elsif($currentState eq 'S' and  $nextState eq 'C') {
			push @currentLine, $counter ;
			push @nextLine , $counter;
		}
		elsif($currentState eq 'E' and  $nextState eq 'S') {
			push @currentLine, $counter++ ;
			push @nextLine , $counter;
		}
		elsif($currentState eq 'E' and  $nextState eq 'S_E') {
			push @currentLine, $counter++ ;
			push @nextLine , $counter;
		}
		elsif($currentState eq 'E' and  $nextState eq 'E') {
			push @currentLine, $counter ;
			push @nextLine , $counter;
		}
		elsif($currentState eq 'E' and  $nextState eq 'C') {
			push @currentLine, $counter ;
			push @nextLine , $counter;
		}
		else{
			die "============ ERROR =======\n";
		}
	}
	elsif ($currentSpeaker ne $nextSpeaker){
		push @currentLine, $counter++ ;
		push @nextLine , $counter;
	}
	$segmentList[$item] = join(' ', @currentLine);
	$segmentList[$item+1] = join(' ', @nextLine);
#~ 
}
#~ foreach (@segmentList){print $_ ."\n";}
#~ exit;

#========== step 4: generating a new hash by concatenning segments ==== #
my %newTrans = ();
foreach my $line (@segmentList){
	my @line = split(/ +/, $line);
	my $oldId = $line[0];
	my $newId = $line[-1];
	
	if (not exists ($newTrans{$newId})){
		$newTrans{$newId}{'speaker'} = $trans{$oldId}{'speaker'};
		$newTrans{$newId}{'start'} = $trans{$oldId}{'start'};
		$newTrans{$newId}{'end'} = $trans{$oldId}{'end'};
		$newTrans{$newId}{'text'} = $trans{$oldId}{'text'};
	}
	else{
		$newTrans{$newId}{'end'} = $trans{$oldId}{'end'};
		$newTrans{$newId}{'text'} = $newTrans{$newId}{'text'} .' '.$trans{$oldId}{'text'};
	}
}

#~ foreach (@segmentList){print $_."\n";}


# ============  step 5: generating stm ================= #
if (! -d $outDir){
	print "creating output directory $outDir\n";
	print "output dir: $outDir\n";

	print "mkdir -p $outDir\n";
	mkdir $outDir;
}
if ( -f $outFile ){
	die "WARNING: output file $outFile already exists. Exiting... \n";
	exit;
}

open(OUT, "> $outFile") or die "unable to create $outFile\n";

my $text = <<'END_TXT';
;; 
;; LABEL "o" "Overall" "Overall results" 
;; LABEL "f0" "f0" "Wideband channel"
;; LABEL "f2" "f2" "Telephone channel"
;; LABEL "male" "Male" "Male Talkers"
;; LABEL "female" "Female" "Female Talkers"
;; 
END_TXT

print OUT $text;

foreach my $id (sort {$a<=>$b} keys %newTrans){
	if ($newTrans{$id}{'speaker'} eq 'unknown'){$newTrans{$id}{'speaker'} = 'unknown_'.$videoName }
	print OUT "$videoName 1 $newTrans{$id}{'speaker'} $newTrans{$id}{'start'} $newTrans{$id}{'end'} <o,f0,unknown> $newTrans{$id}{'text'}\n";
}
close(OUT);

# ========================= end ======================= #

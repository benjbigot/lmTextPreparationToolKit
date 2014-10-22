package cleanCorpus;
use strict;
use warnings;
use Number::Spell;
use Lingua::EN::Sentence qw(get_sentences);
use Exporter qw(import);
our @EXPORT_OK = qw(cleanArray);
#~ ==================== ~#

sub cleanArray{
	# input = RawTextArray
	# output = Clean TextArray one sentence a line
	# clean RawTextArray => CleanTextArray
	
	my (@inputArray) = (@_);
	my @textOut = ();
	my $field = 0;
	
	foreach my $line (@inputArray){		
		next if ($line =~ m/^;;/);
		my @line = split(/ +/, $line);
		next if ($#line <= 5);
		my $lineHead  = join(' ', @line[0 .. ( $field -1 )]);
		my $contentInLine = join(' ', @line[$field .. $#line]);
	
		###############################
		## First step: Content normalization ##
		###############################
		# TODO:
		# === email address ======= #
		# === url ======= #
		# ==== mathematical equations ==== #
		# === greek symbols === #

		# === tab in space === #
		$contentInLine =~ s/\t+/ /g;
		$contentInLine =~ s/ +/ /g;
		$contentInLine =~ s/^ +//g;
		$contentInLine =~ s/ +$//g;
	
		# === remove underscores === #
		$contentInLine =~ s/\_/ /g;
		$contentInLine =~ s/ +/ /g;
		$contentInLine =~ s/^ +//g;
		$contentInLine =~ s/ +$//g;
	
		# === split dashed terms === #
		$contentInLine =~ s/-/ /g;
		$contentInLine =~ s/ +/ /g;
		$contentInLine =~ s/^ +//g;
		$contentInLine =~ s/ +$//g;

		# === add a space between parenthesis, bracket and accolade and word === #
		$contentInLine =~ s/([\[\]{}\(\)])/ $1 /g;
		$contentInLine =~ s/ +/ /g;
		$contentInLine =~ s/^ +//g;
		$contentInLine =~ s/ +$//g;

		# == take care of the thousands and decimals == #
		$contentInLine =~ s/ ([0-9]+),([0-9]+) / $1$2 /g;
		$contentInLine =~ s/ +/ /g;
		$contentInLine =~ s/^ +//g;
		$contentInLine =~ s/ +$//g;

		# === add space between non decimal and decimal $4 => $ 4 and 4p.m. => 4 p.m. === #
		$contentInLine =~ s/(\D)([0-9]+)/$1 $2/gi;
		$contentInLine =~ s/([0-9]+)(\D)/$1 $2/gi;
		$contentInLine =~ s/ +/ /g;
		$contentInLine =~ s/^ +//g;
		$contentInLine =~ s/ +$//g;

		# === decimal numbers === #
		$contentInLine =~ s/ ([0-9]+) . ([0-9]+) / $1 point $2 /gi;
		$contentInLine =~ s/ +/ /g;
		$contentInLine =~ s/^ +//g;
		$contentInLine =~ s/ +$//g;

		# === currencies $ 48 point 30 => 48 dollars point 30 === #
		$contentInLine =~ s/ \$ / dollars /g;
		$contentInLine =~ s/ £ / pounds /g;
		$contentInLine =~ s/ € / euros /g;
		$contentInLine =~ s/ ¥ / yuans /g;
		$contentInLine =~ s/ +/ /g;
		$contentInLine =~ s/^ +//g;
		$contentInLine =~ s/ +$//g;

		# === percentage === #
		$contentInLine =~ s/%/ percents /g;	
		$contentInLine =~ s/ +/ /g;
		$contentInLine =~ s/^ +//g;
		$contentInLine =~ s/ +$//g;

		# === & === #
		$contentInLine =~ s/&/ and /g;	
		$contentInLine =~ s/ +/ /g;	
		$contentInLine =~ s/^ +//g;
		$contentInLine =~ s/ +$//g;

		# ===  protect acronymes with underscores === #
		$contentInLine =~ s/([a-zA-Z0-9])\.([a-zA-Z0-9])\./$1\_$2\_/gi;
		$contentInLine =~ s/ +/ /g;
		$contentInLine =~ s/\_([a-zA-Z0-9])\.([a-zA-Z0-9])/$1\_$2\_/gi;
		$contentInLine =~ s/ +/ /g;
		$contentInLine =~ s/([a-z])\. ([a-z])\. /$1\_$2\_ /g;
		$contentInLine =~ s/ +/ /g;
		$contentInLine =~ s/\_([a-z])\_ ([a-z])\. /\_$1\_$2\_ /g;
		$contentInLine =~ s/ +/ /g;
		$contentInLine =~ s/ +/ /g;
		$contentInLine =~ s/^ +//g;
		$contentInLine =~ s/ +$//g;
	
		# === removing isolated single quote === #
		$contentInLine =~ s/ \' / /g;	
		$contentInLine =~ s/ +/ /g;	
		$contentInLine =~ s/^ +//g;
		$contentInLine =~ s/ +$//g;
	
		# === Specific rules to be checked before splitting in line === #
		$contentInLine =~ s/ Dr. / Doctor /g;	
		$contentInLine =~ s/ Drs. / Doctors /g;	
		$contentInLine =~ s/ Pr. / Professor /g;	
		$contentInLine =~ s/ Mr. / Mr /g;	
		$contentInLine =~ s/ Mrs. / Mrs /g;	
		$contentInLine =~ s/ Ms. / Ms /g;	
		$contentInLine =~ s/ Fig. / Figure /g;	
		$contentInLine =~ s/ Tab. / Table /g;	
		$contentInLine =~ s/ +/ /g;
		$contentInLine =~ s/^ +//g;
		$contentInLine =~ s/ +$//g;	

		

		#############################
		### second step: cleaning content ###
		#############################
		# ========== split segment into sentences. =========== #
		# ========== # Normalization of sentences # ========== #
		
		my $tmp = get_sentences($contentInLine);
		my @contentInSentence = @$tmp;
	
		foreach my $s (@contentInSentence){
			my @splitLine = split(/ +/, $s);
			foreach my $term (@splitLine){			
				if ($term =~ m/[0-9]+/){				
					my $oldTerm=$term;
					$term = spell_number($term);
				}
				elsif ($term =~ m/[^[:alnum:]]+/){
					my $oldTerm=$term;
					my @splitTerm = split(//, $term);
					foreach my $symbol (@splitTerm){
						if ($symbol !~ m/[A-Za-z0-9\_\'-]/ ){
							$symbol=' ' ;
						}
					}
					$term = join('', @splitTerm);
				}
				else{
					# no action required
				}
				$term = lc($term);
			}
			$s = join(' ', @splitLine);
			
			$s =~ s/noiseevent//g;
			$s =~ s/^ +//g;
			$s =~ s/ +$//g;
			$s =~ s/ +/ /g;		
			if ($s ne ''){ push @textOut, $s;}
		}
	}
	return @textOut;
}
1;




sub postProcess{
	my ($lowerLength, $upperLength, $ratioSingleLetter, $ratioNewWord, $ratioNumber,  @inputArray) = (@_);
	
	
	my @outputArray = ();
	foreach my $line (@inputArray){
		my @splitLine = split(/ +/, $line);
		next if (scalar(@splitLine) <= $lowerLength );
		next if (scalar(@splitLine) >= $upperLength );
		
		# ------ remove sentence with too many single characters ------ #
		my $cumulWordLength=0;
		my %wordList= ();
		my $wordNumber = scalar(@splitLine);
		
		my @numbers= ('point','eight','eighteen','eighty','eleven','fifteen','fifty','five','forty','four','fourteen','hundred','nine','nineteen','ninety','one','seven','seventeen','seventy','six','sixteen','sixty','ten','thirteen','thirty','thousand','three','twelve','twenty','two','zero');
		my $wordInNumbers = 0;
		
		foreach my $word (@splitLine){
			$wordList{$word} = 0;
			my @wordSplit  = split(//, $word);
			my $wordLength = scalar(@wordSplit);
			$cumulWordLength+=$wordLength;
			
			if ($word ~~ @numbers){
				$wordInNumbers++;
			}
			
		}
		my $meanLengthWord = sprintf("%0.2f", $cumulWordLength/$wordNumber);
		next if ($meanLengthWord <= $ratioSingleLetter);
		
		# ------ remove sentences with redundant words ----- #		
		my @uniqWordList = ();
		foreach my $uWord (keys %wordList){
			push @uniqWordList, $uWord;
		}
		my $uniqWordNumber = scalar(@uniqWordList);
		my $realNewWordRatio = sprintf("%0.2f", $uniqWordNumber/$wordNumber);
		next if ($realNewWordRatio <= $ratioNewWord);
		
		
		my $propWordInNumber = sprintf("%0.2f", $wordInNumbers/$wordNumber);
		next if ($propWordInNumber >= $ratioNumber);
		push @outputArray, $line;
	}
	return @outputArray;
}
1;





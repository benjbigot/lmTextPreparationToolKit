#!/usr/bin/perl -w
#============================
# author: Benjamin Bigot
# contact: benjbigot@gmail.com
# date: 09/2014
#============================
use strict;
use File::Basename;
use IO::Uncompress::Bunzip2 qw(bunzip2 $Bunzip2Error) ;
use IO::Compress::Bzip2 qw(bzip2 $Bzip2Error) ;
use lib ('../lib/');
use CleanCorpus qw(cleanArray);

# ======================================== #

my $outfile   = $ARGV[1];
my $indexfile = $ARGV[2];

# ========================================= #
my $infile = new IO::File "< $ARGV[0]" or die "Cannot open '$ARGV[0]': $!\n" ;
my $buffer ;
bunzip2 $infile => \$buffer or die "bunzip2 failed: $Bunzip2Error\n";
my @contentSplit = split(/\n/, $buffer);


my %index = ();
my $topic = -1;
foreach my $line (@contentSplit){
	if ($line =~ m/^<doc id\=\"/ ){
		$topic = (split(/\"/, (split(/id\=\"/, $line))[1]))[0];
		my $title = (split(/\"/, (split(/title\=\"/, $line))[1]))[0];
		my $url = (split(/\"/, (split(/url=\"/, $line))[1]))[0];
		if ( !exists($index{$topic})){
			$index{$topic}{'header'} = $line;
			$index{$topic}{'title'} = $title;
			$index{$topic}{'url'} = $url;
			$index{$topic}{'text'} = ();
		}
		else{
			die "problem\n";
		}
	}
	elsif($line =~ m/^\<\/doc\>/){
		my @temp = CleanCorpus::cleanArray( @{$index{$topic}{'text'}});
		@{$index{$topic}{'text'}} = @temp;
		$topic = -1;
	}
	elsif ($topic != -1) {		
		next if ($line eq '');
		push @{$index{$topic}{'text'}}, $line ;
	}
}


open(OUT, ">$outfile") or die "unable to open $outfile\n";
open(IDX, ">>$indexfile") or die "unable to open $indexfile\n";
foreach my $id (keys %index){
	print OUT $index{$id}{'header'}."\n";
	foreach my $line (@{$index{$id}{'text'}}){
		print OUT $line."\n";
	}
	print OUT '</doc>'."\n";
	print IDX $index{$id}{'header'} . ' ' . $outfile.".bz2" . '</doc>' ."\n";
}
bzip2 $outfile => $outfile.".bz2" or die "bzip2 failed: $Bzip2Error\n";
unlink  $outfile;
	
close(OUT);
close(IDX);

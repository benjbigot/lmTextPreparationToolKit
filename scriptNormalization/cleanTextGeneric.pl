#!/usr/bin/perl

use strict;
use Number::Spell;
use Lingua::EN::Sentence qw(get_sentences);
use lib ('./lib/');
use cleanCorpus qw(cleanArray);


my $usage = "cat <file> | perl cleanTextGeneric.pl | gzip -c > <outFile> ";
#~ open(IN, "$inputDir/$file") or die "unable to open $inputDir/$file\n";
my @content = ();
while(<STDIN>){
	push @content, $_;
}

#######################################
## preprocessing for journal article ##
## to remove citation section        ##
#######################################
my @temp = ();
foreach my $line (@content){
	last if ( ($line =~ m/^REFERENCES$/i) or ( $line =~ m/^LITERATURE CITED$/) );
	push @temp, $line;
}

### prepare the text container ###
@content = @temp;
my $contentInLine = join(' ', @content);
@content = ();
push @content, $contentInLine;

### clean the text ###
if ($#content > 0){die "this should contain only one line\n";}
my @cleanText = cleanCorpus::cleanArray(@content);

my $minSizeSentence = 5;
my $maxSizeSentence = 1000;
my $ratioLetterWord = 2; # to remove t h e l i n e l i k e t h i s
my $ratioNewWordSize = 0.5; # to remove long sequence of redundant words
my $maxRatioNumberInLine = 0.9;
my @cleancleanText = cleanCorpus::postProcess($minSizeSentence, $maxSizeSentence, $ratioLetterWord, $ratioNewWordSize, $maxRatioNumberInLine, @cleanText);


foreach my $line (@cleancleanText){
	print $line ."\n";
}

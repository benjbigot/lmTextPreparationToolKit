#!/usr/bin/perl

#~ Usage: perl 3_normalizeStm.pl collection/file.stm stm collection/cleanText/ 6

use strict;
use Number::Spell;
use Lingua::EN::Sentence qw(get_sentences);
use lib ('./lib/');
use cleanCorpus qw(cleanArray);

#~ -----------------------------------
# TODO: prepare the optargs sequence for argument disambiguation
my $inStem  = $ARGV[0];
my $inExt   = $ARGV[1];
my $outDir  = $ARGV[2];
my $field   = $ARGV[3];
if ($field eq ''){$field = 6;}
if ($outDir eq ''){$outDir='.';}

if (! -d $outDir){
	print "creating output directory $outDir\n";
	print "output dir: $outDir\n";
	print "mkdir -p $outDir\n";
	mkdir $outDir;
}

$inStem  =~ s/\.$//;
$inExt   =~ s/^\.//;

my $inFile     = $inStem . '.'. $inExt;
if ( ! -e $inFile ){die "CHECK FILE NAME: unable to find $inFile\n";}

my $videoName  = (split(/\//, $inStem))[-1];
my $outFile    = $outDir . '/' . $videoName . '.stm' ;
my $outText    = $outDir . '/' . $videoName . '.text' ;
if ( -e $outFile){print "ERROR: $outFile already exists\n";exit;}

#~ =======================================

print "video: $videoName\n";
print "output file: $outFile\n";

#~ -----------------------------------

open(IN, "$inFile") or die "unable to open $inFile\n";
my @content = <IN>;
close(IN);		
chomp(@content);
	
my @stmOut = ();
my @textOut = ();


foreach my $line (@content){
	next if ($line =~ m/^;;/);
	my @line = split(/ +/, $line);
	my $lineHead  = join(' ', @line[0 .. ( $field -1 )]);
	my $contentInLine = join(' ', @line[$field .. $#line]);
	
	my @toProcess = ();
	push @toProcess, $contentInLine;
	my @cleanText = cleanCorpus::cleanArray(@toProcess);
	
	my $newContentLine = join(' ', @cleanText);
	my $outputLine = $lineHead . ' ' . $newContentLine;
	
	$outputLine =~ s/noiseevent/\[NOISE\]/g;	
	$outputLine =~ s/^ +//g;
	$outputLine =~ s/ +$//g;
	$outputLine =~ s/ +/ /g;
	$outputLine =~ s/^ +//g;

	$newContentLine =~ s/noiseevent//g;	
	$newContentLine =~ s/^ +//g;
	$newContentLine =~ s/ +$//g;
	$newContentLine =~ s/ +/ /g;
	$newContentLine =~ s/^ +//g;
	
	push @stmOut, $outputLine;
	push @textOut, $newContentLine;
}

# ========================== #
# == create ouput file ===== #
# ========================== #
	

open(OUT, "> $outText") or die "unable to open output file $outText\n";
foreach my $line (@textOut){
	print OUT $line."\n";
}
close(OUT);
	
open(OUT, "> $outFile") or die "unable to open output file $outFile\n";
foreach my $line (@stmOut){
	print OUT $line."\n";
}
close(OUT);

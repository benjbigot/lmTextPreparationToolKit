#!/usr/bin/perl -w
use strict;
use IO::Uncompress::Bunzip2 qw(bunzip2 $Bunzip2Error) ;
use Data::Dumper;

# ======================
open(IN, $ARGV[0]) or die "unable to open $ARGV[0]\n";
my @content = <IN>;
chomp(@content);
close(IN);
# ======================

foreach my $line (@content){
	
	my $fileName = (split(/</, (split(/>/, $line))[1]))[0];
	$fileName =~ s/ //g;
	my @line = split(/\t/ , $line);
	my $number = (split(/\"/, (split(/id=\"/, $line))[1]))[0];
	my $text;
	
	bunzip2 $fileName => \$text or die "bunzip2 failed: $Bunzip2Error\n";
	
	my @text = split(/\n/, $text);
	my @output = ();
	my $tag = 0;
	foreach my $line2 (@text){
		chomp($line2);
		last if (($line2 eq '</doc>') and ($tag == 1))  ;
		if ($line2 =~m / id=\"$number\"/ ){
			$tag = 1;
			next;
		}
		if ($tag == 1){
			push @output, $line2;
		}
	}
	open(OUT, "> ./forLM/$number.txt") or die "unable to open forLM/$number.txt\n";
	foreach (@output){
		print OUT $_."\n";
	}
	close(OUT);
}

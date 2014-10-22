#!/usr/bin/perl

# There seem to be a fair number of repeated sentences in
# the Gigaword corpus.  This removes redunant sentence lines
# from a single file in the corpus.
#
# Copyright 2007 by Keith Vertanen
#

use strict;

my $i;
my %lines;
my $numLines;
my $numOrig;

$i = 1;

while (<>) 
{
	# Always output any SGML tags
	if (/^</)
	{
		print $_;
	}
	else
	{
		$numLines++;

		# Only output the line if we haven't seen it before
		if (!$lines{$_})
		{
			$numOrig++;
			$lines{$_} = 1;	
			print $_;
		}
	}
	$i++;
}

print STDERR "TOTAL SENTENCES: $numLines   UNIQUE: $numOrig\n";


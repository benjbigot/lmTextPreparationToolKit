#!/usr/bin/perl

# The Gigaword corpus has some sentences split
# between paragraph tags.  This script looks
# at all the paragraphs in an article and
# merged things that are probably suppose to
# be the same sentence.
#
# Looks for paragraph ending [a-z] followed
# by one starting [a-z] and ending in period.
#
# Also deletes blank paragraphs caused by
# running BugProc.pl.
#
# Also adds a space at the end of each paragraph
# line since the "sentag" filter appears to eat
# the last thing on a line.
#
# Copyright 2007 by Keith Vertanen
#

use strict;

my $i;
my $artTag;
my @paraTag;
my @paraText;
my $numOrig;
my $numMerged;
my $inArt;
my $inPara;
my $paraTag;
my $j;

$i = 1;

while (<>) 
{
	if (/^\<art/)
	{
		# Starting a new article
		if ($inArt)
		{
			print STDERR "$i : <art> but already in <art>\n";
		}

		$inArt     = 1;
		$artTag    = $_;
		@paraText  = ();
		@paraTag   = ();
		$paraTag   = "";
	}
	elsif (/^\<\/art/)
	{
		# Ending an article, time to output
		if (!$inArt)
		{
			print STDERR "$i : </art> but not in <art>\n";
		}

		#print STDERR $artTag;
		#print STDERR "num para tags : " . @paraTag . "\n";
		#print STDERR "num para text : " . @paraText . "\n";

		if (@paraTag != @paraText)
		{
			print STDERR "$i : num tags " . @paraTag . " != num text " . @paraText . "\n";
		}
	   
		# Go backwards through the paragraphs looking
		# for something that looks like an end sentence
		# fragment.
		$j = @paraText - 1;
		while ($j > 1)
		{
			# See if the last one looks like a good sentence end
			# and the previous one ends in [a-z].
		    if ((@paraText[$j] =~ /^[a-z]+([\.\,]{0,1}[ ][A-Za-z0-9\-\'\`\$\%\#\(\)\+:\&]+)*\.$/) && (@paraText[$j - 1] =~ /[a-z]$/))

			{
				# Good, merge them
				
#				print STDERR "MERGED:\n";
#				print STDERR $paraText[$j - 1];
#				print STDERR $paraText[$j];

				$paraText[$j - 1] .= " ";
				$paraText[$j - 1] .= $paraText[$j];
				$paraText[$j]     = "";
				$paraTag[$j]      = "";				

				$numMerged++;
			}

			$j--;
		}

		# Dump out the article
		print $artTag;
		for ($j = 0; $j < @paraText; $j++)
		{
			if (($paraTag[$j]) && ($paraText[$j]))
			{
				print $paraTag[$j];
				# Add an extra space on the end of the line
				$paraText[$j] =~ s/[\n\r]//g;
				print $paraText[$j] . " \n";
				print "</p>\n";
			}
		}
		print "</art>\n";

		$inArt     = 0;
		$artTag    = "";
		@paraText  = ();
		@paraTag   = ();
		$paraTag   = "";	
	}
	elsif (/^\<p/)
	{
		# Start of paragraph
		if ($inPara)
		{
			print STDERR "$i : <p> but already in <p>\n";
		}

		# Remember the paragraph tag, only push into array
		# if we actually have a non-empty paragraph.
		$paraTag   = $_;
		$inPara    = 1;
	}
	elsif (/^\<\/p/)
	{
		# End of paragraph
		if (!$inPara)
		{
			print STDERR "$i : </p> but not in <p>\n";
		}

		$inPara = 0;
	}
	elsif (($inPara) && ($inArt))
	{
		# Actually sentence text
		push @paraText, $_;
		push @paraTag, $paraTag;
		$numOrig++;
	}

	$i++;
}

print STDERR "PARAGRAPHS: $numOrig   MERGED: $numMerged\n";


#!/usr/bin/perl

# After running BugProc.pl, BugProc2.pl
# and PruneRepeated.pl, there may be
# articles, paragraphs, or sentences that
# no longer have context.  Delete the 
# associated tags.
#
# Also looks for crazy tags that have 
# content gloomed on them, only accept
# tags that are <(art|p|s).(nyt|xie|apw|afe).
#
# Copyright 2007 by Keith Vertanen
#

use strict;

my $i;
my $artTag;
my @paraTags;
my @paraTexts;
my $inArt;
my $inPara;
my $inSent;
my @sentTags;
my @sentTexts;
my $sentTag;
my $sentText;
my $paraTag;
my $j;
my $badSent;
my $badPara;
my $badArt;
my $paraText;
my $numBadSent;
my $numBadPara;
my $numBadArt;
my $numNullSent;
my $numNullArt;
my $numNullPara;
my $numSent;
my $numPara;
my $numArt;

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

		$numArt++;

		$inArt     = 1;
		$artTag    = "";
		@paraTexts = ();
		@paraTags  = ();
		$paraTag   = "";
		$paraText  = "";
		$badSent   = 0;
		$badPara   = 0;
		$badArt    = 0;
		$sentText  = "";
		$sentTag   = "";

		# Check for good start tag
		if (/^\<art\.(afp|nyt|xin|apw|cna|ltw|wpb)/)
		#~ Changed by BB.
		#~ if (/^\<art\.(nyt|xie|apw|afe)/)
		{
			$badArt = 0;
			$artTag = $_;
		}
		else
		{
			$badArt = 1;
			$numBadArt++;
		}
	}
	elsif (/^\<\/art/)
	{
		# Ending an article, time to output
		if (!$inArt)
		{
			print STDERR "$i : </art> but not in <art>\n";
		}

		if (@paraTags != @paraTexts)
		{
			print STDERR "$i : num para tags " . @paraTags . " != num para text " . @paraTexts . "\n";
		}
	   
		# Dump out the article if it has content and not a bad start tag

		if ((@paraTags > 0) && (!$badArt))
		{
			print $artTag;
			for ($j = 0; $j < @paraTexts; $j++)
			{
				if (($paraTags[$j]) && ($paraTexts[$j]))
				{
					print $paraTags[$j];
					print $paraTexts[$j];
					print "</p>\n";
				}
			}		   
			print "</art>\n";
		}
		elsif (@paraTags == 0)
		{
			$numNullArt++;
		}

		$inArt     = 0;
		$artTag    = "";
		@paraTexts = ();
		@paraTags  = ();
		$paraTag   = "";	
	}
	elsif (/^\<p/)
	{
		# Start of paragraph
		if ($inPara)
		{
			print STDERR "$i : <p> but already in <p>\n";
		}

		$numPara++;

		# Remember the paragraph tag, only push into array
		# if we actually have a non-empty paragraph.
		$paraTag   = "";
		$inPara    = 1;
		$paraText  = "";		

		# Check for a good start tag
		if (/^\<p\.(afp|nyt|xin|apw|cna|ltw|wpb)/)
		#~ BB changed
		#~ if (/^\<p\.(nyt|xie|apw|afe)/)
		{
			$badPara = 0;
			$paraTag = $_;
		}
		else
		{
			$badPara = 1;
			$numBadPara++;
		}
	}
	elsif (/^\<\/p/)
	{
		# End of paragraph, add the sentence tags and text
		# that were not null or invalid.

		if (!$inPara)
		{
			print STDERR "$i : </p> but not in <p>\n";
		}

		# If paragraph had good tag and text, then add
		if (($paraText) && (!$badPara))
		{
			push @paraTexts, $paraText;
			push @paraTags, $paraTag;
		}
		elsif (!$paraText)
		{
			$numNullPara++;
		}

		$inPara   = 0;
		$paraText = "";
		$paraTag  = "";

	}
	elsif (/^\<s/)
	{
		# Start of sentence
		if ($inSent)
		{
			print STDERR "$i : <s> but already in <s>\n";
		}

		$numSent++;
		$sentTag  = "";
		$sentText = "";

		if (/^\<s\.(afp|nyt|xin|apw|cna|ltw|wpb)/)
		#~ BB changed
		#~ if (/^\<s\.(nyt|xie|apw|afe)/)
		{
			$badSent = 0;
			$sentTag = $_;
		}
		else
		{
			$badSent = 1;
			$numBadSent++;
		}

		$inSent = 1;
	}
	elsif (/^\<\/s/)
	{
		# End of sentence
		if (!$inSent)
		{
			print STDERR "$i : </s> but not in <s>\n";
		}
		
		# Only add sentence and tags to paragraph if it was valid
		# and not null.
		if (($sentText) && (!$badSent))
		{
			$paraText .= $sentTag;
			$paraText .= $sentText;
			$paraText .= $_;			
		}
		elsif (!$sentText)
		{
			$numNullSent++;
		}

		$inSent   = 0;
		$sentTag  = "";
		$sentText = "";

	}
	elsif (($inPara) && ($inArt) && ($inSent))
	{
		# Actually have sentence text
		$sentText = $_;
	}

	$i++;
}

print STDERR "TOTAL:  ARTICLES $numArt\tPARAGRAPHS $numPara\tSENTENCES $numSent\n";
print STDERR "NULL :  ARTICLES $numNullArt\tPARAGRAPHS $numNullPara\tSENTENCES $numNullSent\n";
print STDERR "BAD  :  ARTICLES $numBadArt\tPARAGRAPHS $numBadPara\tSENTENCES $numBadSent\n";




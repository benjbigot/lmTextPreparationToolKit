#!/usr/bin/perl

# Convert Gigaword XML format to the paragraph
# tagged version that the other CSR conditioning
# programs use.
#
# Reads file from STDIN, output to STDOUT.
# Error messages for to STDERR.
#
# Drops all <DOC> types except "story".  The
# "multi" type can sometimes be a good article,
# but sometimes it is a sequence of things with
# header bits, just eliminate all of them.
#
# Drops articles who have a headline that make
# us suspect cricket scores and the like.
#
# Copyright 2007 by Keith Vertanen
#

use strict;

my $line;
my $id;
my $inDoc;
my $inText;
my $inPara;
my $paraText;
my $lineLower;
my $inStory;
my $inHeadline;
my $i;
my $numPara;
my $posStart;
my $posEnd;
my $paraOutput;
my $headline;
my $badText;
my $outText;

#my $outLog;

#($outLog) = @ARGV;

#open(OUT_LOG, ">" . $outLog);

$i = 1;

while ($line = <>) 
{
	#print $line;
	$lineLower = lc($line);

	if (index($lineLower, "<doc") == 0)
	{
		# Check for improper closing of other tags	   
		if ($inPara)
		{
			print STDERR "$id, line $i, <DOC> hit but in <P>\n";			
			print "\n</p>\n";
			$inPara = 0;
		}
		if ($inText)
		{
			print STDERR "$id, line $i, <DOC> hit but in <TEXT>\n";			
			$inText = 0;
		}
		if ($inDoc)
		{
			print STDERR "$id, line $i, <DOC> hit but in <DOC>\n";			
			print "</art>\n";
		}

		# Starting a new doc, get the id and check that
		# it is of type "story", we drop any "advis",
		# "multi" or "other" document types.
		$inDoc      = 1;
		$id         = "";
		$inStory    = 0;
		$numPara    = 0;
		$inHeadline = 0;
		$badText    = 0;
		$outText    = "";

		if (index($lineLower, "story") != -1)
		{
			$inStory = 1;

			# Parse out the ID string
			$posStart = index($lineLower, '"');
			$posEnd   = index($lineLower, '"', $posStart + 1);

			if (($posStart == -1) || ($posEnd == -1))
			{
				print STDERR "line $i, <DOC> tag missing ID\n";
				$inDoc   = 0;
				$inStory = 0
			}
			else
			{
				$id = substr($lineLower, $posStart + 1, $posEnd - $posStart - 1);
				# Delay output until we make sure the headline is okay
			}		  
		}				
	}
	elsif (index($lineLower, "<headline") == 0)
	{
		# Track headline tag just so we can parse out articles
		# we don't want like sports scores.
		$inHeadline = 1;
	}
	elsif (index($lineLower, "</headline") == 0)
	{
		$inHeadline = 0;
	}
	elsif (index($lineLower, "<text") == 0)
	{
		# Check for improper closing of other tags	   
		if (!$inDoc)
		{
			print STDERR "$id, line $i, <TEXT> hit but not in <DOC>\n";
			if ($inStory)
			{
				$outText .= "<art." . $id . ">\n";
			}
			$inDoc = 1;
		}

		if ($inPara)
		{
			print STDERR "$id, line $i, <TEXT> hit but in <P>\n";
			if ($inStory)
			{
				$outText .= "\n</p>\n";
			}
			$inPara = 0;
		}
		if ($inText)
		{
			print STDERR "$id, line $i, <TEXT> hit but already in <TEXT>\n";
		}

		$inText = 1;

		# Open up the article if we are keeping it
		if ($inStory)
		{
			$outText .= "<art." . $id . ">\n";
		}
	}
	elsif (index($lineLower, "<p") == 0)
	{
		# Check for improper closing of other tags	   
		if (!$inDoc)
		{
			print STDERR "$id, line $i, <P> hit but not in <DOC>\n";
			if ($inStory)
			{
				$outText .= "<art." . $id . ">\n";
			}
			$inDoc = 1;
		}
		if ($inPara)
		{
			print STDERR "$id, line $i, <P> hit but in <P>\n";
			if ($inStory)
			{
			    $outText .= "\n</p>\n";
			}
		}
		if (!$inText)
		{
			print STDERR "$id, line $i, <P> hit but not in <TEXT>\n";
			$inText = 1;
		}

		$paraOutput = 0;
		$inPara = 1;
		$numPara++;

		if ($inStory)
		{
			$outText .= "<p." . $id . "." . $numPara . ">\n";
		}
	}
	elsif (index($lineLower, "</p") == 0)
	{
		# Check for improper closing of other tags	   
		if (!$inDoc)
		{
			print STDERR "$id, line $i, </P> hit but not in <DOC>\n";
			if ($inStory)
			{
				$outText .= "<art." . $id . ">\n";
			}
			$inDoc = 1;
		}
		if (!$inText)
		{
			print STDERR "$id, line $i, </P> hit but not in <TEXT>\n";
			$inText = 1;
		}

		if (!$inPara)
		{
			print STDERR "$id, line $i, </P> hit but not in <P>\n";
			# Don't close in this case
		}
		else
		{
			if ($inStory)
			{
				$outText .= "\n</p>\n";
			}

			$inPara = 0;
		}

	}	
	elsif (index($lineLower, "</text") == 0)
	{
		# Check for improper closing of other tags	   
		if (!$inDoc)
		{
			print STDERR "$id, line $i, </TEXT> hit but not in <DOC>\n";
		}
		if (!$inText)
		{
			print STDERR "$id, line $i, </TEXT> hit but not in <TEXT>\n";
		}
		if ($inPara)
		{
			print STDERR "$id, line $i, </TEXT> hit but in <P>\n";
			if ($inStory)
			{
				$outText .= "\n</p>\n";
			}
			$inPara = 0;
		}

		$inText = 0;
	}
	elsif (index($lineLower, "</doc") == 0)
	{
		# Check for improper closing of other tags	   
		if (!$inDoc)
		{
			print STDERR "$id, line $i, </DOC> hit but not in <DOC>\n";
		}
		if ($inText)
		{
			print STDERR "$id, line $i, </DOC> hit but in <TEXT>\n";
			$inText = 0;
		}
		if ($inPara)
		{
			print STDERR "$id, line $i, </DOC> hit but in <P>\n";
			if ($inStory)
			{
				$outText .= "\n</p>\n";
			}
			$inPara = 0;
		}

		# Only close if we were actually outputing
		if ($inStory)
		{
			$outText .= "</art>\n";

			# Make sure the text content wasn't bad before
			# outputting the whole thing.

			if (!$badText)
			{
				print $outText;
				$outText = "";
			}
			else
			{
				print STDERR "NUKED 5: $headline";
			}
		}

		$inDoc      = 0;
		$inStory    = 0;
		$inPara     = 0;
		$inText     = 0;
		$numPara    = 0;
		$paraOutput = 0;
	}
	elsif (($inPara) && ($inText) && ($inDoc) && ($inStory))
	{
		# Line is text of the story, strip any leading/trailing
		# whitespace from the line.

		# Seek and destoy any articles that look like there
		# is a table in them (like stock, sports scores, weather).
        #
		# Yuck, this looks for:
		#   spaces, a word, spaces, another word/num, spaces OR
		#   spaces, number, spaces, number
		#   start line, space(s), [number]., space(s), name, space(s), score/time/etc
		#   any 4 numbers surround by whitespace
		#   spaces, number like 1:29.309
		# 
		# This sometimes nails things it shouldn't but the majority rules.

		if (($line =~ /\s{2,}[A-Za-z0-9\-\.\%\$\+\/\(\)\,]{2,}\s{2,}[A-Za-z0-9\-\.\%\$\+\/\(\)\,]{1,}\s{2,}/) || 
			($line =~ /\s{2,}[0-9\.\-\+\%\$\/\(\)\,]{1,}\s{2,}[0-9\.\-\+\%\$\/\(\)\,]{1,}/) ||
			($line =~ /^\s+[0-9]{1,2}[\.]\s+[A-Za-z\s]{3,}\s+[0-9\.\:\-\(\)\/\%\$\+]/) ||
			($line =~ /(\s+[0-9\.\%\-\+\(\)\\]+){4,}\s+/) ||
			($line =~ /\s{2,}[0-9]+\:[0-9]+\.[0-9]+/))
		{
			$badText = 1;
		}
		else
		{
			$line =~ s/^\s{1,}//;
			$line =~ s/\s{1,}$//;

			# If we already output a line, then put in a space.
			if ($paraOutput)
			{
				$outText .= " ";
			}
			
			$outText .= $line;
			$paraOutput = 1;
		}
	}
	elsif ($inHeadline)
	{
		# This is the text headline, try and eliminate things
		# like sports scores.  Terminate cricket scores with
		# extreme prejudice.

		# Look for cricket keyword plus a nation
		if ((($lineLower =~ /scoreboard/) ||
			 ($lineLower =~ /scorecard/)) &&
			 (($lineLower =~ /england/) ||
			  ($lineLower =~ /new zealand/) ||
			  ($lineLower =~ /australia/) ||
			  ($lineLower =~ /pakistan/) ||
			  ($lineLower =~ /sri lanka/) ||
			  ($lineLower =~ /india/) ||
			  ($lineLower =~ /west indies/) ||
			  ($lineLower =~ /glamorgan/) ||
			  ($lineLower =~ /zimbabwe/) ||
			  ($lineLower =~ /south africa/) ||
			  ($lineLower =~ /bangladesh/)))
		{
			$inStory = 0;
			print STDERR "NUKED 1: $line";
		}
		# "score" + another word is a good guess at sports scores
		elsif (($lineLower =~ /score/) &&
			   (($lineLower =~ /cricket/) ||
			    ($lineLower =~ /inning/) ||
			    ($lineLower =~ /rugby/) ||
			    ($lineLower =~ /league/) ||
			    ($lineLower =~ /tea/) ||
			    ($lineLower =~ /golf/) ||
			    ($lineLower =~ /football/) ||
			    ($lineLower =~ /baseball/) ||
			    ($lineLower =~ /open/) ||
			    ($lineLower =~ /masters/) ||
			    ($lineLower =~ /pga/) ||
			    ($lineLower =~ /\sv\s/) ||
			    ($lineLower =~ /cup/)))
		{
			$inStory = 0;
			print STDERR "NUKED 2: $line";
		}
		elsif (($id =~ /afe/) &&
			   (($lineLower =~ /requested repetition/) ||
			    ($lineLower =~ /requested rptn/) ||
				($line =~ /REPETITION/) ||
				($line =~ /FIXING/) ||
				($line =~ /CORRECTION/) ||
				($line =~ /CORRECTED/) ||
				($line =~ /CORRECTS/) ||
				($line =~ /UPDATES/) ||
				($line =~ /CHANGING DATELINE/)))

		{
			# Avoid including repeated articles (AFE only)
			$inStory = 0;
			print STDERR "NUKED 3: $line";
		}
		elsif (($id =~ /apw/) &&
			   (($line =~ /REPEATING/) ||
			    ($line =~ /RETRANSMIT/) ||
				($line =~ /CORRECT/) ||
				($line =~ /UPDATES/) ||
				($line =~ /ADDS/) ||
				($line =~ /CHANGES/) ||
				($line =~ /COMBINES/) ||
				($line =~ /HOLD FOR RELEASE/) ||
				($line =~ /RESTRANSMIT/) ||
				($line =~ /NASDAQ Indexes/) ||
				($line =~ /Stock Indexes/) ||
				($line =~ /Active Stocks/) ||
				($line =~ /Big Movers in the Stock Market/) 			 
				))
		{
			# Avoid including repeated articles (APW only)
			# Also get rid of stock listings.
			$inStory = 0;
			print STDERR "NUKED 4: $line";
		}
		elsif (($lineLower =~ /football table/) ||
			   ($lineLower =~ /football results/) ||
			   ($lineLower =~ /nba standings/) ||
			   ($lineLower =~ /league table/) ||
			   ($lineLower =~ /nba results/) ||
			   ($lineLower =~ /championship scores/) ||
			   ($lineLower =~ /medals table/) ||
			   ($lineLower =~ /premiership table/) ||
			   ($lineLower =~ /cricket standings/) ||
			   ($lineLower =~ /nhl summaries/) ||
			   ($lineLower =~ /nba roundup/) ||
			   ($lineLower =~ /nba standings/) ||
			   ($lineLower =~ /nfl individual leaders/) ||
			   ($lineLower =~ /championship results/) ||
			   ($lineLower =~ /scores$/) ||
			   ($lineLower =~ /results$/) ||
			   ($lineLower =~ /(individual|baseball|scoring|nba|league|championship|nfl|nba|pga|playoff|points|al|nl|open|money|nasdaq|dollar) leaders$/)
			  )
		{
			# More sports filtering, some stock filtering
			$inStory = 0;
			print STDERR "NUKED 6: $line";
		}


		$headline = $line;

	}

	$i++;
}

close(OUT_LOG);

#!/usr/bin/perl

# Converts a CSR LM-1 text file into what
# we want to train an SRI LM.  Gets rids
# of any tags, makes lower case, and brackets
# sentences with <s> </s>
#
# This version gets rid of lines that have
# things that shouldn't be there like single symbols
# like "*" and numbered words like "17.50". 
#
# Some VP words are converted to words according
# to the "convert words" file.  I follow the original
# scripts and convert every 5th "DOUBLE-QUOTE word
# to "quote" to the NVP text.
#
# Outputs a VP and NVP version.
#
# Copyright 2007 by Keith Vertanen
#

use strict;

if ( @ARGV < 3 )
{
	print @ARGV;
    #~ print "$0 <input file> <VP output> <NVP output> <valid VP words> <allow words> <convert words> [debug]\n"; 
    print "$0 <input file> <valid VP words> <allow words> <convert words> [debug]\n"; 
    exit(1);
}

my $quoteCount;
my $convertFile;
my $fullFile;
my $vpFile;
my $nvpFile;
my $line;
my $validFile;
my %validVP;
my $nvpLine;
my @words;
my $i;
my $bad;
my $goodLines = 0;
my $badLines = 0;
my $debug = 0;
my $allowFile;
my %allowWords;
my %convertWords;

#~ ($fullFile, $vpFile, $nvpFile, $validFile, $allowFile, $convertFile, $debug) = @ARGV;
($validFile, $allowFile, $convertFile) = @ARGV;

# Read in all the words that are valid VP words
open(IN, $validFile);
while ($line = <IN>) 
{
    $line =~ s/[\n\r]//g;
	$line = lc($line);
	$validVP{$line} = 1;
}
close(IN);

# Read in file of VP that we convert to an actual word
open(IN, $convertFile);
while ($line = <IN>) 
{
    $line =~ s/[\n\r]//g;
	$line = lc($line);
	
	@words = split(/\s{1,}/, $line);

	if (@words > 1)
	{
		$convertWords{$words[0]} = $words[1];
	}
}
close(IN);

# Read in a file of exceptions that don't count as bad words
open(IN, $allowFile);
while ($line = <IN>) 
{
    $line =~ s/[\n\r]//g;
	$line = lc($line);
	$allowWords{$line} = 1;
}
close(IN);

#~ open(OUT_VP, ">" . $vpFile);
#~ open(OUT_NVP, ">" . $nvpFile);
# =================================== #
#~ open(IN, $fullFile);
#~ while ($line = <IN>) 
while ($line = <STDIN>) 
{
    $line =~ s/[\n\r]//g;
	$line = lc($line);
	
    # Make sure the line has some content and isn't one
	# of the markup tags.

	if ((index($line, "<art") != -1) ||
		(index($line, "<doc") != -1))
	{
		# Reset quote counter at article boundaries
		$quoteCount = 0;
	}
    elsif (($line =~ /\w/) && 
		(index($line, "<p.") == -1) &&
		(index($line, "<s.") == -1) &&
		(index($line, "</") == -1))

    {
		# Make a single pass through all the words, we'll look
		# for anything that makes it invalid and subject to
		# being dropped completely.  At the same time, remove
		# any VP words for output to the NVP file.
		$nvpLine = "";
		@words   = split(/\s{1,}/, $line);
		$i       = 0;
		$bad     = 0;

		while (($i < @words) && (!$bad))
		{
			if ($convertWords{$words[$i]})
			{
				# This is a valid VP word that needs to be converted
				# in the NVP version of the file.
			
				if ($nvpLine)
				{
					$nvpLine = $nvpLine . " ";
				}
				$nvpLine = $nvpLine . $convertWords{$words[$i]};
			}
			elsif (($validVP{$words[$i]}) || ($allowWords{$words[$i]}))
			{
				# A valid VP word, can't cause a bad line, but don't add 
				# to the NVP line.

				# Check for the special "DOUBLE-QUOTE business
				if (index($words[$i], "double-quote") != -1)
				{
					$quoteCount++;

					if (($quoteCount % 5) == 0)
					{
						if ($nvpLine)
						{
							$nvpLine = $nvpLine . " ";
						}
						$nvpLine = $nvpLine . "quote";
					}
				}
			}
			else
			{
				# Check the word against a bunch of rules made
				# from looking at the unigrams of the uncleaned
				# text.

				if (($words[$i] =~ /^\./) ||                           # .something
					($words[$i] =~ /[0-9]/) ||                         # no numbers
					($words[$i] =~ /^[\$\#\'\*\<\>\[\]\\\^\~\|]$/) ||  # lone symbol
					($words[$i] =~ /\w\w\.$/) ||                       # words ending in period
					($words[$i] =~ /[a-z]\.[a-z]/) ||                  # words with period in the middle
					($words[$i] =~ /\.\./))                            # anything with two periods

				{
					$bad = 1;

					#~ if ($debug)
					#~ {
						#~ print "BAD (" . $words[$i] . ") : " . $line . "\n";
					#~ }
				}

				if (!$bad)
				{
					if ($nvpLine)
					{
						$nvpLine = $nvpLine . " ";
					}
					$nvpLine = $nvpLine . $words[$i];
				}
			}			
			$i++;
		}

		if (!$bad)
		{
			$nvpLine =~ s/([a-z])\. ([a-z])\. /$1\_$2\_ /g;
			$nvpLine =~ s/ +/ /g;
			$nvpLine =~ s/\_([a-z])\_ ([a-z])\. /\_$1\_$2\_ /g;
			$nvpLine =~ s/ +/ /g;
			
			print "<s> " . $nvpLine . " </s>\n";
			#~ print OUT_NVP "<s> " . $nvpLine . " </s>\n";
			#~ print OUT_VP  "<s> " . $line . " </s>\n";
			$goodLines++;
		}
		else
		{
			$badLines++;
		}

    }
}
#~ close IN;

#~ close OUT_VP;
#~ close OUT_NVP;

#~ print $fullFile . "\t" . $goodLines . "\t" . $badLines . "\n";

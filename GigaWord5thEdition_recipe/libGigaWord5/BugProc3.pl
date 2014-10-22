#!/usr/local/bin/perl
#

# One final round of bug fixing before punctuation gets converted
# to verablized form.

use strict;
my $line;
my $drop;

while(<>)
{
    if (index($_, "<") == 0)
	{
		# All tag lines get passed as is
		print $_;
	}
	else
	{
		$drop = 0;

		# Convert single quotes '' and backwards quotes `` to double quote "
   		s/\'\'/\"/g;
		s/\`\`/\"/g;

		if (($_) && (!$drop))
		{
			print $_;
		}

	}
}


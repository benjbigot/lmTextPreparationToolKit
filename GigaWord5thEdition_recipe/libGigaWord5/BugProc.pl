#!/usr/local/bin/perl
# 
# Fixes some stuff in the newswire text.  Adapted
# from the bugproc.* scripts in CSR LM corpus.
#
# Added loads more to cleanup sports, datelines,
# errors, editor comments, you name it.
#

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

		# Do some whitespace munging straight off
		s/\t/ /g;			                # separate everything by spaces
		s/\s{2,}/ /g;                       # 2 spaces to 1
		s/^\s+//;                           # Delete leading whitespace
		s/\s+$/\n/;                         # Delete trailing whitespace

        # replace TIPSTER v.2 SGML entities with simple chars;
		s/\&amp;/&/ig;     
		s/\&plus;/+/ig;
		s/\&equals;/=/ig;
		s/\&minus;/-/ig;

        # square brackets are actually fractions;
		s/\&lsqb;/ 1\/8/ig; 
		s/\&rsqb;/ 3\/8/ig;

        # other funny characters are also fractions;
		s/\\/ 1\/4/g;  
		s/\{/ 1\/2/g;
		s/\|/ 5\/8/g;
		s/\}/ 3\/4/g;
		s/\~/ 7\/8/g;

		s/(\w)\(/$1 (/g;			        # eg. x( -> x (
		s/\)(\w)/) $1/g;	  		        # eg. )x -> ) x;

		s/(\d)\((\d)/$1 ($2/g;			    # \d(\d
		s/(\d)\)(\d)/$1) $2/g;			    # \d)\d;
		s/([a-zA-Z]{2,}\.)(\d)/$1 $2/g;		# eg. Sept.30
		s/,([a-zA-Z])/, $1/g;			    # eg. 20,Smith
		s/(\W)milion(\W)/$1million$2/g;		# spelling err

		s/(\W&\s*)Co([^\w\.-])/$1Co.$2/g;	# "& Co" -> "& Co."
		s/(\WU\.S)([^\.\w])/$1.$2/g;		# U.S -> U.S.

		# Some new things I added to handle number screw ups
		s/ l([0-9])/ 1$1/g;                 # leading "l" instead of "1"
		s/([0-9])l([0-9])/${1}1$2/g;        # "l" that should be "1" in the middle
		s/([0-9])l([ ,])/${1}1$2/g;         # trailing "l" that should be "1"

		s/ ([0-9]+)%% / $1% /g;             # 15%% -> 15%

		s/[0-9]O[ \)]/${1}0${2}/g;          # Trailing O that should be zero
		s/([ \(])O[0-9]/${1}0${2}/g;        # Leading O that should be zero
		s/[0-9]O[0-9]/${1}0${2}/g;          # Mid-O that should be zero

		s/[0-9], OO[0-9]/${1}, 00${2}/g;    # Things like "2, OO0-strong"

        # O's in a decimal 
		s/ ([0-9]+)\.([0-9]*)O([0-9]*) / ${1}\.${2}0${3} /g; 
		s/ ([0-9]*)O([0-9]*).([0-9]+) / ${1}0${2}.${3} /g; 

		# Get rid of starting datelines like: WARSAW, Poland (AP) - 
		# start line, word, comma, space, word, space, word in ()'s, space(s), dash/underscore/colon, space(s)
		s/^[A-Za-z]{2,}\, [A-Za-z]+ \([A-Za-z]+\)\s+[\_\-\:]{1,2}\s*//;

		# xie format dateline: LONDON, August 1 (Xinhua) -- 
		s/^([A-Za-z]{2,}[ ]*){1,}\, [A-Za-z]+ [0-9]+ \([A-Za-z]{2,}\)\s+[\-]+//;
		# Dateline like: LONDON (AP) _ 
		s/^[A-Za-z]{2,} \([A-Za-z]{2,}\) [\-\_\:]//;

		# Dateline like: WASHINGTON _ 
		s/^[A-Z]{3,} [\-\_]//;

		# Dateline like: KANSAS CITY, Mo. -- 
		s/^[A-Z ]+, [A-Za-z\.]+ [\-]{1,2}//;

		# Dateline: LONDON, May 13 (AFP) 
		s/^[A-Z -']*\,[A-Za-z0-9, -'#:]*\(AFP\)[ -:]*//;

		# Dateline: SUNSHINE-QUITS (Washington) -- The
		s/^[A-Z \-,\']+[ ]+\([A-Z a-z]+\)[ ]+[-_]+//;

		# Dateline: PARIS-- Defense
		# ALso catches some other starting labels like BACK TO EARTH AWARD -- Last year
		s/^[A-Z \'\-]+[\-\_]{2,}[ ]//;

		# Another dateline catcher, look for specific news sources like: (Xinhua)	   
		s/^[A-Za-z\,0-9\'\(\) \-\#\.\:\;]+\((Xinhua|XINHUA|xinhua|AFP|Xihua|NBC|Fox|TNT|airborne|AP|ESPN|espn|ap|tnt|Bloomberg|ABC|CBS|QNN)[A-Za-z\/ \-\'\,]*\)\s*[-_:]+//;
		
		# Xinhua specific datelines, look for anything like *(Xinhua) --
		# This one allows no dash to seperate.
		s/^[A-Za-z\,0-9\' \-]+\(Xinhua\)\s*[-_ :]+//;

		# Xinhua datelines, allow multiple ()'s around Xinhua.
		# Allow no following dashes.
		s/^[A-Za-z\,0-9\' \-]+[\(]+Xinhua[\)]+\s*[-_:]*//;

		# Xinhua datelines, like: (Xinhua) -- 
		s/^\(xinhua\)\s*[-_:]+//i;

		# Xinhua garbage at end of line like:
		# he said.  enditem  =01022049  =01022043  02/01/96 20:50 GMT nnnn	   
		s/[\(]*(enditem|Endtiem}Endityem|Ednitem|Enitem|ENDITEM|Editem|nditem|Enitem|eNDITEM|Endfitem|Endiem)[\.\)]*[ ]+[A-Za-z0-9 \=\/\:\,\*\-\'\)\(\.\#\$\%]*$//;

	    # 19/02/98 12:10 GMT NNNN 20:12 20:12 g PAB
	    s/[\.\"][A-Za-z0-9 \/\:\/\=\#]*PAB$//;
	
	    # Xinhua ending garbage, look for period and ending "GMT nnnn"
   	    s/\.[A-Za-z0-9 \/\:\/\=\(\)\-]* GMT nnnn$//;

	    # enterprises. More =02050555 NNNN 14:02 14:02 g # HAB
	    s/(More|more|\(more|\(More|\(more \)) \=[A-Za-z0-9 \/\:\/\=\(\)\-\#]*$//;
        # (to be continued) =08231238 =08231258 NNNN 20:37 20:38 g # PAB
        s/\([A-Za-z0-9 \/\:\/\=\(\)\-\#]*(PAB|HAB|nnnn)$//;
 
	    # year =02090354 09/02/95 04:03 GMT nnnn 
	    # =05141117 NNNN 19:24 19:24 g # HAB
	    s/\s+\=[0-9]{8}[A-Za-z0-9 \/\:\/\=\(\)\-\#]*(nnnn|HAB)$//;

	    # 03/05/95 15:11 GMT nnnn
  	    s/\s+[0-9]{2}\/[A-Za-z0-9 \/\:\/\=\(\)\-\#]*nnnn$//;


		# Some datelines are single captial words like: BEIRUT: 
		# This also gets some other stuff at the beginning of the
		# line, but these words probably should be conisdered part
		# of a properly formed sentence.	   
		s/^[A-Z]{3,}: //;

		# Nuke any GMT times inside ()'s, like "(0100 GMT Thursday)"
		# The time/day probably appears in the main text.
		s/\s*\([0-9]{4} GMT(\s[A-Za-z]+)*\)//g;

		# Bullet type points have a "-- " before them, just delete it.
		s/^-{2,} //g;

		# Lines ending with source like (AFP), (MORE)
		s/\((AFP|MORE|END)\)$//i;	   

		# numproc script will hang on tennis scores like: Cosac 6-7 (5/0)
		# Delete the fraction part after a X-Y
		s/([0-9])\-([0-9]) \([0-9]\/[0-9]\)/${1}\-${2}/g;

	    # Corrupt lines seem to contain captial letters and %'s.
	    # Anything that has A% or %A is suspect and we drop.
	    if ((/[A-Z]%/) || (/%[A-Z]/))
		{
			$drop = 1;
		}
		
		# Sports writers seem to be too stupid to get "21st, 22nd, 23rd" write.
		# Fix any 21th etc to the right thing.
		s/ ([0-9]*)([2-9])+1th / ${1}${2}1st/g;
		s/ ([0-9]*)([2-9])+2th / ${1}${2}2nd/g;
		s/ ([0-9]*)([2-9])+3th / ${1}${2}3rd/g;

		# Fix times that have a semi-colon instead of colon: 1;06.72
		s/([0-9]);([0-9]{2}).([0-9]{1,2 out at 1-1.})/${1}:${2}:${3}/g;

		# Get rid of strange numbers in ()'s like: (2&3)
		s/\([0-9]+&[0-9]+\)//g;

		# Fraction of 1/1 makes numproc unhappy, get rid of it
		s/ 1\/1 //g;
    
		# Change to a comma things like: 2.600th
		s/([0-9]{1,3})\.([0-9]{3})(th|nd|rd|th)/${1}\.${2}${3}/g;

        # No idea how to pronounce things like: at 1.6295/1.6305 against
		if (/[0-9]+\.[0-9]+\/[0-9]+\.[0-9]+/)
		{
			$drop = 1;
		}

		# Drop lines with silly number sequences like: 62-68-65-67_262 
		# Some sort of addition of scores.  In fact, get rid of any
		# sequence like this with three numbers.
		if ((/[0-9]+(-[0-9]+)+_/) ||
		    (/[0-9]+-[0-9]+-[0-9]/))
		{
			$drop = 1; 
		}

		# Lines with lots of "....." are probably a table of some sort
		if (/[\.]{5,}/)
		{
			$drop = 1;
		}

		# NYT, get rid of things like (EDS: Confirm local listings)
		s/\(EDS\:[A-Za-z0-9 \-\/\,\.\;\'\`]*\)//g;

		# Single word lines are probably junk, as are some APE ending lines
		# like "l0229 29Aou94"
		if ((/^[A-Za-z0-9\/]+$/) ||
		    (/^[A-Za-z0-9\/]+ [0-9]{1,2}[A-Za-z]{3}[0-2]{2}$/))
		{
			$drop = 1;
		}

		# AFE has instructions like "ADDS: blah blah" on lines that usually
		# end in double or triple forward slashes.  
        # Look for capital word surround by ()'s.
		# Other keywords denote instructions to the editors.
		# Drop lines containing just -'s and .'s
        if ((/\/\/$/) ||
            ((/^\([A-Z]{4,}[ ,]/) && (/\)$/)) ||
			(/^(ADDS|RECAST|UPDATE|CHANGING|CHANGES|EMBARGO|CORRECT|CLARIFIES|REPEAT|REPETION|\(changing)/) ||
			(/^[\-\.]+$/))  
		{
			$drop = 1;
		}

		# Some NYT garbage sentences
		if ((/^Transmission Complete$/) ||
			(/^No briefs this evening.$/) ||
			(/^(\-)+[0-9]+(\-)+$/) ||
			(/^(\.){2,}[0-9]/)
           )
		{
			$drop = 1;
		}

		s/^\s+//;                           # Delete leading whitespace

		if (($_) && (!$drop))
		{
			print $_;
		}

	}
}


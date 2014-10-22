#!/usr/local/bin/perl
#
# Second set of fixing Gigaword text.
# This set is used to fix problems after
# ParaTag.pl, BugProc.pl, ParaMerge.pl and
# sentag have been run.
# 
# Could be combined with BugProc.pl, but 
# it takes a long time to run that script.

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

		# Fix any 21th etc to the right thing.  BugProc.pl does this
		# except doesn't handle case when followed by something besides space.
		# Also allows starting with ( instead of space.
		s/([ \(\"])([0-9,]*)([02-9])+1(th|nd|rd)([\) \(,.\;\:\-\/\#\"])/${1}${2}${3}1st${5}/g;
		s/([ \(\"])([0-9,]*)([02-9])+2(th|st|rd)([\) \(,.\;\:\-\/\#\"])/${1}${2}${3}2nd${5}/g;
		s/([ \(\"])([0-9,]*)([02-9])+3(th|st|nd)([\) \(,.\;\:\-\/\#\"])/${1}${2}${3}3rd${5}/g;
		s/([ \(\"])([0-9,]*)([04-9])(st|rd|nd)([\) \(,.\;\:\-\/\#\"])/${1}${2}${3}th${5}/g;

		# And sports writers get it wrong the other way as well:
		# scored in the 13rd minute 		
		s/ ([0-9])*13rd/ ${1}13th/g;
		s/ ([0-9])*12nd/ ${2}12th/g;
		s/ ([0-9])*11st/ ${3}11th/g;

		s/ 1(th|nd|rd)/ 1st/g;
		s/ 2(th|st|rd)/ 2nd/g;
		s/ 3(th|st|nd)/ 3rd/g;

		# Fix fractions that have gotten a space in them:
		#  foot (1 /3 meter) long
		#  11 5 /8 inches,
		s/([ \(])([1-9]) \/([1-9]{1,2})([ \)\,\.])/${1}${2}\/${3}${4}/g;

		# Seperate slashes from numbers after a word: billion /2.6 billion 
		s/([a-z]) \/([0-9.]+) /${1} \/ ${2}/g;

		# Seperate num.(num) like: Studio 54.(212) 719-1300.
		s/ ([0-9]+)\.\([0-9]+\)/ ${1}\. ${2}/g;

		# Fix semi-colons in times:  begin at 4;30 a.m.
        # Also: at 2''30 p.m
		s/ ([0-9]{1,2})(\;|\'\')([0-9]{2})([ ,\.;\)\(])/ ${1}:${3}${4}/g;

		# Numbers inside //'s: reported /2.70/ Inches 
		s/ \/([0-9.]+)\/ / ${1} /g;

		# Fixed decimal numbers followed by -: (1.-25-mile)
		s/([0-9]+)\.\-([0-9]+)\-([A-Za-z])/${1}\.${2}-${3}/g;
		
		# Strange sports score format: 7-6,(6),
		s/([0-9]+\-[0-9]+\,)\([0-9]+\)\,/${1}/g;

		# Appear to missing second half of fractions: grow 2 1/ meters (8 feet) tall
		# Assume these fractions should be 1/2
		s/ ([0-9]+) 1\/ ([A-Za-z])/ ${1} 1\/2 ${2}/g;

		# Handle bible chapter:verse and chapter:verse-verse: Ezekiel 16:49, Genesis 19:1-29
		s/(genesis|exodus|leviticus|numbers|deuteronomy|joshua|judges|ruth|samuel|kings|chronicles|ezra|nehemiah|esther|job|psalms|proverbs|ecclesiastes|solomon|isaiah|jeremiah|lamentations|ezekiel|daniel|hosea|joel|amos|obadiah|jonah|micah|nahum|habakkuk|zephaniah|haggai|zechariah|malachi|matthew|mark|luke|john|acts|romans|corinthians|galatians|ephesians|philippians|colossians|thessalonians|timothy|tithus|philemon|hebrews|james|peter|john|jude|revelation)[ ,]+([0-9]+):([0-9]+)([ ,A-Za-z.\)\(])/${1} chapter ${2} verse ${3}${4}/gi;
		s/(genesis|exodus|leviticus|numbers|deuteronomy|joshua|judges|ruth|samuel|kings|chronicles|ezra|nehemiah|esther|job|psalms|proverbs|ecclesiastes|solomon|isaiah|jeremiah|lamentations|ezekiel|daniel|hosea|joel|amos|obadiah|jonah|micah|nahum|habakkuk|zephaniah|haggai|zechariah|malachi|matthew|mark|luke|john|acts|romans|corinthians|galatians|ephesians|philippians|colossians|thessalonians|timothy|tithus|philemon|hebrews|james|peter|john|jude|revelation)[ ,]+([0-9]+):([0-9]+)\-([0-9]+)/${1} chapter ${2} verses ${3} to ${4}/gi;

		# Two numbers with a _ is probably suppose to a dash: Blue Bulls 42_16 and
		s/([ \(])([0-9]+)_([0-9]+)([ ,\)])/${1}${2}-${3}${4}/g;

		# APW has lots of sentences with _'s that seem to denote a 
		# phrase that should be surround by commas:
		#   The play _ first staged in Krakow, Poland, in 1979 _ deals with the life
		s/ _ ([A-Za-z0-9 ,\'\`]+) _ /, ${1},/g;

		# Fix improper US phone number like:  (603)-881-9377.
		s/\([0-9]{3}\)\-([0-9]{3})\-([0-9]{4})([, .\(\)])/\(${1}\) ${2}-${3}${4}/g;

		# Drop second part of decimal notation like: traded at 3.0610/10
		s/([0-9]+)\.([0-9]+)\/([0-9])+ /${1}.${2} /g;

		# Fix fractions with space in them: fell 1-1/ 2 games back
		s/([0-9])\-([0-9])\/ ([0-9]) /${1}\-${2}\/${3}/g;

        # Put a space between numbers seperated by ()'s:  La Piedad's 37)(157 votes)
		s/([0-9])\)\(([0-9])/${1}\) \(${2}/g;

		# Fix dashes in numbers like: its 50,-000-member
		s/([0-9]+),-([0-9]{3})/${1},${2}/g;

		# Lines starting with an underscore are bullet items, get rid of underscore
		# Like: _The only justice not
		s/^_[ ]*//g;

		# Dates sometimes are followed by underscore: July 28, 2000_9th U.S. Circuit Court
		# Drop the underscore and replace with space.
		s/, ([0-9]{4})_/, ${1} /g;

		# Fix fractions with double slashes: at 130 7//8.
		s/([0-9])\/\/([0-9])/${1}\/${2}/g;

		# Fix period in number: the 2.600th anniversary
		s/([0-9])\.([0-9]{3})(th|st|nd|rd])/${1}\,${2}${3}/g;
	
	    # Seperate numbers connected by a & or ;
	    # Like: Routes 1&9 South OR  from 1.4832;1.4809 Canadian
	    s/ ([0-9\.]+)([\&\;])([0-9\.]+) / ${1} ${2} ${3} /g;

	    # Seperate number followed by slash and space.
	    # Like in phone numbers: with tel. no. 807-5537/ 825-6374.
	    s/([0-9])\/ ([0-9])/${1} \/ ${2}/g;
	    
	    # Seperate number folowed by space then slash and number.
	    # Like:  year 1998 /1999.
    	s/([0-9]) \/([0-9])/${1} \/ ${2}/g;

 	    # Seperate numbers with ) and , like: (8-6),6-3.
	    s/([0-9])\),([0-9])/${1}\), ${2}/g;

	    # Fix times that have extra space or period in them:
	    # Like:  at 10: 30 pm local
  	    s/([0-9]{2}):[ .] ([0-9]{2}) (am|pm|a\.m\.|p\.m\.|GMT|gmt)/${1}:${2} ${3}/g;
  	    s/([0-9]{2})[ .]:([0-9]{2}) (am|pm|a\.m\.|p\.m\.|GMT|gmt)/${1}:${2} ${3}/g;

	    # Seperate percent from following () phrase, like: play 17.6%(6th)
 	    s/([0-9])%\(/${1}% \(/g;

	 # Lone _ are floating around in NYT and APW articles.
	 # Two seperated by words should be a commad delimited phrase.
	 # Like:  family _ having sold its cellular phone empire to AT&T _ has 
	 #s/ _ ([a-z A-Z0-9\-\(\)\`\'\\$\%\&\#])+ _ /, ${1}, /g;
	 # changed, will just convert all lone " _ " to commas

	 # Get rid of things all in caps on LHS followed by " _ "
	 # Like: ATLANTA _ The online
	 s/^[A-Z \-\'\`]{2,} _ //;
	
	 # More datelines like: ITZHAR, West Bank _ Amid 
	 s/^[A-Z \-\']{2,}, [A-Z a-z\-\']* _ //;

	 # Mixed cased datelines like: Vidor, Texas _ Ku Klux Kla
	 s/^([A-Z][a-z\-\']+)+, ([A-Z][a-z\-\']+)+ _ //;

	 # Not clear what type of punctuation a " _ " should be.
	 # Usually a comma, but sometimes a colon or dash might
         # also work. 
	 s/ _ /, /g;

		# Drop garbage lines like: to2410th51letoa
		if (/ [a-z]+[0-9]+[a-z]+[0-9]/)
		{
			$drop = 1;
		}

	   # Drop crazy phone numbers: tel: 03-8293794/5/6  03-8253325 
		if ((/ [0-9]+\-[0-9]{3,}\/[0-9]{2,}/) ||
			(/ [0-9]{2}\-[0-9]{5,}/))
		{
			$drop = 1;
		}

		# Drop lines with bad US format phone numbers: Call (228)-6325 for
		if (/ \([0-9]{3}\)\-[0-9]{4} /)
		{
			$drop = 1;
		}

		# Drop numbers like: (7:189; 16:97; 33:35) 
		if (/[0-9]+\:[0-9]+\;/)
		{
			$drop = 1;
		}
		
		# Drop silly lists of number with slashes
		if (/[0-9]+\/[0-9]+\/[0-9]+\/[0-9]+/)
		{
			$drop = 1;
		}

		# Drop lines like: 10.(15) ``60 Minutes,'' CBS, 8.8, 9.0 million homes.
		if (/[0-9]+\.[ ]*\([0-9]+\)/)
		{
			$drop = 1;
		}

		# Drop scores, the 21_98 kills numproc: L.A. Lakers 25 24 28 21_98
	    # Also like: Manta 5_7, 6_4, 6_3
		if ((/([0-9]+ )+[0-9]+_[0-9]+/) ||
			(/[0-9]*_[0-9]*,[ ]*[0-9]*_[0-9]*/))
		{
			$drop = 1;
		}

		# Drop lines with URLs in them
		if ((/http:\/\//) ||
			(/(www|WWW)\.[A-Za-z]+\./) ||
			(/\.(com|org|net|edu)\//)) 
		{
			$drop = 1;
		}

	 
	# Drop lines with capital letters followed or preceeded by _
	# Like: Rebounds_UNLV 33 (D.JJohnson 12)
	if ((/_([A-Z]){2,}/) ||
            (/([A-Z]){2,}_/))
		{
			$drop = 1;
		}

		if (($_) && (!$drop))
		{
			print $_;
		}

	}
}


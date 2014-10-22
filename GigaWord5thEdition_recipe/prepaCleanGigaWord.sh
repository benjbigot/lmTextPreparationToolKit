#!/bin/bash
# author: Benjamin Bigot
# date: 09/2014
# email: benjbigot@gmail.com

# description:
# recipe for GigaWord preparation for language modelling.
# based on the code of http://www.keithv.com/
# required: Perl, C ansi

# ============================================== #
# usage: bash $0 <absolute path to GigaWord>
GIGA_DATA=$1
#~ GIGA_DATA=/local/Database/LDC2011T07-EnglishGigawordFifthEdition
OUT_DIR=$2

# =============================================== #

if [[ $OUT_DIR == '' ]]; then
	LOG_V=$$
	OUT_DIR="./OUT_$LOG_V"
fi
if [[ -d $OUT_DIR ]]; then
	echo "output directory already exists, will overwrite existing files"
fi
mkdir -p $OUT_DIR > /dev/null 2>&1

# ============================================== #
lib='./libGigaWord5'

for infile in $(find $GIGA_DATA -name "*.gz"); do 
		outfile=$OUT_DIR/$(basename $infile)
		echo $infile "=>" $outfile

		if [[ -f $outfile ]]; then
			echo "$outfile already existsPassing $outfile"
		else
			# extracting stories
			# fixing Bugs
			# merge sentence
			# group in sentences 

			gunzip -d -c $infile       |\
			perl $lib/ParaTag.pl       |\
			perl $lib/BugProc.pl       |\
			perl $lib/ParaMerge.pl     |\
			./$lib/sentag              |\
			perl $lib/PruneRepeated.pl |\
			perl $lib/BugProc2.pl      |\
			perl $lib/CleanTags.pl     |\
			perl $lib/numproc          |\
			perl $lib/abbrproc         |\
			perl $lib/BugProc3.pl      |\
			perl $lib/puncproc -np     |\
			perl $lib/ConvertClean.pl valid_vp.txt valid_other.txt valid_convert.txt |\
			iconv -t UTF-8//IGNORE | gzip -c > $outfile
		fi
	done
done

exit 1;




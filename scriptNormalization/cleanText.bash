#!/bin/bash
# To change the end-of-line marker
IFS=$'\n'

#################################
# Tested on Ubuntu 12.04
# need Perl 5
# requires Number::Spell to convert numeric to letters
# sudo cpan -i Number::Spell
# sudo apt-get install dos2unix
# sudo apt-get install iconv
#
################################
usage="usage: $0 <path/to/input/directory>"

if [ $# -ne 1 ]; then 
	echo $usage
	exit 0
fi

if [[ ! -d $1 ]]; then
	echo "$1 does not exists"
	echo $usage
	exit 0
fi

#################################

logValue=$$

toProcess=$1
logFile=./$logValue.log
workDir=./$logValue.rawFiles
outDir=./$logValue.cleanFiles
lmDir=./$logValue.lmFiles

mkdir $workDir || exit 0 >> $logFile 2>&1
mkdir $outDir  || exit 0 >> $logFile 2>&1
mkdir $lmDir   || exit 0 >> $logFile 2>&1

echo ==== input files in $toProcess
echo =========== logs in $logFile
echo ====== raw files in $workDir
echo ==== clean files in $outDir
echo = language model in $lmDir

##################################################
# step 0: backup files from $toProcess to $workDir
for file in $(find $toProcess -type f); do
	echo "$file ==> $workDir" >> $logFile 2>&1
	cp $file $workDir/ || exit 0 >> $logFile 2>&1
done
echo "$(echo $(ls $workDir | wc -l )) files copied" >> $logFile 2>&1

###################################################
# step 1: format file names in $workDir
rename 's/ /_/g' $workDir/*

####################################################
# step 2: special cases
for file in $(find $workDir -name "*.pdf"); do 
	echo processing pdftotext on $file
	pdftotext $file  >> $logFile 2>&1
	rm $file         >> $logFile 2>&1
done

for file in $(find $workDir -name "*.gz"); do 
	echo unzipping $file
	gunzip $file >> $logFile 2>&1
	rm $file     >> $logFile 2>&1
done

####################################################
# step 3: Windows to Linux conversion
for file in $(find $workDir -type f); do 
	dos2unix $file >> $logFile 2>&1
done

######################################################
# step 4: UTF8 conversion
for file in $(find $workDir -type f); do 
	iconv -t UTF-8//IGNORE $file -o $workDir/temp >> $logFile 2>&1	
	mv $workDir/temp $file
done

###############################################################
# step 5: cleaning text files using a Perl script
for file in $(find $workDir -type f); do
	cat $file | perl cleanTextGeneric.pl | sort -u |  add-start-end.sh | gzip -c > $outDir/$(basename $file).gz 
done

###############################################################
# step 6: Language modeling
rm $lmDir/text.txt.gz >> $logFile 2>&1
rm $lmDir/log >> $logFile 2>&1
echo $outDir

for file in $(find $outDir -name "*.gz"); do 
	gunzip -dc $file | wc >> $lmDir/log
	gunzip -l $file | tail -n1 >> $lmDir/log
	gunzip -dc $file >> $lmDir/text.txt
done
	sort -u $lmDir/text.txt -o $lmDir/text.txt
	wc $lmDir/text.txt >> $lmDir/log
	du -hs $lmDir/text.txt >> $lmDir/log	
	gzip $lmDir/text.txt
	sed -i 's/ \+/ /g'  $lmDir/log

build-lm.sh -i "gunzip -c $lmDir/text.txt.gz " -o $lmDir/text.ilm.gz -k 4 -n 5 -s kneser-ney -v
compile-lm $lmDir/text.ilm.gz --text=yes /dev/stdout | gzip -c > $lmDir/text.lm.gz
dict -i="gunzip -c $lmDir/text.txt.gz" -o=$lmDir/text.dict -f=y -sort=yes
rm $lmDir/text.txt.gz >> $logFile 2>&1
################################################################
echo "process is over"


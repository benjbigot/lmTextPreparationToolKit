#!/bin/bash

#~ Description
#~ ============
#~ download a video and transcriptions from Youtube by passing the url as an argument

# Usage 
#========
# url to a YouTube video ($linkName) ===== Process ======>  $outDir/transcript/$videoName.txt $outDir/video/$videoName.txt  
# usage: $0 http://youtube... ./lecture/....

link=$1
outputDir=$2
#~ logFile=
extractAudio=1

if [ $# -ne 2 ]; then 
	echo "illegal number of parameters"
	exit 1
fi

# creating output directory
for i in  download audio transcripts cleanText; do
	if [ ! -e $outputDir/$i ]; then 
		echo "creating $outputDir/$i"
		mkdir -p $outputDir/$i
	else 
		echo "$outputDir/$i already exists."
	fi
done


#~ download video and transcripts
youtube-dl -c -o $outputDir/download/'%(title)s.%(ext)s' --no-overwrite --restrict-filenames --write-sub $link

#~ Converting audio
if [ $extractAudio ] ;then
	for videoName in $(find $outputDir/download -name "*.mp4"); do 
		echo $videoName		
		avconv -i $videoName -ac 1 -ar 16000 $outputDir/audio/$(basename $videoName .mp4).wav
	done
fi


#~ ==========================================
#~  Help section 

# Youtube-dl
#~ ==========
# https://github.com/rg3/youtube-dl/blob/master/README.md
# sudo curl https://yt-dl.org/latest/youtube-dl -o /usr/local/bin/youtube-dl
# sudo chmod a+x /usr/local/bin/youtube-dl
#~ The list of option of youtube-dl is long

#An example: Youtube-dl --ct --write-sub [URL]
#--ct: conitnue | embeded title
#--write-sub: 
##~ youtube-dl -c -o 'originaldata/%(title)s-%(id)s.%(ext)s' --restrict-filenames --write-sub $linkName

# second step AV processing 
#2.1 extract audio from video
#"ffmpeg" is used to extract the audio from video. You can refer to the "http://linuxers.org/tutorial/how-install-ffmpeg-linux" on the installation and more details about "youtube-dl". The audio should be one channel, 16000Hz sample rate, and the in the format of 'WAV'.
# An example: ffmpeg -i "mp4file" -ac 1 -ar 16000 "wavFile"

#~ ffmpeg -i $outDir/originaldata/$videoname.mp4 -ac 1 -ar 16000 $outDir/audio/$videoname.wav
#~ for videoname in $(find $outDir/originaldata/ -name "*.mp4") ;do
	#~ echo $outDir/originaldata/$videoname "=>" $outDir/audio/$(basename $videoname .mp4).wav
	#~ avconv -i $outDir/originaldata/$videoname -ac 1 -ar 16000 $outDir/audio/$(basename $videoname .mp4).wav
	#~ python transcript_generation.py $outDir/originaldata/$(basename $videoname .mp4) $outDir/transcript/$(basename $videoname .mp4).txt
	#~ python sentline.py $outDir/transcript/$(basename $videoname .mp4).txt $outDir/sentline/$(basename $videoname .mp4).stm
	#~ python sentline_nopunctuation.py $outDir/originaldata/ $outDir/sentline_nopunctuation
#~ done
#2.2 transcript process.
#The format of the original transcript is listed as follows:
#YouTube transcript ===> | transcript_generation.py | ===> stm-like format
#first lines of the manual transcript from youtube

#"transcript_generation.py" is used to transfer the format of the original transcript to the format like the follows:

###### before ####
#1
#00:00:09,929 --> 00:00:16,929
#Hello, there everybody. In this video course
#on fluid mechanics the main objectives are
### after ###
#Lec-1 00:00:09,929 0:00:16,929 Hello, there everybody. In this video course on fluid mechanics the main objectives are 
###



##"sentline.py" is used to transfer the format of the original transcript to the format "one sentence a line".
### example ####
##Hello, there everybody.
##In this video course on fluid mechanics the main objectives are  introduce fluid mechanics and establish its relevant in civil engineering develop the  fundamental principles demonstrates how these are used in engineering, especially in civil  engineering field.
#################



##To remove punctuation marks and some text normalization (for numbers)
##"senline_nopunctuation.py": extract the contents from the transcript and save as per line per sentence and change the dot in fraction to point, and then delete all the punctuation. For example, 0.99 --> 0 point 99.
### example ####
#Hello there everybody 
#In this video course on fluid mechanics the main objectives are introduce fluid mechanics and establish its relevant in civil engineering develop the fundamental principles demonstrates how these are used in engineering especially in civil engineering field 
################


#/bin/bash

# Source our config files
source config.sh

# Introuduce the program to the user
echo " "
echo " "
echo "--------------------------------------------------"
echo "Please wait while we initialize the stream..."
echo "--------------------------------------------------"
echo " "
echo " "

# ensure our alsa is set up right
sudo modprobe snd-aloop pcm_substreams=1

# Allow for CTRL+C to exit
trap "exit" SIGINT

# Define Our Private Temporary Variables
STREAM_GIF_PATH="/tmp/streamGif"
CURRENT_GIF_PATH="/tmp/CURRENT_GIF.txt"
STREAM_TEXT_PATH="/tmp/stream.txt"
CURRENT_GIF=""
RANDOMSONG=""
ARTIST=""
SONG_NAME=""

# Generate an optimized gif
CURRENT_GIF="$STREAM_GIF_PATH$(date +%s).gif"
echo "$CURRENT_GIF" > $CURRENT_GIF_PATH
./optimizeGif.sh $(./getFileFromDir.sh $GIF_DIRECTORY) $CURRENT_GIF

echo " "
echo " "
echo "--------------------------------------------------"
echo "Starting the stream..."
echo "--------------------------------------------------"
echo " "
echo " "

while true ; do
      # Get our random song
      RANDOMSONG=$(./getFileFromDir.sh $MUSIC_DIRECTORY)

      # Create our video text from the random song
      rm $STREAM_TEXT_PATH
      ARTIST=$(id3info "$RANDOMSONG" | grep TPE1 | head -n 1 | perl -pe 's/.*: //g')
      SONG_NAME=$(id3info "$RANDOMSONG" | grep TIT2 | head -n 1 | perl -pe 's/.*: //g')
      echo "Artist: $ARTIST" >> $STREAM_TEXT_PATH
      echo " " >> /tmp/stream.txt
      echo "Song: $SONG_NAME" >> $STREAM_TEXT_PATH

      # Create our two threads of audio playing, and the stream
      # Run the commands, and wait for either to finish
      # Also, optimize the next gif, while the stream is playing
      ( /usr/bin/mpg123 "$RANDOMSONG" ) & \
      ( ./runFfmpeg.sh $(cat $CURRENT_GIF_PATH) &
      sleep 2; \
      CURRENT_GIF="$STREAM_GIF_PATH$(date +%s).gif"; \
      echo "$CURRENT_GIF" > $CURRENT_GIF_PATH
      ./optimizeGif.sh $(./getFileFromDir.sh $GIF_DIRECTORY) $CURRENT_GIF &
      wait ) & wait -n

      # Kill the other command if one finishes
      pkill -P $$
      # Ensure both are completely killed (Fixes Alsa device busy)
      sudo killall ffmpeg
      sudo killall mpg123
      sudo killall generateGif

      # Loop to the next song
      echo " "
      echo " "
      echo "--------------------------------------------------"
      echo "Playing next song..."
      echo "--------------------------------------------------"
      echo " "
      echo " "
done
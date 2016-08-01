#!/bin/sh


VP9_LIVE_PARAMS="-speed 6 -tile-columns 4 -frame-parallel 1 -threads 3 -static-thresh 0 -max-intra-rate 300 -deadline realtime -lag-in-frames 0 -error-resilient 1"

ffmpeg \
  -f v4l2 -input_format mjpeg -r 30 -s 640x360 -thread_queue_size 1024 -i /dev/video0 \
  -f alsa -ar 48000 -ac 1 -thread_queue_size 1024 -i pulse \
  -map 0:0 \
  -pix_fmt yuv420p \
  -c:v libvpx-vp9 \
    -s 640x360 -keyint_min 60 -g 60 ${VP9_LIVE_PARAMS} \
    -b:v 1000k \
  -aspect 16:9 \
  -f webm_chunk \
    -header "/var/www/html/live/glass_360.hdr" \
    -chunk_start_index 1 \
  /var/www/html/live/glass_360_%d.chk \
  -map 1:0 \
  -c:a libvorbis \
    -b:a 64k -ar 48000 \
  -f webm_chunk \
    -audio_chunk_duration 2000 \
    -header /var/www/html/live/glass_171.hdr \
    -chunk_start_index 1 \
  /var/www/html/live/glass_171_%d.chk

#!/bin/sh



ffmpeg \
  -f webm_dash_manifest -live 1 \
  -i /var/www/html/live/glass_360.hdr \
  -f webm_dash_manifest -live 1 \
  -i /var/www/html/live/glass_171.hdr \
  -c copy \
  -map 0 -map 1 \
  -f webm_dash_manifest -live 1 \
    -adaptation_sets "id=0,streams=0 id=1,streams=1" \
    -chunk_start_index 1 \
    -chunk_duration_ms 2000 \
    -time_shift_buffer_depth 7200 \
    -minimum_update_period 7200 \
    -utc_timing_url "https://linuxbierwanderung.com/live/now.txt" \
  /var/www/html/live/glass_live_manifest.mpd


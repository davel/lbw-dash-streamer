#!/usr/bin/perl

use strict;
use warnings;

use Time::HiRes qw/ sleep time /;
use DateTime;


my $ffmpeg = fork() // die $!;

if ($ffmpeg==0) {
	my $vp9="-speed 6 -tile-columns 4 -frame-parallel 1 -threads 3 -static-thresh 0 -max-intra-rate 300 -deadline realtime -lag-in-frames 0 -error-resilient 1";
	exec(qq{ffmpeg -f v4l2 -input_format mjpeg -r 30 -s 640x360 -thread_queue_size 1024 -i /dev/video0 }.
             qq{-f alsa -ar 48000 -ac 1 -thread_queue_size 1024 -i pulse }.
             qq{-map 0:0 }.
             qq{-pix_fmt yuv420p }.
             qq{-c:v libvpx-vp9 }.
             qq{-s 640x360 -keyint_min 60 -g 60 $vp9 }.
             qq{-b:v 1000k }.
             qq{-aspect 16:9 }.
             qq{-f webm_chunk }.
             qq{-header "/var/www/html/live/glass_360.hdr" }.
             qq{-chunk_start_index 1 }.
             qq{/var/www/html/live/glass_360_%d.chk }.
             qq{-map 1:0 }.
             qq{-c:a libvorbis }.
             qq{-b:a 64k -ar 48000 }.
             qq{-f webm_chunk }.
             qq{-audio_chunk_duration 2000 }.
             qq{-header /var/www/html/live/glass_171.hdr }.
             qq{-chunk_start_index 1 }.
             qq{/var/www/html/live/glass_171_%d.chk }
) or die;
}

sleep 10;

system(qq{ffmpeg -y -f webm_dash_manifest -live 1 }.
       qq{-i /var/www/html/live/glass_360.hdr }.
       qq{-f webm_dash_manifest -live 1 }.
       qq{-i /var/www/html/live/glass_171.hdr }.
       qq{-c copy }.
       qq{-map 0 -map 1 }.
       qq{-f webm_dash_manifest -live 1 }.
       qq{-adaptation_sets "id=0,streams=0 id=1,streams=1" }.
       qq{-chunk_start_index 1 }.
       qq{-chunk_duration_ms 2000 }.
       qq{-time_shift_buffer_depth 7200 }.
       qq{-minimum_update_period 7200 }.
       qq{-utc_timing_url "https://linuxbierwanderung.com/live/now.txt" }.
       qq{/var/www/html/live/glass_live_manifest.mpd }
)==0 or die;

while (1) {
	open(my $fh, ">", "/var/www/html/now.txt.new") or die $!;
	sleep 1-(time-int(time));
	print $fh DateTime->now->add( seconds => -6 )->iso8601."Z\n";
	close $fh;
	rename("/var/www/html/now.txt.new", "/var/www/html/live/now.txt") or die $!;
}

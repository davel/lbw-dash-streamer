#!/usr/bin/perl

use strict;
use warnings;

use Time::HiRes qw/ sleep time /;
use DateTime;

my $pre    = time."-";
my $prefix = "/var/www/html/live/$pre";

my $res = "640x360";

my $ffmpeg = fork() // die $!;

my $fps = 30;
my $chunk_duration = 30000;
my $keyint_min = $chunk_duration/$fps;


if ($ffmpeg==0) {
	my $vp9="-speed 6 -tile-columns 4 -frame-parallel 1 -threads 3 -static-thresh 0 -max-intra-rate 300 -deadline realtime -lag-in-frames 0 -error-resilient 1";
	exec(qq{ffmpeg -f v4l2 -input_format mjpeg -r $fps -s $res -thread_queue_size 2048 -i /dev/video0 }.
             qq{-f alsa -ar 48000 -ac 1 -thread_queue_size 2048 -i pulse }.
             qq{-map 0:0 }.
             qq{-pix_fmt yuv420p }.
             qq{-c:v libvpx-vp9 }.
             qq{-s $res -keyint_min $keyint_min -g $keyint_min $vp9 }.
             qq{-b:v 128k }.
             qq{-aspect 16:9 }.
             qq{-f webm_chunk }.
             qq{-header "${prefix}glass_360.hdr" }.
             qq{-chunk_start_index 1 }.
             qq{${prefix}glass_360_%d.chk }.
             qq{-map 1:0 }.
             qq{-c:a libvorbis }.
             qq{-b:a 64k -ar 48000 }.
             qq{-f webm_chunk }.
             qq{-audio_chunk_duration $chunk_duration }.
             qq{-header ${prefix}glass_171.hdr }.
             qq{-chunk_start_index 1 }.
             qq{${prefix}glass_171_%d.chk }
) or die;
}

$SIG{TERM} = $SIG{INT} = sub {
	kill(15, $ffmpeg);
	exit 0;
};


sleep 10;

system(qq{ffmpeg -y -f webm_dash_manifest -live 1 }.
       qq{-i ${prefix}glass_360.hdr }.
       qq{-f webm_dash_manifest -live 1 }.
       qq{-i ${prefix}glass_171.hdr }.
       qq{-c copy }.
       qq{-map 0 -map 1 }.
       qq{-f webm_dash_manifest -live 1 }.
       qq{-adaptation_sets "id=0,streams=0 id=1,streams=1" }.
       qq{-chunk_start_index 1 }.
       qq{-chunk_duration_ms $chunk_duration }.
       qq{-time_shift_buffer_depth 7200 }.
       qq{-minimum_update_period 7200 }.
       qq{-utc_timing_url "https://linuxbierwanderung.com/live/${pre}now.txt?iso" }.
       qq{${prefix}glass_live_manifest.mpd }
)==0 or die;

open(my $fh, ">", "/var/www/html/live/live.html") or die $!;
print $fh qq{<html>
<head>
<title>Linux Bier wanderung ... live</title>
<script src="https://cdn.dashjs.org/latest/dash.all.min.js"></script>
<style>
    video {
       width: 640px;
       height: 360px;
    }
</style>
</head>
<body>
   <div>
       <video data-dashjs-player autoplay src="https://linuxbierwanderung.com/live/${pre}glass_live_manifest.mpd" controls></video>
   </div>
</body>
</html>
};

close $fh;

while (1) {
	open(my $fh, ">", "/var/www/html/live/${pre}now.txt.new") or die $!;
	sleep 1-(time-int(time));
	print $fh DateTime->now->add( seconds => -60 )->iso8601."Z";
	close $fh;
	rename("/var/www/html/live/${pre}now.txt.new", "/var/www/html/live/${pre}now.txt") or die $!;
}

#!/usr/bin/perl

use strict;
use warnings;

use Time::HiRes qw/ sleep time /;
use DateTime;

while (1) {
	open(my $fh, ">", "/var/www/html/now.txt.new") or die $!;
	sleep 1-(time-int(time));
	print $fh DateTime->now->add( seconds => -6 )->iso8601."Z\n";
	close $fh;
	rename("/var/www/html/now.txt.new", "/var/www/html/live/now.txt") or die $!;
}

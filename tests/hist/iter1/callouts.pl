#!/usr/bin/env perl

use warnings;
use strict;
use utf8;

my $count = 0;
my $prev_count = 0;

while(<STDIN>) {
  while(s/>//d) {
    ++$count;
  }
  s/ //d;
  s/\[\!([^]]*)\] (.*)/::: {.$1 title="$2"}/;
  if($count < $prev_count) {
    print ":::\n";
  }
  $prev_count = $count;
  $count = 0;
  print $_;
}

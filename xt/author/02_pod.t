#!perl -w
use strict;
use warnings;
use Test::More;
eval 'use Test::Pod; 1'
  or plan skip_all => 'Test::Pod required';
plan skip_all => 'skip author tests during AUTOMATED_TESTING'
  if $ENV{AUTOMATED_TESTING};
all_pod_files_ok();

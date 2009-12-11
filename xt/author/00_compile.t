#!perl -w
use strict;
use warnings;
use Test::More;
eval 'use Test::Compile; 1'
  or plan skip_all => 'Test::Compile required';
plan skip_all => 'skip author tests during AUTOMATED_TESTING'
  if $ENV{AUTOMATED_TESTING};
all_pm_files_ok();

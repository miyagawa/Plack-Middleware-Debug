#!perl
use warnings;
use strict;
use Test::More;
eval 'use Test::Synopsis; 1' or
    plan skip_all => 'Test::Synopsis required';
plan skip_all => 'skip author tests during AUTOMATED_TESTING' if
    $ENV{AUTOMATED_TESTING};
all_synopsis_ok('lib');

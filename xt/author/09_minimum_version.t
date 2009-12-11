#!perl -w
use strict;
use warnings;
use Test::More;
eval 'use Test::MinimumVersion; 1' or
    plan skip_all => 'Test::MinimumVersion required';
plan skip_all => 'skip author tests during AUTOMATED_TESTING' if
    $ENV{AUTOMATED_TESTING};
all_minimum_version_from_metayml_ok();

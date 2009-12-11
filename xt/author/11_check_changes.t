#!perl -w
use strict;
use warnings;
use Test::More;
eval 'use Test::CheckChanges; 1' or
    plan skip_all => 'Test::CheckChanges required';
plan skip_all => 'skip author tests during AUTOMATED_TESTING' if
    $ENV{AUTOMATED_TESTING};
ok_changes(base => '../');

#!perl -T
use strict;
use warnings;
use Test::More;
eval 'use Test::Portability::Files; 1' or
    plan skip_all => 'Test::Portability::Files required';
plan skip_all => 'skip author tests during AUTOMATED_TESTING' if
    $ENV{AUTOMATED_TESTING};
run_tests();

#!perl -T
use strict;
use warnings;
use Test::More;
eval 'use Test::Portability::Files; 1'
  or plan skip_all => 'Test::Portability::Files required';
SKIP: {

    # Have to use a skip block because that module plans a test in import()
    skip 'skip author tests during AUTOMATED_TESTING', 1
      if $ENV{AUTOMATED_TESTING};
    run_tests();
}

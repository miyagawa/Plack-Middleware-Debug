#!perl
use strict;
use warnings;
use FindBin '$Bin';
use Test::More;
plan skip_all => 'skip author tests during AUTOMATED_TESTING' if
    $ENV{AUTOMATED_TESTING};
eval 'use Test::Kwalitee; 1' or
    plan skip_all => 'Test::Kwalitee required';
my $file = "$Bin/../../Debian_CPANTS.txt";
if (-e $file) {
    unlink $file or die "can't unlink $file: $!\n";
}

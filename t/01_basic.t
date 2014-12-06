use strict;
use warnings;
use Test::More tests => 1;
use_ok(
    'Test::TrapWarnings',
    qw(
        trap_warning
        trap_warnings
        no_warnings
    )
);

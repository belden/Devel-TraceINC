package mytest::thing;
use strict;
use warnings;

use mytest::stub_me_out;
use mytest::look_inside_me;

sub load_something { require mytest::loaded_via_require }
sub dynamic_load_one { eval 'use mytest::loaded_via_string_eval_use' }

1;

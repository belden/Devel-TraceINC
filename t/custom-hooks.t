#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;

use lib grep { -d } qw(../lib ./lib ./t/lib);

use Devel::TraceINC hook => sub {
	my ($self, $file) = @_;

	my $module = $self->as_module($file);

	if ($module =~ /stub_me_out/) {
		$self->stub_out($module);
	} else {
		$self->keep_looking;
	}
};

use mytest::thing;
no Devel::TraceINC;

my $graph = Devel::TraceINC->graph;
use Data::Dumper;
ok( ! exists($graph->{'Data::Dumper'}), "Didn't track Data::Dumper (unloaded tracking correctly)" );

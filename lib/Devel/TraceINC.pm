use 5.008;
use strict;
use warnings;

package Devel::TraceINC;
our $VERSION = '1.100850';
# ABSTRACT: Trace who is loading which perl modules

use Array::Sticky::INC;

BEGIN {
    unshift @INC, sub {
        my ($self, $file) = @_;
        my ($package, $filename, $line) = caller;
        warn "$file loaded from package $package, file $filename, line $line\n";
        return;    # undef to indicate that require() should look further
    };
    Array::Sticky::INC->make_sticky;
}
1;


__END__
=pod

=for test_synopsis 1;
__END__

=head1 NAME

Devel::TraceINC - Trace who is loading which perl modules

=head1 VERSION

version 1.100850

=head1 SYNOPSIS

    $ perl -MDevel::TraceINC t/01_my_test.t
    Test/More.pm loaded from package main, file t/01_my_test.t, line 6
    Test/Builder/Module.pm loaded from package Test::More, file /usr/local/svn/perl/Test/More.pm, line 22
    Test/Builder.pm loaded from package Test::Builder::Module, file /usr/local/svn/perl/Test/Builder/Module.pm, line 3
    Exporter/Heavy.pm loaded from package Exporter, file /System/Library/Perl/5.8.6/Exporter.pm, line 17
    ...

=head1 DESCRIPTION

I had a situation where a program was loading a module but I couldn't find
where in the code it was loaded. It turned out that I loaded some module,
which loaded another module, which loaded the module in question. To be
able to track down who loads what, I wrote Devel::TraceINC.

Just C<use()> the module and it will print a warning every time a module is
searched for in C<@INC>, i.e., loaded.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Devel-TraceINC>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Devel-TraceINC/>.

The development version lives at
L<http://github.com/hanekomu/Devel-TraceINC/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


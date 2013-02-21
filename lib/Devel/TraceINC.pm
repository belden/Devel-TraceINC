use 5.008;
use strict;
use warnings;

package Devel::TraceINC;
our $VERSION = '1.100900';
# ABSTRACT: Trace who is loading which perl modules

# a base package for sticky arrays; see this on CPAN
BEGIN {
    package Array::Sticky;

    sub TIEARRAY {
      my ($class, %args) = @_;

      my $self = bless +{
        head => [ @{ $args{head} || [] } ],
        body => [ @{ $args{body} || [] } ],
        tail => [ @{ $args{tail} || [] } ],
      }, $class;

      return $self;
    }

    sub POP { pop @{shift()->{body}} }
    sub PUSH { push @{shift()->{body}}, @_ }
    sub SHIFT { shift @{shift()->{body}} }
    sub UNSHIFT { unshift @{shift()->{body}}, @_ }

    sub CLEAR {
      my ($self) = @_;
      @{$self->{body}} = ();
    }
    sub EXTEND {}
    sub EXISTS {
      my ($self, $index) = @_;
      my @serial = $self->serial;
      return exists $serial[$index];
    }

    sub serial {
      my ($self) = @_;
      return map { @{$self->{$_}} } qw(head body tail);
    }

    sub STORE {
      my ($self, $index, $value) = @_;
      $self->{body}[$index] = $value;
    }

    sub SPLICE {
      my $self = shift;
      my $offset = shift || 0;
      my $length = shift; $length = $self->FETCHSIZE if ! defined $length;

      # avoid "splice() offset past end of array"
      no warnings;

      return splice @{$self->{body}}, $offset, $length, @_;
    }

    sub FETCHSIZE {
      my $self = shift;

      my $size = 0;
      my %size = $self->sizes;

      foreach (values %size) {
        $size += $_;
      }

      return $size;
    }

    sub sizes {
      my $self = shift;
      return map { $_ => scalar @{$self->{$_}} } qw(head body tail);
    }

    sub FETCH {
      my $self = shift;
      my $index = shift;

      my %size = $self->sizes;

      foreach my $slot (qw(head body tail)) {
        if ($size{$slot} > $index) {
          return $self->{$slot}[$index];
        } else {
          $index -= $size{$slot};
        }
      }

      return $self->{body}[$size{body} + 1] = undef;
    }
}

# also from CPAN
BEGIN {
    package Array::Sticky::INC;

    sub make_sticky { tie @INC, 'Array::Sticky', head => [shift @INC], body => [@INC] }
}

# At last, the code we care about
my $singleton;
sub import {
  my ($class, %args) = @_;

  my $inc_hook;

  if (! scalar keys %args) {
    $inc_hook = sub {
      my ($self, $file) = @_;
      my ($package, $filename, $line) = caller;
      warn "$file loaded from package $package, file $filename, line $line\n";
      return;    # undef to indicate that require() should look further
    };
  } else {
    $inc_hook = $class->new(hook => $args{hook});
		$singleton = $inc_hook;
  }

  unshift @INC, $inc_hook;
  Array::Sticky::INC->make_sticky;
}

sub unimport { untie @INC }
sub graph { $singleton->{graph} }

sub new {
  my ($class, %args) = @_;
  return bless +{
    hook => $args{hook},
  }, $class;
}

sub Devel::TraceINC::INC {
  my ($self, $file) = @_;

  my $module = $self->as_module($file);
  my ($package, $filename, $line) = caller;
  push @{$self->{graph}{$module}}, "$filename at line $line";

  my $hook = $self->{hook};
  return $hook->($self, $file);
}

sub as_module {
  my ($self, $file) = @_;
  (my $module = $file) =~ s{/}{::}g;
  $module =~ s{\.pm}{};
  return $module;
}

sub stub_out {
  my ($self, $module_or_file) = @_;
  my $module = $self->as_module($module_or_file);
  my @source = ("package $module;", "1;");
  return sub {
    $_ = shift @source;
    return defined $_;
  };
}

sub keep_looking { return undef }

1;

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
L<http://github.com/marcelgrunauer/Devel-TraceINC/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


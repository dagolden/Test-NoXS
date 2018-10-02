use 5.006;
use strict;
use warnings;

package Test::NoXS;
# ABSTRACT: Prevent a module from loading its XS code

our $VERSION = '1.04';

use Module::CoreList 3.00;
require DynaLoader;
require XSLoader;

my @no_xs_modules;
my $no_xs_all;
my $xs_core_only;
my $xs_core_or_dual;

our $PERL_CORE_VERSION = sprintf( "%vd", $^V );

sub import {
    my $class = shift;
    if ( grep { /:all/ } @_ ) {
        $no_xs_all = 1;
    }
    elsif ( grep { /:xs_core_only/ } @_ ) {
        $xs_core_only = 1;
    }
    elsif ( grep { /:xs_core_or_dual/ } @_ ) {
        $xs_core_or_dual = 1;
    }
    else {
        push @no_xs_modules, @_;
    }
}

sub _assert_module {
    my $module = shift;
    die "XS disabled\n" if $no_xs_all;
    die "XS disabled for $module\n" if grep { $module eq $_ } @no_xs_modules;
    _assert_in_core($module) if $xs_core_or_dual || $xs_core_only;
    _assert_exact_core_version($module) if $xs_core_only;
    return 1;
}

sub _assert_in_core {
    my $module = shift;
    # Uses explicit $PERL_CORE_VERSION instead of default for testing
    die "XS disabled for non-core modules"
      unless Module::CoreList::is_core( $module, undef, $PERL_CORE_VERSION );
    return 1;
}

sub _assert_exact_core_version {
    my $module = shift;
    # Uses explicit $PERL_CORE_VERSION instead of default for testing
    my $core_module_version = $Module::CoreList::version{$PERL_CORE_VERSION}{$module};
    my $module_version      = $module->VERSION;
    if ( $core_module_version ne $module_version ) {
        die "$module installed version: $module_version"
          . " ne $core_module_version ( shipped with perl $PERL_CORE_VERSION )";
    }
    return 1;
}

# Overload DynaLoader and XSLoader to fake lack of XS for designated modules
for my $orig (qw/DynaLoader::bootstrap XSLoader::load/) {
    local $^W;
    no strict 'refs';
    no warnings 'redefine';
    my $coderef = *{$orig}{CODE};
    *{$orig} = sub {
        my $caller = @_ ? $_[0] : caller;
        _assert_module($caller);
        goto $coderef;
    };
}

1;

=head1 SYNOPSIS

    use Test::NoXS 'Class::Load::XS';
    use Module::Implementation;

    eval "use Class::Load";
    is(
        Module::Implementation::implementation_for("Class::Load"),
        "PP",
        "Class::Load using PP"
    );

    # Disable all XS loading
    use Test::NoXS ':all';

    # Disable all XS loading except core or dual-life modules
    use Test::NoXS ':xs_core_or_dual';

    # Disable all XS loading except modules that shipped in core
    use Test::NoXS ':xs_core_only';

=head1 DESCRIPTION

This modules hijacks L<DynaLoader> and L<XSLoader> to prevent them from loading
XS code for designated modules.  This is intended to help test how modules
react to missing XS, e.g. by dying with a message or by falling back to a
pure-Perl alternative.

=head1 USAGE

Arguments on the use line control which XS modules are allowed.  One and only
one of the following options are allowed:

=for :list
* C<:all> — all XS loading is disabled
* C<:xs_core_or_dual> — XS loading is disabled except for modules that are
  core modules in the current perl, even if they have been subsequently
  upgraded from CPAN
* C<:xs_core_only> — XS loading is disabled except for modules that shipped
  with the current perl.  Modules upgraded from CPAN will have XS disabled.
  This vaguely simulates upgrading dual-life modules on a system without a
  compiler.
* a list of module names — disables XS loading for these specific modules only

=cut

# vim: ts=4 sts=4 sw=4 et:

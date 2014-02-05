use strict;
use warnings;

package Test::NoXS;
# ABSTRACT: Prevent a module from loading its XS code
# VERSION

use Module::CoreList 3.00;

my @no_xs_modules;
my $no_xs_all;
my $xs_core_only;

our $PERL_CORE_VERSION = sprintf( "%vd", $^V );

sub import {
    my $class = shift;
    if ( grep { /:all/ } @_ ) {
        $no_xs_all = 1;
    }
    elsif ( grep { /:xs_core_only/ } @_ ) {
        $xs_core_only = 1;
    }
    else {
        push @no_xs_modules, @_;
    }
}

#die unless module is in core and hasn't been upgraded.
sub _test_module_in_core {
    my $module = shift;
    # Uses explicit $PERL_CORE_VERSION instead of default for testing
    die "XS disabled for non-core modules"
      unless Module::CoreList::is_core( $module, undef, $PERL_CORE_VERSION );
    my $core_module_version = $Module::CoreList::version{$PERL_CORE_VERSION}{$module};
    my $module_version      = $module->VERSION;
    if ( $core_module_version != $module_version ) {
        die "$module installed version: $module_version"
          . " != $core_module_version ( shipped with perl $PERL_CORE_VERSION )";
    }
    return 1;
}

# Overload DynaLoader and XSLoader to fake lack of XS for designated modules
{
    no strict 'refs';
    no warnings 'redefine';
    local $^W;
    require DynaLoader;
    my $bootstrap_orig = *{"DynaLoader::bootstrap"}{CODE};

    *DynaLoader::bootstrap = sub {
        my $caller = @_ ? $_[0] : caller;
        die "XS disabled" if $no_xs_all;
        die "XS disable for $caller" if grep { $caller eq $_ } @no_xs_modules;
        if ( $xs_core_only && _test_module_in_core($caller) ) {
            goto $bootstrap_orig;
        }
        goto $bootstrap_orig;
    };
    # XSLoader entered Core in Perl 5.6
    if ( $] >= 5.006 ) {
        require XSLoader;
        my $xsload_orig = *{"XSLoader::load"}{CODE};
        *XSLoader::load = sub {
            my $caller = @_ ? $_[0] : caller;
            die "XS disabled" if $no_xs_all;
            die "XS disable for $caller" if grep { $caller eq $_ } @no_xs_modules;
            if ( $xs_core_only && _test_module_in_core($caller) ) {
                goto $bootstrap_orig;
            }
            goto $xsload_orig;
        };
    }
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

    # Disable all XS loading except core modules
    use Test::NoXS ':xs_core_only';

=head1 DESCRIPTION

This modules hijacks L<DynaLoader> and L<XSLoader> to prevent them from loading
XS code for designated modules.  This is intended to help test how modules
react to missing XS, e.g. by dying with a message or by falling back to a
pure-Perl alternative.

=head1 USAGE

Modules that should not load XS should be given as a list of arguments to C<use
Test::NoXS>.  Alternatively, giving ':all' as an argument will disable all
future attempts to load XS. Passing ':xs_core_only' works like ':all' but will
allow loading of core modules that have not been upgraded from the core version.

=cut

# vim: ts=4 sts=4 sw=4 et:

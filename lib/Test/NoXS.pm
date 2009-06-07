package Test::NoXS;

$VERSION = "1.00";

use strict;
# use warnings; # only for Perl >= 5.6

my @no_xs_modules;
my $no_xs_all;

sub import {
    my $class = shift;
    if  ( grep { /:all/ } @_ ) {
      $no_xs_all = 1;
    }
    else { 
      push @no_xs_modules, @_;
    }
}
    
# Overload DynaLoader and XSLoader to fake lack of XS for designated modules
{
    no strict 'refs';
    local $^W;
    require DynaLoader;
    my $bootstrap_orig = *{"DynaLoader::bootstrap"}{CODE};
    *DynaLoader::bootstrap = sub {
        die "XS disabled" if $no_xs_all;
        die "XS disable for $_[0]" if grep { $_[0] eq $_ } @no_xs_modules;
        goto $bootstrap_orig;
    };
    # XSLoader entered Core in Perl 5.6
    if ( $] >= 5.006 ) {
        require XSLoader;
        my $xsload_orig = *{"XSLoader::load"}{CODE};
        *XSLoader::load = sub {
            die "XS disabled" if $no_xs_all;
            die "XS disable for $_[0]" if grep { $_[0] eq $_ } @no_xs_modules;
            goto $xsload_orig;
        };
    }
}
    

1; #this line is important and will help the module return a true value

__END__

=head1 NAME

Test::NoXS - Prevent a module from loading its XS code

=head1 SYNOPSIS

 # Note: XS for Scalar::Util is actually in List::Util
 use Test::NoXS 'List::Util'; 
 
 eval "use Scalar::Util qw( weaken )";
 
 like( $@, qr/weak references/i, "Scalar::Util failed to load XS" );

=head1 DESCRIPTION

This modules hijacks L<DynaLoader> and L<XSLoader> to prevent them from loading
XS code for designated modules.  This is intended to help test how modules
react to missing XS, e.g. by dying with a message or by falling back to a
pure-Perl alternative.

=head1 USAGE

Modules that should not load XS should be given as a list of arguments to C<use
Test::NoXS>.

=head1 BUGS

Please report any bugs or feature using the CPAN Request Tracker.  
Bugs can be submitted by email to C<bug-Test-NoXS@rt.cpan.org> or 
through the web interface at 
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Test-NoXS>

When submitting a bug or request, please include a test-file or a patch to an
existing test-file that illustrates the bug or desired feature.

=head1 AUTHOR

David A. Golden (DAGOLDEN)

dagolden@cpan.org

http://dagolden.com/

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006 by David A. Golden

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

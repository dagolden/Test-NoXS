use strict;
use warnings;
use Test::More;
plan tests => 4;

require_ok('Test::NoXS');
eval "use Test::NoXS ':xs_core_only'";

is( $@, q{}, "told Test::NoXS only to allow core modules to load XS" );

#Mock List::Util that *is* in Core.
{

    package List::Util;
    our $VERSION = 1.23;
    1;
};

#Mock Cwd that *isn't* in core
{

    package Cwd;
    our $VERSION = 3.99;
    1;
};

{
    local $Test::NoXS::PERL_CORE_VERSION = 'v5.14.2';    #version 1.23 for List::Util
    ok Test::NoXS::test_module_in_core('List::Util'),
"Mock perl version $Test::NoXS::PERL_CORE_VERSION and Mock List::Util version 1.23";

    eval {
        Test::NoXS::test_module_in_core('Cwd');
        fail "should never get here";
    };
    like $@, '/3\.99/',"Died properly: $@";
};

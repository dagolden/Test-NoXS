# Test::NoXS tests
use strict;

use Test::More;

plan tests =>  6;

require_ok( 'Test::NoXS' );

# Scalar::Util actually bootstraps List::Util
eval "use Test::NoXS qw( List::Util DB_File)";

is( $@, q{},  "told Test::NoXS not to load XS for Scalar::Util or DB_File" );

my $use_SU = "use Scalar::Util qw( weaken )";

eval $use_SU;

ok( $@, "'$use_SU' threw an error" );

like( $@, '/weak/i', 
    "error matched warning for unavailable weak references (i.e XS not loaded)"
);

my $use_F = "use Fcntl qw( LOCK_EX )";

eval $use_F;

is( $@, q{}, "'$use_F' successful" );

ok( defined *main::LOCK_EX{CODE}, "function LOCK_EX imported (i.e. XS loaded)" );

#silence warning
LOCK_EX();


use strict;
use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new( 
    module_name         => 'Test::NoXS',
    dist_author         => 'David A. Golden <dagolden@cpan.org>',
    license             => 'perl',
    create_readme       => 0,
    create_makefile_pl  => 'traditional',
    requires        => {
        # module requirements here
        'Scalar::Util' => 1.01, # has weaken
        'Fcntl'        => 0,
        'Test::More'   => 0.45,   # thread-safe
    },
)->create_build_script;

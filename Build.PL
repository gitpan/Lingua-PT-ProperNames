use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Lingua::PT::ProperNames',
    license             => 'artistic',
    dist_author         => 'José João Almeida <jj@di.uminho.pt>',
    dist_version_from   => 'lib/Lingua/PT/ProperNames.pm',
    requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Lingua-PT-ProperNames-*' ],
);

$builder->create_build_script();

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Lingua::PT::ProperNames',
    AUTHOR              => 'José João Almeida <jj@di.uminho.pt>',
    VERSION_FROM        => 'lib/Lingua/PT/ProperNames.pm',
    ABSTRACT_FROM       => 'lib/Lingua/PT/ProperNames.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Lingua-PT-ProperNames-*' },
);

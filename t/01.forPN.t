# -*- cperl -*-

use Test::More tests => 5;

BEGIN {
  use_ok( 'Lingua::PT::ProperNames' );
}

use locale;
use Data::Dumper;

$a = 'à';

SKIP: {
  skip "not a good locale", 4 unless $a =~ m!^\w$!;

  my $count=0;
  my %pnlist=();
  my $countD=0;
  my %pnlistD=();

  forPN({in=>"t/01.forPN.input"},
	sub{$pnlist{n($_[0])}++; $count++});

  is( $count, "322","forPN");
  is( $pnlist{Portugal}, "5","forPN");
  is( $pnlist{"Pimenta Machado"}, "4","forPN");
  is( $pnlist{"Ribeiro da Silva"}, "1","forPN");

  sub n{
    my $a=shift;
    for($a){s/\s+/ /g; s/^ //; s/ $//;}
    $a;
  }
}
1;




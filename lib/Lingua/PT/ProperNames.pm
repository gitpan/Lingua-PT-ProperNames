package Lingua::PT::ProperNames;

#require Exporter;
use locale;
use warnings;
use strict;

=head1 NAME

Lingua::PT::ProperNames - Simple module to extract proper names from Portuguese Text

=head1 Version

Version 0.02

=cut
our $VERSION = '0.02';
our @ISA = qw(Exporter);
our @EXPORT = qw/get print printString process forString/;

our ($em, $np1, $np, $prof, $sep1, $sep2, %vazia, @stopw);

BEGIN {

  $np1 = qr{(?:(?:[A-Z�����][.])+|[sS]r[.]|[dD]r[.]|St[oa]?[.]|[A-Z�����]\w+(?:[\'\-]\w+)*)};

  #if ($e) {
  #$np= qr{$np1(?:\s+(?:d[eao]s?\s+|e\s+)?$np1)*};
  #} else {
  $np= qr{$np1(?:\s+(?:d[eao]s?\s+)?$np1)*};
  #}

  @stopw = qw{
              no com se em segundo a o os as na nos nas do das dos da tanto
              para de desde mas quando esta sem nem s� apenas mesmo at� uma uns um
              pela por pelo pelas pelos depois ao sobre como umas j� enquanto aos
              tamb�m amanh� ontem embora essa nesse olhe hoje n�o eu ele eles
              primeiro simplesmente era foi � ser� s�o seja nosso nossa nossos nossas
              chama-se chamam-se subtitui resta diz salvo disse diz vamos entra entram
              aqui come�ou l� seu vinham passou quanto sou vi onde este ent�o temos
              num aquele tivemos
             };

  $prof = join("|", qw{
                       astr�logo astr�nomo advogado actor
                       baterista
                       cantor compositor
                       dramaturgo
                       engenheiro escritor
                       fil�sofo flautista f�sico
                       investigador
                       jogador
                       matem�tico m�dico ministro m�sico
                       pianista poeta professor
                       qu�mico
                       te�logo
                      });
  $sep1 = join("|", qw{chamado "conhecido como"});

  $sep2 = join("|", qw{brilhante conhecido reputado popular});
  @vazia{@stopw} = (@stopw); # para ser mais facil ver se uma pal � stopword
  $em = '\b(?:[Ee]m|[nN][oa]s?)';
}

=head1 Synopsis

This module contains simple Perl-based functions to detect and extract
proper names from Portuguese text.

    use Lingua::PT::ProperNames;

    my $pndict = Lingua::PT::ProperNames->new;

=head1 ProperNames dictionary

=head2 new

Creates a new ProperNames dictionary

=cut

sub new {
  my $class = shift;
  # my $filename = shift;

  my $self = bless {}, $class;
  $self->_load_dictionary;
  return $self;
}

sub _load_dictionary {
  my $self = shift;
  my $file = shift || undef;

  if ($file) {
    open C, $file or die;
    while(<C>) {
      chomp;
      next if m!^\s*$!;
      $self->{cdic}{$_} = $_;
    }
    close C;
  } else {
    seek DATA, 0, 0;
    while(<DATA>) {
      chomp;
      next if m!^\s*$!;
      $self->{dic}{$_} = $_;
    }
  }
}



sub _exists {
  my $self = shift;
  my $word = shift;
  return exists($self->{dic}{$word}) or
    exists($self->{cdic}{$word}) or
      exists($self->{sdic}{$word})
}

=head2 is_name

This method checks if a name exists in the Names dictionary.

=cut

sub is_name {
  return _exists(@_)
}



=head1 Export the following functions

=head2 process

=cut


sub process{
  ## opt:  in=> inputfile(sdtin), out => file(stdout)
  my %opt = (sep => "", t => "normal" );

  %opt = (%opt , %{shift(@_)}) if ref($_[0]) eq "HASH";

  my $f=shift;
  my $m="\x01";
  my $f1;
  my $old;
  my $F1 ;

  local $/ = $opt{sep};  # input record separator=1 or more empty lines

  if (defined $opt{in}) {
    open $F1, "$opt{in}" or die "cant open $opt{in}\n";
  } else {
    $F1=*STDIN;
  }

  if (defined $opt{out}) {
    open F, ">$opt{out}" or die "cant create $opt{out}\n";
    $old = select(F);
  }

  die "invalid parameter to 'forPN'" unless ref($f) eq "CODE";

  if ($opt{t} eq "double") {
    $f1 = shift;
    die "invalid parameter ". ref($f1) unless ref($f1) eq "CODE";
  }

  while (<$F1>) {
    my $ctx = $_;
    if ($opt{t} eq "double") {

      s{($np)}{$m($1$m)}g;
      s{(^\s*|[-]\s+|[.!?]\s*)$m\(($np)$m\)}{
	my ($aux1,$aux2,$aux3)= ($1,$2, &{$f1}($2,$ctx));
	if   (defined($aux3)){$aux1 . $aux3}
	else                 {$aux1 . _tryright($aux2)} }ge;
      s{$m\(($np)$m\)}{   &{$f }($1,$ctx) }ge;

    } else {
      s{(\w+\s+|[\�\�,:()'`"]\s*)($np)}{$1 . &{$f }($2,$ctx) }ge;
    }
    print;
  }
  close $F1 if $opt{in};
  if (defined $opt{out}) {
    select $old;
    close F;
  }
}

=head2 forPNstring

=cut

sub forPNstring {
  my $f = shift;
  die "invalid parameter to 'forPNstring': function expected" unless ref($f) eq "CODE";
  my $text = shift;
  my $sep = shift || "\n";
  my $r = '';
  for (split(/$sep/,$text)) {
    my $ctx = $_;
    s/(\w+\s+|[\�\�,()'`i"]\s*)($np)/$1 . &{$f}($2,$ctx)/ge       ;
    $r .= "$_$sep";
  }
  return $r;
}

=head2 printPNstring

=cut

sub printPNstring{
  my $text = shift;
  my %opt = ();

  if   (ref($text) eq "HASH") { %opt = %$text        ; $text = shift; }
  elsif(ref($text) eq "ARRAY"){ @opt{@$text} = @$text; $text = shift; }

  my (%profissao, %names, %namesduv, %gnames);

  for ($text) {
    chop;
    s/\n/ /g;
    for (m/[.?!:;"]\s+($np1\s+$np)/gxs)  { $namesduv{$_}++ }
    for (m![)>(]\s*($np1\s+$np)!gxs)     { $namesduv{$_}++ }
    for (m/(?:[\w\�\�,]\s+)($np)/gxs)    { $names{$_}++ }
    if ($opt{em}) {
      for (/$em\s+($np)/g) { $gnames{$_}++ }
    }
    if ($opt{prof}) {
      while(/\b($prof)\s+(?:(?:$sep1)\s+)?($np)/g)
	{ $profissao{$2} = $1 }
      while(/(?:[\w\�\�,]\s+|[(])($np),\s*(?:(?:$sep2)\s+)?($prof)/g)
	{ $profissao{$1} = $2 }
    }
  }

  # tratamento dos nomes "duvidosos" = Nome prop no inicio duma frase
  #

  for (keys %namesduv) {
    if (/^(\w+)/ && $vazia{lc($1)}) { #exemplo "Como Jose Manuel"
      s/^\w+\s*//;                    # retira-se a 1.a palavra
      $names{$_}++
    } else { 
      $names{$_}++
    }
  }

  for (keys %names) {
    if (/^(\w+)/ && $vazia{lc($1)}) {  #exemplo "Como Jose Manuel"
      my $ant = $_;
      s/^\w+\s*//;                     # retira-se a 1.a palavra
      $names{$_} += $names{$ant};
      delete $names{$ant}
    }
  }

  if ($opt{oco}) {
    for (sort {$names{$b} <=> $names{$a}} keys %names ) {
      printf("%60s - %d\n", $_ ,$names{$_});
    }
  } else {
    if ($opt{comp}) {
      my @l = sort _compara keys %names;
      _compacta(\%names, @l)
    } else {
      for (sort _compara keys %names ) {
	printf("%60s - %d\n", $_ ,$names{$_});
      }
    }
    if ($opt{prof}) {
      print "\nProfiss�es\n";
      for (keys %profissao) {
	print "$_ -- $profissao{$_}"
      }
    }
    if ($opt{em}) {
      print "\nGeograficos\n";
      for (sort _compara keys %gnames ) {
	printf("%60s - %d\n", $_ ,$gnames{$_})
      }
    }
  }
}


=head2 getPN

=cut

sub getPN {
  local $/ = "";           # input record separator=1 or more empty lines

  my %opt;
  @opt{@_} = @_;
  my (%profissao, %names, %namesduv, %gnames);

  while (<>) {
    chop;
    s/\n/ /g;
    for (/[.?!:;"]\s+($np1\s+$np)/g)     { $namesduv{$_}++;}
    for (/[)>(]\s*($np1\s+$np)/g)        { $namesduv{$_}++;}
    for (/(?:[\w\�\�,]\s+)($np)/g)       { $names{$_}++;}
    if ($opt{em}) {
      for (/$em\s+($np)/g) { $gnames{$_}++;}}
    if ($opt{prof}) {
       while(/\b($prof)\s+(?:(?:$sep1)\s+)?($np)/g)
	 { $profissao{$2} = $1 }
       while(/(?:[\w\�\�,]\s+|[(])($np),\s*(?:(?:$sep2)\s+)?($prof)/g)
	 { $profissao{$1} = $2 }
     }
  }

  # tratamento dos nomes "duvidosos" = Nome prop no inicio duma frase
  #

  for (keys %namesduv) {
    if(/^(\w+)/ && $vazia{lc($1)}) {  # exemplo "Como Jose Manuel"
      s/^\w+\s*//;                    # retira-se a 1.a palavra
      $names{$_}++
    } else {
      $names{$_}++
    }
  }
  return (%names)
}


=head2 printPN

=cut

sub printPN{
  local $/ = "";           # input record separator=1 or more empty lines

  my %opt;
  @opt{@_} = @_;
  my (%profissao, %names, %namesduv, %gnames);

  while (<>) {
    chop;
    s/\n/ /g;
    for (/[.?!:;"]\s+($np1\s+$np)/g)     { $namesduv{$_}++ }
    for (/[)>(]\s*($np1\s+$np)/g)        { $namesduv{$_}++ }
    for (/(?:[\w\�\�,]\s+)($np)/g)       { $names{$_}++ }
    if ($opt{em}) {
      for (/$em\s+($np)/g) { $gnames{$_}++ }
    }
    if ($opt{prof}) {
       while(/\b($prof)\s+(?:(?:$sep1)\s+)?($np)/g)
	 { $profissao{$2} = $1 }
       while(/(?:[\w\�\�,]\s+|[(])($np),\s*(?:(?:$sep2)\s+)?($prof)/g)
	 { $profissao{$1} = $2 }
     }
  }

  # tratamento dos nomes "duvidosos" = Nome prop no inicio duma frase
  #

  for (keys %namesduv){
    if(/^(\w+)/ && $vazia{lc($1)} )   #exemplo "Como Jose Manuel"
      {s/^\w+\s*//;                  # retira-se a 1.a palavra
       $names{$_}++;}
    else
      { $names{$_}++;}
  }

  ##### N�o sei bem se isto serve...

  for (keys %names){
    if(/^(\w+)/ && $vazia{lc($1)} )   #exemplo "Como Jose Manuel"
      { my $ant = $_;
        s/^\w+\s*//;                  # retira-se a 1.a palavra
        $names{$_}+=$names{$ant};
        delete $names{$ant};}
  }

  if($opt{oco}){
    for (sort {$names{$b} <=> $names{$a}} keys %names )
      {printf("%6d - %s\n",$names{$_}, $_ );}
  }
  else
    {
      if($opt{comp}){my @l = sort _compara keys %names;
		     _compacta(\%names, @l); }
      else{for (sort _compara keys %names )
	     {printf("%60s - %d\n", $_ ,$names{$_});} }

      if($opt{prof}){print "\nProfiss�es\n";
		     for (keys %profissao){print "$_ -- $profissao{$_}";} }

      if($opt{em}){print "\nGeograficos\n";
		   for (sort _compara keys %gnames )
		     {printf("%60s - %d\n", $_ ,$gnames{$_});} }
  }
}



##
# Auxiliary stuff

sub _tryright{
  my $a = shift;
  return $a unless $a =~ /(\w+)/;
  my $m = "\x01";
  my ($w,$r) = ($1,$');
  $r =~ s{($np)}{$m($1$m)}g;
  return "$w$r";
}


sub _compacta{
  my $s;
  my $names = shift;

  my $p = shift;
  my $r = $p;
  my $q = $names->{$p};
  while ($s = shift)
    { if ($s =~ (/^(.+) $p/)) { $r = "($1) $r" ;
				$q += $names->{$s};
			      }
      else {print "$r - $q"; $r=$s; $q = $names->{$s}; }
      $p=$s;
    }
  print "$r - $q";
}

sub _compara {
  # ordena pela lista de palavras invertida
  join(" ", reverse(split(" ",$a))) cmp join(" ", reverse(split(" ",$b)));
}


=head1 Author

Jos� Jo�o Almeida, C<< <jj@di.uminho.pt> >>

Alberto Sim�es, C<< <ambs@di.uminho.pt> >>

=head1 Bugs

NOTE: We know documentation for exported methods is inexistent. We are
      working on that for very soon.

Please report any bugs or feature requests to
C<bug-lingua-pt-propernames@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 Copyright & License

Copyright 2004 Alberto Sim�es, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Lingua::PT::ProperNames

__DATA__
Abecassis
Abel
Ab�rcio
Ab�lio
Abiss�nia
Aboim
Abra�o
Abraham
Abrams
Abrantes
Abreu
Abril
Abu
Ac�cio
A�ores
Acre
Adalberto
Adamastor
Adams
Ad�o
Adelaide
Adelina
Adelino
Adelson
Adolfo
Ad�nis
Adriano
Adri�tico
Afeganist�o
Afonso
�frica
Afrodite
�gata
Agostinho
Agostinhos
Agosto
Agra
Agra�o
�guas
�gueda
Aguiar
Aires
Aix-en-Provence
Aix-la-Chapelle
�jax
Alandroal
Al�
Alarico
Alasca
Alb�nia
Albano
Alba
Albergaria-a-Nova
Albergaria-a-Velha
Albertina
Albertino
Albert
Alberto
Albino
Albufeira
Albuquerque
Alc�cer
Alcanena
Alc�ntara
Alcino
Alcinos
Alcoba�a
Alcochete
Alcoforado
Alcor�o
Alcoutim
Aldora
�lea
Aleixo
Alemanha
Alencar
Alenquer
Alentejo
Alexandra
Alexandre
Alexandria
Alfredo
Algarves
Algarve
Alg�s
Algodres
Alhambra
Alhandra
Alicante
Alice
Alij�
Al�pio
Aljezur
Aljubarrota
Aljustrel
Allen
Almada
Alman�or
Almeida
Almeirim
Almod�var
Almort�o
Alpes
Alpiar�a
Alportel
Als�cia
Alvai�zere
Alvalade
�lvares
�lvaro
Alverca
Alves
Alvim
Alvito
Alzira
Amadeu
Amadeus
Amadora
Amado
Am�lia
Am�ncio
Am�ndio
Amap�
Amaral
Amarante
Amares
Amaro
Am�
Amato
Amazonas
Amaz�nia
Ambr�sio
Am�lia
Am�ricas
Am�rica
Am�rico
Amesterd�o
Am�lcar
Amorim
Anabela
Anadia
Ana
Anast�cio
Anat�lia
Anaximandro
Anax�menes
Ancara
Andaluzia
Andersen
Andrade
Andr�
Andrews
Andr�meda
Andy
Angeiras
�ngela
Angeles
Ang�lica
�ngelo
�ngelo
Angkor
Angola
Angra
An�bal
Aniceto
Anita
Anselmo
Ansi�es
Ansi�o
Ant�o
Ant�rctida
Antas
Antero
Antilhas
Antioquia
Antoine
Ant�nia
Ant�nio
Antu�rpia
Antunes
Apalaches
Apar�cio
Apocalipse
Apolin�rio
Apol�nia
Apol�nio
Apolo
Ap�lia
Aquiles
Aquilino
Aquino
Aquisgrana
Aquit�nia
Ara�o
Ar�bia
Arafat
Arag�o
Aranjuez
Ara�jo
Arc�dia
Ardenas
Ardila
Arganil
Arg�lia
Argel
Argentina
�rgon
Arg�via
Aristides
Arist�fanes
Arist�teles
Arizona
Arkansas
Arles
Arlindo
Armamar
Armando
Arm�nia
Arm�nio
Armindo
Arnaldo
Arnold
Arnoldo
Arno
Arouca
Arquimedes
Arrabal
Arr�bida
Arraiolos
Arronches
Arruda
Artur
Ascen��o
�sia
Asp�sia
Ass�ria
Assis
Assis
Assun��o
Ast�rix
Ast�rias
�talo
Atenas
�tila
Atlanta
Atl�ntico
Auckland
Augusta
Augustini
Augusto
Aur�lia
Aur�lio
Auschwitz
Austr�lia
�ustria
Aveiro
Avelar
Aveleda
Avelino
Avicena
�vila
Avilez
Avinh�o
Avintes
Avis
Azambuja
Azeit�o
Azem�is
Azerbaij�o
Azevedo
Babil�nia
Bacelar
Bach
Bacon
Baco
Badajoz
Bagdade
Bagdad
Ba�a
Bai�o
Ba�a
Baiona
Bairrada
Baker
Balc�s
Balsem�o
Baltasar
Baltazar
B�ltico
Baltimore
Balzac
Baptista
Baptiste
Barahona
B�rbara
Barbosa
Barcelona
Barcelos
Barnab�
Barquinha
Barrab�s
Barrancos
Barreiros
Barreiro
Barreto
Barroso
Bartok
Bartolomeu
Basileia
Basilicata
Basilienses
Bas�lio
Bassor�
Basto
Bastos
Baudelaire
Baviera
Beatles
Beatriz
Beaumont
Becket
Beethoven
Beirute
Beja
Belarmino
Belchior
Bel�m
Belfast
B�lgica
Belgrado
Belize
Belmiro
Belmonte
Beltrano
Beltr�o
Belzebu
Benavente
Benedito
Benelux
Benfica
Bengala
Benguela
Benilde
Benjamin
Bento
Bereng�rio
Bergen
Berger
Bergman
Bergson
Berkeley
Berlenga
Berlim
Berlioz
Bernardes
Bernardino
Bernard
Bernardo
Berna
Bernoulli
Bernstein
Berta
Berto
Bertrand
Bessa
Bet�nia
Bettencourt
B�tica
B�blia
Bielor�ssia
Bi�
Bilbau
Bill
Birm�nia
Biscaia
Bismarck
Bismark
Bissau
Bizet
Boaventura
Boavista
Bocage
Bogot�
Bohr
Bolena
Bol�via
Bolonha
Boltzmann
Bombaim
Bombarda
Bombarral
Bonaparte
Bona
Bonfim
Bonif�cio
Bonjardim
Boole
Borba
Bordalo
Borges
Borgonha
Borguinh�es
Boris
Born�u
B�snia
Boston
Botelho
Botswana
Boulevard
Bouro
Boximanes
Boyle
Brabante
Bracara
Bradenburgo
Bragan�a
Braga
Brahms
Brama
Branca
Brand�o
Brandeburgo
Brandt
Bras�lia
Brasil
Br�s
Bratislava
Braun
Bremen
Bretanha
Breyner
Brighton
Briolanja
Bristol
Brit�nia
Briteiros
British
Brito
Brno
Broadway
Brooklyn
Brown
Bruce
Bruges
Bruno
Brutus
Bruxelas
Bu�aco
Bucareste
Buda
Budapeste
Buenos
Bulg�ria
Burgenland
Burgos
Bush
Byron
Cabanelas
Cabral
Cabul
Cac�m
Cacilhas
Cadaval
C�dis
Caeiro
Caetano
Caim
Caio
Cairo
Cal�bria
Calced�nia
Calcut�
Caldelas
Calheta
Calheiro
Calheiros
Calif�rnia
Cal�gula
Calisto
Calvino
Cambodja
Cambra
Cambridge
Camelo
Camilo
Cam�es
Campanh�
Camp�nia
Cana�
Canad�
Can�rias
Canaveses
C�ndida
C�ndido
Cannes
Cansas
Cant�bria
Cantanhede
Cant�o
Cantu�ria
Capad�cia
Caparica
Capric�rnio
Carachi
Cara�bas
Carcavelos
Cardan
Cardoso
Car�lia
Car�ntia
Carla
Carl
Carlos
Carlota
Carmelo
C�rmen
Carminda
Carmona
Carmo
Carnaval
Carnegie
Carolina
Carol
C�rpatos
Carrazeda
Carregal
Carrol
Cartago
Cartaxo
Cartuxa
Carvalhos
Carvalhas
Casablanca
Casanova
Cascais
Casimiro
C�spio
Cassiano
Cassinga
Cassiopeia
Castela
Castilho
Castro
Catalunha
Cat�nia
Catarina
Catherine
Catulo
C�ucaso
Cavacoti
C�vado
Caxias
Cazaquist�o
Cear�
Cec�lia
Cedofeita
Ceil�o
Celeste
C�lia
Celorico
Celso
Cen�culo
Cerqueira
Cervantes
Cerveira
Cesareia
Ces�rio
C�sar
C�u
Ceuta
C�zanne
Chang
Chaplin
Charles
Charlot
Charlotte
Chaves
Checoslov�quia
Chen
Cher
Chevalier
Chicago
Chile
China
Chipre
Chomsky
Chopin
Christian
Christopher
C�cero
Cid�lia
Cid
Cinderela
Cinf�es
Cipi�o
Cipriano
Cirilo
Cisjord�nia
Cit�nia
City
Claire
Clark
Claudel
Claude
Cl�udia
Cl�udio
Clemente
Clementina
Cle�patra
Clinton
Clotilde
Cluj
Cohen
Coimbra
Colegiada
College
Collins
Col�mbia
Colombo
Colonato
Colorado
Columbano
Col�mbia
Comba
Compostela
Concei��o
Condeixa-a-Nova
Condeixa
Condest�vel
Conf�cio
Congo
Connor
Conrado
Constan�a
Const�ncio
Constantino
Constantinopla
Copenhaga
Cop�rnico
Copperfield
Cor�o
Cordeiro
C�rdoba
C�rdova
Coreia
Corn�lia
Correia
C�rsega
Cortes�o
Coruche
Corunha
Corvina
Corvino
Cosme
Costa
Couceiro
Coutinho
Covilh�
Crac�via
Crato
Crespo
Creta
Crimeia
Criologia
Cript�fita
Cristi�nia
Cristiano
Cristo
Crist�v�o
Cro�cia
Cromwell
Cruzeirinho
Cruz
Cuba
Cunene
Cunhal
Cunha
Curdist�o
Curi�cios
C�ria
Cust�dio
Cust�ias
Czardas
D�cia
D�cios
Dacota
Dahl
Daire
Dalila
Dalm�cia
Dalton
Damasco
Dam�sio
Damas
D�maso
Dame
Dami�o
Daniel
Dan
Dante
Dan�bio
Dario
Darwinti
David
Davidson
Davis
D�bora
Debrecen
Debussy
Dec�logo
D�dalo
Delfim
Delfos
Dem�trio
Dem�crito
Dem�nio
Descartes
Desid�rio
Detroit
Deus
Dezembro
Diabo
Diamantina
Diamantino
Diana
Di�spora
Didier
Diego
Dili
Dinamarca
Dinis
Diocleciano
Diodoro
Diogo
Dion�sio
Dirac
Dirceu
Direc��o-Geral
Diu
Dolores
Domingos
Domingues
Donato
Donetsk
Don
Doris
Doroteia
Dortmund
Dostoievski
Douglas
Douro
Drake
Dresden
Duarte
Dublin
Duke
Dulce
Dumont
Dunquerque
Dur�o
D�sseldorf
Dylan
Eanes
Eastwood
Ebro
E�a
Edgar
Edimburgo
�dipo
Edite
Edmond
Edmund
Edmundo
Eduarda
Eduardo
Edward
Ef�sio
�feso
Egas
Egeu
Eg�dio
Egipto
Einstein
Eisenberg
Eisenhower
Ekaterinburgo
El�dio
Elba
Electra
Elia
Elias
Elisa
El�sio
El�sios
El�i
Elsa
Elvas
Elvira
Emanuel
Em�dio
Emile
Emiliano
Em�lia
Em�lio
Eneias
Engels
Eng
Engr�cia
Entre-os-Rios
Epicuro
Erasmo
Erat�stenes
Ericeira
Erich
Ermelinda
Ermesinde
Erm�nio
Ernesto
Ernst
Escandin�via
Escobar
Esc�cia
Escorial
Escritura
Esfinge
Esgalhado
Eslov�quia
Eslov�nia
Esmeralda
Esmirna
Espanha
Esparta
Espinozati
Esp�rito
Esposende
�squilo
Ess�nios
Estalinegrado
Estaline
Estarreja
Estef�nia
Estela
Est�v�o
Esteves
Estio
Est�ria
Estocolmo
Est�nia
Estoril
Estrasburgo
Estrela
Estremadura
Estremoz
Estugarda
Etelvina
Eti�pia
Eucaristia
Euclides
Euf�mia
Eufrates
Eug�nia
Eug�nio
Eul�lia
Euler
Eunice
Eurico
Eur�pides
Euro�sia
Europa
Eus�bio
Evangelho
Eva
Evans
Evaristo
Evereste
�vora
Ezequiel
F�bio
Fafe
Fahrenheit
Fagundes
Faial
Falc�o
Falkland
Famagusta
Famalic�o
Fanny
Faria
Faro
F�tima
Faustino
Fausto
Feij�
Feio
Feldspato
Felgueiras
Feliciano
Fel�deos
Felisberto
Felismina
F�lix
Fellini
Ferguson
Fermat
Fernanda
Fernandes
Fernandez
Fernando
Fern�o
Ferrari
Ferraz
Ferreira
Fevereiro
Feynman
Fialho
Fibonacci
Figueiredo
Figueir�
Filad�lfia
Filgueiras
Filinto
Filipa
Filipe
Filipes
Filipinas
Filipos
Filomena
Finl�ndia
Fiorentina
Firmino
Fischer
Fitzgerald
Flandres
Flaviano
Fl�vio
Fletcher
Floren�a
Flor�ncio
Fl�rido
Florinda
Fonseca
Fontainhas
Ford
Fortunato
Foz
Fraga
Fran�a
Francelina
Franc�s
Francforte
Francisca
Francisco
Francis
Fran�oise
Fran�ois
Francos
Frankenstein
Frankfurt
Franklin
Frank
Franz
Frederico
Fred
Freire
Freitas
Freixo
Freud
Friburgo
Fr�sia
Fritz
Friuli
Fulton
Funchal
Furna
Gab�o
Gabriela
Gabriel
Gaia
Gaio
Gal�cia
G�lias
G�lia
Galileia
Galileu
Galiza
Gal
G�l
Galv�o
G�mbia
Ganges
Garcia
Garrett
Gaspar
Gasset
Gast�o
Gates
Gauguin
Gaulle
Gaza
Gede�o
Geiger
Genebra
G�nesis
G�nova
George
Ge�rgia
Georgina
Geraldes
Geraldo
Gerardo
Ger�s
Germ�nia
Gertrudes
Gerv�sio
Gestapo
Get�lio
Gibraltar
Gilberto
Gilda
Gil
Giovanni
Gir�o
Gisela
Glasgow
Glen
Gl�ria
Goa
Godard
Godinho
Goethe
Gogh
Goi�s
G�is
Goleg�
Gomes
Gomez
Gon�alo
Gon�alves
Gondomar
G�ngora
Gonzaga
Gonz�lez
Gordon
G�rgias
Gorki
Gotland
Gouveia
Gouveias
Gouveia
Goya
Gr�-Bretanha
Gra�a
Graciano
Gracinda
Graciosa
Gr�ndola
Gr�o-Par�
Graz
Gr�cia
Greenwich
Gregoriano
Greg�rio
Grenoble
Grieg
Gronel�ndia
Grozny
Guadalajara
Guadalquivir
Guadalupe
Guadiana
Gualtar
Guanabara
Guarda
Guatemala
Guedes
Guelfos
Guevara
Guianas
Guiana
Guida
Guilherme
Guilhermina
Guimar�es
Guin�-Bissau
Guin�
Guiomar
Gulbenkian
Guliver
Gusm�o
Gusm�o
Gustavo
Gutemberg
Gutenberg
Guterres
Habsburgos
Haia
Haiti
Hall
Halle
Hamburgo
Hamilton
Hamlet
Hammerfest
Hampshire
Handel
Han�ver
Hansa
Hanse�tica
Harold
Harvard
Havana
Hebron
H�cuba
Hegel
Heidegger
Heisenberg
Heitor
H�lder
Helena
Helen
Helga
Heliodoro
Helmut
Hels�nquia
Henri
Henrique
Henriques
Henriqueta
Her�clito
Herbert
Herculano
H�rcules
Herman
Hermano
Hermenegildo
Hermes
Herm�nio
Hern�ni
Herodes
Her�doto
Herzegovina
Hessen
Hess
Hil�rio
Hilbert
Hildebrando
Hill
Himalaias
Himalaia
Hip�crates
Hip�lito
Hiroshima
Hisp�nia
Hispano
Hitchcock
Hitleri
Hoare
Hobbes
Holanda
Hollywood
Holy
Hom�rico
Homero
Honduras
Hong-Kong
Hong
Honorato
Hon�rio
Hopkins
Hor�cia
Hor�cio
Hor�cios
Horn
Hort�nsia
Hort�nsio
Houdini
Howard
Huambo
Hubble
Hudson
Hugo
Humberto
Humphrey
Hungria
Hussein
�caro
Idanha-a-Nova
Idanha-a-Velha
I�mene
Igreja
Ilda
Ildefonso
�lhavo
Il�ada
Il�dio
Illinois
In�cio
�ndias
�ndico
Indochina
Indon�sia
In�s
Inglaterra
Ingmar
Innsbruck
Inoc�ncio
Inverno
Iorque
Iowa
Ipanema
Ir�o
Iraque
Irene
Irlanda
Irving
Isaac
Isabel
Isa�as
Isaura
Isidoro
Isidro
Isl�ndia
Isl�o
Ismaelitas
Ismael
Isolda
Israel
Istambul
�stmicos
It�lia
Itamar
Ivan
Ivone
Ivo
Jacar�
Jacarta
Jacinta
Jacinto
Jack
Jackson
Jacobi
Jacobitas
Jacob
Jacques
Jaime
Jamaica
James
Janeiro
Jane
Janet
Jansenistas
Janus
Jamu�rio
Jap�o
Jaques
Jargal
Jarreteira
Jasmim
Jaspers
Java
Jean
Jefferson
Jenny
Jeov�
Jeremias
Jeric�
Jer�nimo
Jer�nimos
Jersey
Jerusal�m
Jesus
Joana
Joanesburgo
Joanina
Joan
Jo�o
Joaquim
Joaquina
John
Jonas
Jord�nia
Jordan
Jord�o
Jorge
Josefa
Josefina
Josef
Jos�
Joseph
Josu�
Joyce
Juan
Judas
Jud�
Judeia
Judite
Judith
Jugosl�viax
Jules
Julho
Juliana
Julian
Juliano
J�lia
Juli�o
Julie
Julieta
J�lio
Julius
Jung
Junho
Juno
Junqueira
Junqueiro
J�piter
Jur�ssico
Justiniano
Justino
Kafka
Kahn
Kali
Kant
Karl
Kazan
Kazan
Keaton
Keil
Keller
Kelvin
Kennedy
Kensington
Kentucky
Kepler
Keynes
Khan
Kiev
King
Kinshasa
Kleene
Klein
Kong
Korsakov
Kosovo
Kremlin
Kuwait
Lacerda
Lacroix
Ladislau
Lagrange
Lajes
Lamarcki
Lambert
Lamego
Lanhoso
Laos
Laplace
Lap�nia
Las
Latr�o
Laura
Laurentino
Laurinda
Lausana
Lautrec
Lavoisier
Lawrence
L�zaro
L�zio
Leal
Leandro
Le�a
Leibnitz
Leibniz
Leida
Leipzig
Leiria
Leix�es
Lencastre
Leninegrado
Lenineit
Leonard
Leonardo
Leonel
Le�nidas
Leonor
Leopoldina
Leopoldo
L�rida
Let�nia
Lev�tico
Lewis
L�bano
Lib�ria
L�bia
Lic�nio
L�dia
Li�ge
Lili
Lima
Limpopo
Lincoln
Lino
Lisboa
Litu�nia
Liverpool
Ljubljana
Lobato
Lobo
Loiola
Lombardia
Lombardi
Londres
Lopes
Lopez
Lopo
Lordelo
Lord
Lorena
Los
Louis
Loul�
Louren�o
Lourinh�
Lourosa
Lousada
Lous�
Louvre
Luanda
Lubango
Lucas
Lucena
Luciano
L�cia
L�cifer
Luc�lia
Luc�lio
Lucinda
L�cio
Luc
Lucr�cia
Lucr�cio
Ludovico
Ludwig
Lugo
Luigi
Lu�sa
Luisiana
Lu�s
Lumen
Lumiar
Lumi�re
Lurdes
Lus�adas
Lusit�nia
Lutero
Luther
Luxemburgo
Luzia
Luz
Lvov
Maastricht
Mac�rio
Macau
Maced�nia
Macedo
Machado
Machico
Macintosh
Macintosh
Madag�scar
Madalena
Madeleine
Madonna
Madre
Madrid
Madureira
Mafalda
Mafra
Magalh�es
Magda
Magdeburgo
Magrebe
Maias
Maia
Maio
Maiorca
Malaca
M�laga
Malaia
Malanje
Mal�sia
Malawi
Malheiro
Mali
Malta
Malva
Mamede
Manchester
Manch�ria
Mandela
Mangualde
Manica
Manila
Manteigas
M�ntua
Manuela
Manuel
Maom�
Mao
Maputo
Maquiavel
Maranh�o
Mar�o
Marcelino
Marcel
Marceloti
M�rcio
Mar�o
Marconi
Marcos
Marcus
Marg�o
Margarida
Mariana
Maria
Marias
Marie
Mar�lia
Marilyn
Marim
M�rio
Mariz
Mark
Marques
Marrocos
Marselha
Marselhesa
Marshall
Marte
Martim
Martinez
Mart�nez
Martinho
Martinica
Martin
Martins
Marv�o
Marxi
Mary
Mascarenhas
Massachusetts
Massarelos
Mateus
Matias
Matilde
Matosinhos
Matos
Matusal�m
Maur�cio
Mauro
Mavilde
Maximiano
Maximiliano
Max
Mazag�o
Mealhada
Meca
M�da
Medeiros
Medina
Mediterr�neo
Meije
Meireles
Melan�sios
Melchior
Melga�o
Melinde
Melo
Memphis
Mendes
Mendez
Mendon�a
Mendo
Menelau
Meneses
Menezes
Mercedes
M�rida
Meriterr�neo
M�rtola
Mesopot�mia
Mesquita
Messalina
Messias
Messina
Metelo
Metz
M�xico
M�xico
Miami
Michaelis
Michael
Michigan
Midas
Miguel
Mil�o
Mileto
Mileto
Mille
Miller
Milner
Milton
Mimi
Mindelo
Minerva
Ming
Minho
Minneli
Minnesota
Minotauro
Minsk
Miragaia
Miranda
Mirandela
Mira
Miskolc
Mistral
Mitilene
Mitra
Mo�ambique
Mo��medes
Mogadouro
Moh�mede
Moimenta
Mois�s
Mold�via
Moli�re
M�naco
Monchique
Moncorvo
Mondego
Mondim
Monforte
Monfortinho
Mong�is
Mong�lia
M�nica
Moniz
Monroe
Monsanto
Monsaraz
Montalegre
Montalv�o
Montebelo
Montecorvo
Monteiro
Montejunto
Montemor
Montemor-o-Novo
Montemor-o-Velho
Montenegro
Montenegro
Monterverdi
Montesquieu
Monteverdi
Montevideu
Montgomery
Montpellier
Montreal
Monza
Moore
Morais
Mor�via
Moreira
Morgado
Morgan
Morin
Morse
Mort�gua
Moscovo
M�s
Mota
Moura
Mour�o
Moutinho
Mozart
Muller
Munique
Mur�a
M�rcia
Murdock
Murphy
Murtosa
Mussolini
Nadine
Nagasaki
Nagas�qui
Nanci
Nancy
Nanquim
Nantes
Napole�o
N�poles
Narva
Nashville
Nat�lia
Navarra
Nazar�
Nazar�
Necas
Neil
Neiva
Nellie
Nelson
Nem�sio
Nemo
Nepal
Neptuno
N�ri
Nero
Nestor
Neva
Nevogilde
Newcastle
Newman
Nicar�gua
Nice
Nick
Nicolas
Nicolau
Nic�sia
Nietzsche
Nig�ria
Nilo
Nilsson
Nisa
Nobel
No�
Nogueira
Normandia
Normandos
Noronha
Norton
Noruega
Notre
N�tre
Nottingham
Novais
Novembro
Novgorod
Novossibirsk
Nunes
Nuno
Nuremberga
Oakland
Ob�lix
�bidos
Oceania
Oce�nia
Octaviano
Oct�vio
Odemira
Odense
�der
Oder
Odete
Odisseia
Odivelas
Odorico
Oeiras
Of�lia
Ohio
Oklahoma
Olga
Olh�o
Oligoc�nico
Ol�mpia
Olimpo
Olinda
Oliva
Olivares
Oliveira
Oliven�a
Oliv�rio
Oliver
Omar
Om�
Onofre
Ont�rio
Orestes
Orfeu
Orlando
Orle�es
Ormuz
Orofernes
Orontes
Ortega
Ortig�o
Osaca
Osaka
Osborn
�scar
Oslo
Os�rio
Ostende
Ostrogodos
Osvaldo
Ot�vio
Otelo
Othello
Ot�lia
Our�m
Ourense
Ourique
Outono
Outubro
Ovar
Ov�dio
Ov�dio
Oviedo
Owen
Oxford
Pacheco
Pac�fico
Pa�os
Padre-Nosso
P�dua
Pai-Nosso
Paio
Paiva
Paleol�tico
Palermo
Palestina
Palmeira
Palmela
Palmer
Palmira
Palo
Pampilhosa
Panam�
Pandora
Pantagruel
Papas
Paquist�o
Paraguai
Para�ba
Para�so
Param�cidas
Paramec�deos
Paran�
Paran�
Paranhos
Par�
Parente
P�rias
Paris
Parkinson
Park
Parma
Parnasianismo
P�rtenon
Pascal
P�scoa
Pascoal
Pascoal
Pascoela
Pas-de-Calais
Pasolini
Passau
Passos
Pasteur
Patag�nia
Pato
Patr�cio
Patrick
Paula
Pauli
Paulino
Paulina
Paulista
Paul
Pauloh
Pavlov
Peano
Pedrog�o
Pedro
Pedrosa
Pedroso
P�gaso
Peixoto
Peles-Vermelhas
Pelourinho
Penacova
Penafiel
Penagui�o
Penalva
Penamac�r
Penedono
Penela
Peng
Peniche
Pensilv�nia
Pentecostes
Pepino
Pequim
Pera
Pereira
Peres
Perez
P�rez
Pernambuco
P�ro
Perp�tua
Perseu
P�rsia
Pestana
Petersburgo
Petrarcai
Petrozavodsk
Philippe
Phil
Phoenix
Piau�
Pi�arra
Picasso
Piemonte
Piemonte
Pierre
Pilar
Pilatos
Pimenta
Pimentel
Pinacoteca
Pina
P�ndaro
Ping
Pinheiro
Pinhel
Pinto
Pio
Piren�us
Pires
Pireu
Pirro
Pit�goras
Pl�cido
Planck
Plat�o
Plauto
Pl�nio
Plistoc�nico
Pneum�tica
Poiares
Poincar�
Policarpo
Polin�sia
Pol�nia
Polo
Pombeiro
Pomer�nia
Pompeu
Pontevedra
Pont�fice
Popper
Portalegre
Portela
Portel
Portim�o
Porto
Portugal
Potter
P�voa
Prado
Praga
Preciosa
Primavera
Prince
Proen�a-a-Nova
Proen�a
Prokofiev
Prometeu
Prot�goras
Proust
Proven�a
Prud�ncio
Pr�ssia
Psico
Pskov
Ptolomeu
P�blia
P�blio
Puglia
Pulitzer
Quanza
Quatern�rio
Quebeque
Queir�s
Queiroz
Quel�nios
Queluz
Qu�nia
Quental
Quentin
Quibir
Quit�ria
Quixoteit
Rabag�o
Rachel
Racine
Radag�sio
Rafael
Raimundo
Ramad�o
Ramalde
Ramalho
Ramires
Ramirez
Ramiro
Ramon
Ram�n
Rams�s
Rangel
Raposo
Raquel
Ratisbona
Raul
Ravel
Real
Rebeca
Rebelo
Rebordelo
Regina
R�gio
Rego
Reguengos
Reinaldo
Rembrandt
Remo
Ren�nia
Renato
Renoir
Reno
Resende
Ressurrei��o
Reynolds
Ribatejo
Ribeiro
Ricardo
Richard
Richardson
Riemann
Riga
Rimini
Rimski
Rioja
Rita
Rivera
Riviera
Robert
Roberto
Robespierre
Robin
Robinson
Rockefeller
Rockford
R�dano
R�d�o
Rod�sia
Rodolfo
Rodrigo
Rodrigues
Rodriguez
Rodr�guez
Rog�rio
Rold�o
Rom�o
Roma
Rom�nia
Romero
Romeu
Rommel
R�mulo
Rond�nia
Roosevelt
Roraima
Ros�lia
Rosalina
Rosa
Ros�rio
Rosenberg
Rose
Rosita
Rossilh�o
Rossini
Rostock
Roterd�o
Rousseau
Royal
Roy
Ruanda
Rubens
Rudolfo
Rufino
Rui
Russell
Russel
R�ssia
Rute
Rutherford
Ruth
Saar�
Sab�
Sabrosa
Sado
Sadova
Saint
Salamanca
Salazarit
Saldanha
Salemas
Sally
Salmo
Salom�o
Salom�
Salsete
Salvador
Salvaterra
Salvatore
Salzburgo
Samaria
Sameiro
Sam
Samora
Sampaiot
Samuel
Samuelson
San
Sanches
Sanchez
Sancho
Sandinoti
Sandra
S�
Sans�o
Santana
Santander
Santar�m
Santiago
S�o
Sarago�a
Sarah
Saraiva
Sarajevo
Saramago
Sara
Sardenha
Sardoal
Sarg�o
Sarre
Sartre
Sat�
Satan�s
Satan
S�t�o
Satis
Satureja
Saturno
Saudita
Sav�ia
Sax�nia-Anhalt
Sax�nia
Scala
Scarlatti
Schelling
Schengen
Schiller
Schlwesig-Holstein
Schopenhauer
Schubert
Schumann
Schwarz
Scott
Seabra
Seattle
Sebasti�o
Segismundo
Seg�via
Seguin
Seia
Selznick
Semedo
Sena
S�neca
Senegal
Sequeira
Serafim
Serafins
S�rbia
S�rgio
Sergipe
Sernancelhe
Serpa
Serpula
Sesimbra
S�
Setembro
Set�bal
Seul
Severino
Sever
Sevilha
Shakespeare
Shangai
Shapiro
Shaw
Si�o
Sib�ria
Sic�liap
Sicrano
SIDA
Sidney
Sid�nio
S�don
Siegfried
Sil�sia
Silva
Silveira
Silv�rio
Silves
Silvestre
S�lvia
S�lvio
Sim�o
Sime�o
Sim�es
Simone
Simon
Simpson
Sinai
Sin�drio
Sines
Singapura
Sinopsis
Sinqui�o
Sintra
Siracusa
Siracusanas
Sir
S�ria
Smith
Soares
Sobral
Society
S�crates
Soeiro
Sofia
S�focles
Soleim�o
Solim�o
Solim�es
Solino
Som�lia
S�nia
Sorbona
Sortelha
S�r
Sotomaior
Soure
Sousa
Sousel
Soutelo
Souto
Spencer
Spenser
Sporting
Stanley
Stefano
Stephens
Stern
Stevens
Stewart
Stratford
Strauss
Stravinsky
Stuart
Su�rez
Sud�o
Sudetas
Su�cia
Sueste
Suez
Su��a
Sullivan
Suriname
Susana
Susan
Sut�o
Sutra
Szabo
Taboritas
Tabua�o
Tabula
Tadeu
Tail�ndia
Taira
Taishi
Taiwan
Tales
Tallinn
Tam�o
T�mega
Tamisa
Tancos
Tancredo
T�nger
Tanner
Tao
Tarouca
Tarqu�nio
T�rrega
Tarso
Tasm�nia
Tauride
Tauris
Tauro
Tauros
Taurus
Tavares
Taveira
Tavira
T�vora
Taylorit
Tchaikovsky
T�uzzu
Tebaldo
Tebas
Teer�o
Teixeira
Tejo
Telavive
Telesio
Teles
Telmo
Tenessi
Tenreiro
Teodora
Teodoreto
Teodorico
Teodoro
Teod�sio
Te�filo
Teofrasto
Teot�nio
Ter�ncio
Teresa
Tertuliano
Tesauro
Teseu
Tete
Texas
Thomas
Thompson
Thomson
Thor
Thorp
Tiago
Tib�es
Tib�rio
Tibete
Tibre
Ticiano
Tim
Timor-Leste
Timor
Tim�teo
Timothy
Tirol
Tirso
Tit�nia
Titanic
Tito
Toarciano
Tobias
Tocantins
Toledo
Tolstoi
Tom�s
Tom�
Tondela
T�nia
Toni
Tony
T�quio
Torcato
Tordesilhas
Torga
Toronto
Torres
Toscana
Toulouse
Tracy
Trancoso
Transcauc�sia
Transilv�nia
Transjord�nia
Transval
Tr�s-os-Montes
Trento
Trevis
Trigueiros
Trindade
Trinit�
Tripoli
Trist�o
Trofa
Tr�ia
Trondheim
Trotski
Ts�
Tuc�dides
Tucultininurta
Tudor
Tui
Tunes
Tun�sia
Turcomenist�o
Turim
Tur�ngia
T�rios
Turner
Turquest�o
Turquia
Tutancamon
Ucr�nia
Uganda
U�ge
Ulisses
Ulster
Umbria
UNESCO
Universo
Urais
�rano
Urbi�n
Uruguai
Uzbequist�o
Valdemar
Valdevez
Valen�a
Valen�a
Val�ncia
Vale
Valentim
Valentino
Valhadolid
Valongo
Val�nia
Valpa�os
Van
Vars�via
Varzim
Vasconcelos
Vasco
Vasques
V�squez
Vassoural
Vaticano
Vaz
Vedras
Veiga
Velado
Vel�squez
Veloso
Ven�ncio
Venceslau
Veneto
Veneza
Venezianos
Venezuela
V�nus
Venusino
Vera
Ver�o
Verdelete
Verdi
Vergara
Ver�ssimo
Verona
Veron�s
Versalhes
Vesta
Ves�vio
Via-L�ctea
Viana
Vicente
Vichy
Vi�osa
Victoria
Victor
Vidigueira
Viegas
Vieira
Viena
Vietname
Vigo
Vilafranca
Vilari�a
Vilarinho
Vilar
Vilela
Vilhena
Vilnius
Vimioso
Vinci
Vingt
Vinhais
Virg�lio
Virg�nia
Virgo
Viriato
Visconti
Viseu
V�stula
Vito
Vit�ria
Vitorina
Vitorino
V�tor
Vivaldi
Vizela
Vladimir
Vladivostok
Volga
Voltaire
Volta
Von
Vorarlberg
Vouga
Vouzela
Vulcano
Vulgata
Wagneri
Walter
Washington
Waterloo
Watson
WC
Weber
Weimar
Welles
Westminster
White
Wilde
William
Williams
Wilson
Windsor
Winston
Wolf
Xanana
Xangai
Xavier
Xenofonte
Xerxes
Xiitas
Ximenes
Xira
Xiva
Yale
Yang
Yao
Yoga
Yorkshire
York
Zacarias
Zagreb
Zaire
Zambeze
Zamb�zia
Z�mbia
Zamora
Zanzibar
Zapatait
Zeca
Zeferino
Zel�ndia
Z�lia
Z�
Zeus
Z�zere
Zimbabwe
Zod�aco
Zola
Zulmira
Zurique

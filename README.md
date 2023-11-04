<div>
    <p><a href="https://github.com/philiprbrenan/SiliconChip"><img src="https://github.com/philiprbrenan/SiliconChip/workflows/Test/badge.svg"></a>
</div>

# Name

Silicon::Chip - Design a [silicon](https://en.wikipedia.org/wiki/Silicon) [chip](https://en.wikipedia.org/wiki/Integrated_circuit) by combining [logic gates](https://en.wikipedia.org/wiki/Logic_gate) and sub [chips](https://en.wikipedia.org/wiki/Integrated_circuit).

# Synopsis

Create and simulate the operation of a 4-bit comparator. Given two 4-bit
unsigned integers, the comparator indicates whether the first integer is
more than the second:

    my $B = 4;
    my $c = Silicon::Chip::newChip(title=>"$B Bit Compare");

    $c->input( "a$_") for 1..$B;                                    # First number
    $c->input( "b$_") for 1..$B;                                    # Second number
    $c->gate("nxor",   "e$_", {1=>"a$_", 2=>"b$_"}) for 1..$B-1;    # Test each bit for equality
    $c->gate("gt",     "g$_", {1=>"a$_", 2=>"b$_"}) for 1..$B;      # Test each bit pair for greater

    for my $b(2..$B)
     {$c->and(  "c$b", {(map {$_=>"e$_"} 1..$b-1), $b=>"g$b"});     # Greater on one bit and all preceding bits are equal
     }

    $c->gate("or",     "or",  {1=>"g1",  (map {$_=>"c$_"} 2..$B)}); # Any set bit indicates that 'a' is more than 'b'
    $c->output( "out", "or");                                       # Output 1 if a > b else 0

    my $t = $c->simulate({a1=>1, a2=>1, a3=>1, a4=>0,
                          b1=>1, b2=>0, b3=>1, b4=>0},
                          svg=>"svg/Compare$B");                    # Svg drawing of layout
    is_deeply($t->values->{out}, 1);

To obtain:

<div>
    <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/Compare4.svg">
</div>

Other circuit diagrams can be seen in folder: [lib/Silicon/svg](https://github.com/philiprbrenan/SiliconChip/tree/main/lib/Silicon/svg)

# Description

Design a [silicon](https://en.wikipedia.org/wiki/Silicon) [chip](https://en.wikipedia.org/wiki/Integrated_circuit) by combining [logic gates](https://en.wikipedia.org/wiki/Logic_gate) and sub [chips](https://en.wikipedia.org/wiki/Integrated_circuit).

Version 20231031.

The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see [Index](#index).

# Construct

Construct a [Silicon](https://en.wikipedia.org/wiki/Silicon) [chip](https://en.wikipedia.org/wiki/Integrated_circuit) using standard [logic gates](https://en.wikipedia.org/wiki/Logic_gate), components and sub chips combined via buses.

## newChip(%options)

Create a new [chip](https://en.wikipedia.org/wiki/Integrated_circuit).

       Parameter  Description
    1  %options   Options

**Example:**

    if (1)                                                                           # Single AND gate

     {my $c = Silicon::Chip::newChip;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      $c->input ("i1");
      $c->input ("i2");
      $c->and   ("and1", {1=>q(i1), 2=>q(i2)});
      $c->output("o", "and1");
      my $s = $c->simulate({i1=>1, i2=>1});
      ok($s->steps          == 2);
      ok($s->values->{and1} == 1);
     }

## gate($chip, $type, $output, $inputs)

A [logic gate](https://en.wikipedia.org/wiki/Logic_gate) of some sort to be added to the [chip](https://en.wikipedia.org/wiki/Integrated_circuit).

       Parameter  Description
    1  $chip      Chip
    2  $type      Gate type
    3  $output    Output name
    4  $inputs    Input names to output from another gate

**Example:**

    if (1)                                                                           # Two AND gates driving an OR gate  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     {my $c = newChip;
      $c->input ("i11");
      $c->input ("i12");
      $c->and   ("and1", {1=>q(i11),  2=>q(i12)});
      $c->input ("i21");
      $c->input ("i22");
      $c->and   ("and2", {1=>q(i21),  2=>q(i22)});
      $c->or    ("or",   {1=>q(and1), 2=>q(and2)});
      $c->output( "o", "or");
      my $s = $c->simulate({i11=>1, i12=>1, i21=>1, i22=>1});
      ok($s->steps         == 3);
      ok($s->values->{or}  == 1);
         $s  = $c->simulate({i11=>1, i12=>0, i21=>1, i22=>1});
      ok($s->steps         == 3);
      ok($s->values->{or}  == 1);
         $s  = $c->simulate({i11=>1, i12=>0, i21=>1, i22=>0});
      ok($s->steps         == 3);
      ok($s->values->{o}   == 0);
     }

## Buses

A bus is an array of bits or an array of arrays of bits

### Bits

An array of bits that can be manipulated via one name.

#### inputBits($chip, $name, $bits, %options)

Create an **input** bus made of bits.

       Parameter  Description
    1  $chip      Chip
    2  $name      Name of bus
    3  $bits      Width in bits of bus
    4  %options   Options

**Example:**

    if (1)
     {my $W = 8;
      my $i = newChip(name=>"not");

         $i->inputBits('i',     $W);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

         $i->notBits  (qw(n i), $W);
         $i->outputBits(qw(o n), $W);

      my $o = newChip(name=>"outer");

         $o->inputBits ('a',     $W);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

         $o->outputBits(qw(A a), $W);

         $o->inputBits ('b',     $W);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

         $o->outputBits(qw(B b), $W);

      my %i = connectBits($i, 'i', $o, 'A', $W);
      my %o = connectBits($i, 'o', $o, 'b', $W);
      $o->install($i, {%i}, {%o});

      my %d = setN('a', $W, 0b10110);
      my $s = $o->simulate({%d}, svg=>"svg/not$W");
      is_deeply($s->bitsToInteger('B', $W), 0b11101001);
     }

#### outputBits($chip, $name, $input, $bits, %options)

Create an **output** bus made of bits.

       Parameter  Description
    1  $chip      Chip
    2  $name      Name of bus
    3  $input     Name of inputs
    4  $bits      Width in bits of bus
    5  %options   Options

**Example:**

    if (1)
     {my $W = 8;
      my $i = newChip(name=>"not");
         $i->inputBits('i',     $W);
         $i->notBits  (qw(n i), $W);

         $i->outputBits(qw(o n), $W);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


      my $o = newChip(name=>"outer");
         $o->inputBits ('a',     $W);

         $o->outputBits(qw(A a), $W);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

         $o->inputBits ('b',     $W);

         $o->outputBits(qw(B b), $W);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


      my %i = connectBits($i, 'i', $o, 'A', $W);
      my %o = connectBits($i, 'o', $o, 'b', $W);
      $o->install($i, {%i}, {%o});

      my %d = setN('a', $W, 0b10110);
      my $s = $o->simulate({%d}, svg=>"svg/not$W");
      is_deeply($s->bitsToInteger('B', $W), 0b11101001);
     }

    if (1)
     {my @B = ((my $W = 4), (my $B = 2));

      my $c = newChip();
         $c->inputWords ('i',           @B);
         $c->andWords   (qw(and  i),    @B);
         $c->andWordsX  (qw(andX i),    @B);
         $c-> orWords   (qw( or  i),    @B);
         $c-> orWordsX  (qw( orX i),    @B);
         $c->notWords   (qw(n    i),    @B);

         $c->outputBits (qw(And  and),  $W);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


         $c->outputBits (qw(AndX andX), $B);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


         $c->outputBits (qw(Or   or),   $W);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


         $c->outputBits (qw(OrX  orX),  $B);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

         $c->outputWords(qw(N    n),    @B);

      my %d = setNN('i', $W, $B, 0b00,
                                 0b01,
                                 0b10,
                                 0b11);
      my $s = $c->simulate({%d}, svg=>"svg/andOrWords$W");

      is_deeply($s->bitsToInteger('And',  $W),  0b1000);
      is_deeply($s->bitsToInteger('AndX', $B),  0b00);

      is_deeply($s->bitsToInteger ('Or',   $W),  0b1110);
      is_deeply($s->bitsToInteger ('OrX',  $B),  0b11);
      is_deeply([$s->wordsToInteger('N',    @B)],  [3, 2, 1, 0]);
     }

#### notBits($chip, $name, $input, $bits, %options)

Create a **not** bus made of bits.

       Parameter  Description
    1  $chip      Chip
    2  $name      Name of bus
    3  $input     Name of inputs
    4  $bits      Width in bits of bus
    5  %options   Options

**Example:**

    if (1)
     {my $W = 8;
      my $i = newChip(name=>"not");
         $i->inputBits('i',     $W);

         $i->notBits  (qw(n i), $W);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

         $i->outputBits(qw(o n), $W);

      my $o = newChip(name=>"outer");
         $o->inputBits ('a',     $W);
         $o->outputBits(qw(A a), $W);
         $o->inputBits ('b',     $W);
         $o->outputBits(qw(B b), $W);

      my %i = connectBits($i, 'i', $o, 'A', $W);
      my %o = connectBits($i, 'o', $o, 'b', $W);
      $o->install($i, {%i}, {%o});

      my %d = setN('a', $W, 0b10110);
      my $s = $o->simulate({%d}, svg=>"svg/not$W");
      is_deeply($s->bitsToInteger('B', $W), 0b11101001);
     }

#### andBits($chip, $name, $input, $bits, %options)

**and** a bus made of bits.

       Parameter  Description
    1  $chip      Chip
    2  $name      Name of bus
    3  $input     Name of inputs
    4  $bits      Width in bits of bus
    5  %options   Options

**Example:**

    if (1)
     {my $W = 8;

      my $c = newChip();
         $c-> inputBits('i',         $W);

         $c->   andBits(qw(and i),   $W);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

         $c->    orBits(qw(or  i),   $W);
         $c->output    (qw(And and));
         $c->output    (qw(Or  or));

      my %d = setN('i', $W, 0b10110);
      my $s = $c->simulate({%d}, svg=>"svg/andOrBits$W");

      is_deeply($s->values->{and}, 0);
      is_deeply($s->values->{or},  1);
     }

#### orBits($chip, $name, $input, $bits, %options)

**or** a bus made of bits.

       Parameter  Description
    1  $chip      Chip
    2  $name      Name of bus
    3  $input     Name of inputs
    4  $bits      Width in bits of bus
    5  %options   Options

**Example:**

    if (1)
     {my $W = 8;

      my $c = newChip();
         $c-> inputBits('i',         $W);
         $c->   andBits(qw(and i),   $W);

         $c->    orBits(qw(or  i),   $W);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

         $c->output    (qw(And and));
         $c->output    (qw(Or  or));

      my %d = setN('i', $W, 0b10110);
      my $s = $c->simulate({%d}, svg=>"svg/andOrBits$W");

      is_deeply($s->values->{and}, 0);
      is_deeply($s->values->{or},  1);
     }

### Words

An array of arrays of bits that can be manipulated via one name.

#### inputWords($chip, $name, $words, $bits, %options)

Create an **input** bus made of words.

       Parameter  Description
    1  $chip      Chip
    2  $name      Name of bus
    3  $words     Width in words of bus
    4  $bits      Width in bits of each word on bus
    5  %options   Options

**Example:**

#### outputWords($chip, $name, $input, $words, $bits, %options)

Create an **output** bus made of words.

       Parameter  Description
    1  $chip      Chip
    2  $name      Name of bus
    3  $input     Name of inputs
    4  $words     Width in words of bus
    5  $bits      Width in bits of each word on bus
    6  %options   Options

**Example:**

#### notWords($chip, $name, $input, $words, $bits, %options)

Create a **not** bus made of words.

       Parameter  Description
    1  $chip      Chip
    2  $name      Name of bus
    3  $input     Name of inputs
    4  $words     Width in words of bus
    5  $bits      Width in bits of each word on bus
    6  %options   Options

**Example:**

    if (1)
     {my @B = ((my $W = 4), (my $B = 2));

      my $c = newChip();
         $c->inputWords ('i',           @B);
         $c->andWords   (qw(and  i),    @B);
         $c->andWordsX  (qw(andX i),    @B);
         $c-> orWords   (qw( or  i),    @B);
         $c-> orWordsX  (qw( orX i),    @B);

         $c->notWords   (qw(n    i),    @B);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

         $c->outputBits (qw(And  and),  $W);
         $c->outputBits (qw(AndX andX), $B);
         $c->outputBits (qw(Or   or),   $W);
         $c->outputBits (qw(OrX  orX),  $B);
         $c->outputWords(qw(N    n),    @B);

      my %d = setNN('i', $W, $B, 0b00,
                                 0b01,
                                 0b10,
                                 0b11);
      my $s = $c->simulate({%d}, svg=>"svg/andOrWords$W");

      is_deeply($s->bitsToInteger('And',  $W),  0b1000);
      is_deeply($s->bitsToInteger('AndX', $B),  0b00);

      is_deeply($s->bitsToInteger ('Or',   $W),  0b1110);
      is_deeply($s->bitsToInteger ('OrX',  $B),  0b11);
      is_deeply([$s->wordsToInteger('N',    @B)],  [3, 2, 1, 0]);
     }

#### andWords($chip, $name, $input, $words, $bits, %options)

**and** a bus made of words to produce a single word

       Parameter  Description
    1  $chip      Chip
    2  $name      Name of bus
    3  $input     Name of inputs
    4  $words     Width in words of bus
    5  $bits      Width in bits of each word on bus
    6  %options   Options

**Example:**

    if (1)
     {my @B = ((my $W = 4), (my $B = 2));

      my $c = newChip();
         $c->inputWords ('i',           @B);

         $c->andWords   (qw(and  i),    @B);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

         $c->andWordsX  (qw(andX i),    @B);
         $c-> orWords   (qw( or  i),    @B);
         $c-> orWordsX  (qw( orX i),    @B);
         $c->notWords   (qw(n    i),    @B);
         $c->outputBits (qw(And  and),  $W);
         $c->outputBits (qw(AndX andX), $B);
         $c->outputBits (qw(Or   or),   $W);
         $c->outputBits (qw(OrX  orX),  $B);
         $c->outputWords(qw(N    n),    @B);

      my %d = setNN('i', $W, $B, 0b00,
                                 0b01,
                                 0b10,
                                 0b11);
      my $s = $c->simulate({%d}, svg=>"svg/andOrWords$W");

      is_deeply($s->bitsToInteger('And',  $W),  0b1000);
      is_deeply($s->bitsToInteger('AndX', $B),  0b00);

      is_deeply($s->bitsToInteger ('Or',   $W),  0b1110);
      is_deeply($s->bitsToInteger ('OrX',  $B),  0b11);
      is_deeply([$s->wordsToInteger('N',    @B)],  [3, 2, 1, 0]);
     }

    if (1)

     {my @b = ((my $W = 4), (my $B = 3));

      my $c = newChip();
         $c->inputWords ('i',      @b);
         $c->outputWords(qw(o i),  @b);

      my %d = setNN('i', $W, $B, 0b000,
                                 0b001,
                                 0b010,
                                 0b011);
      my $s = $c->simulate({%d}, svg=>"svg/words$W");

      is_deeply([$s->wordsToInteger('o', @b)], [0..3]);
      is_deeply([$s->wordXToInteger('o', @b)], [0, 12, 10]);
     }

#### andWordsX($chip, $name, $input, $words, $bits, %options)

**and** a bus made of words by anding the corresponding bits in each word to mak a single word.

       Parameter  Description
    1  $chip      Chip
    2  $name      Name of bus
    3  $input     Name of inputs
    4  $words     Width in words of bus
    5  $bits      Width in bits of each word on bus
    6  %options   Options

**Example:**

    if (1)
     {my @B = ((my $W = 4), (my $B = 2));

      my $c = newChip();
         $c->inputWords ('i',           @B);
         $c->andWords   (qw(and  i),    @B);

         $c->andWordsX  (qw(andX i),    @B);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

         $c-> orWords   (qw( or  i),    @B);
         $c-> orWordsX  (qw( orX i),    @B);
         $c->notWords   (qw(n    i),    @B);
         $c->outputBits (qw(And  and),  $W);
         $c->outputBits (qw(AndX andX), $B);
         $c->outputBits (qw(Or   or),   $W);
         $c->outputBits (qw(OrX  orX),  $B);
         $c->outputWords(qw(N    n),    @B);

      my %d = setNN('i', $W, $B, 0b00,
                                 0b01,
                                 0b10,
                                 0b11);
      my $s = $c->simulate({%d}, svg=>"svg/andOrWords$W");

      is_deeply($s->bitsToInteger('And',  $W),  0b1000);
      is_deeply($s->bitsToInteger('AndX', $B),  0b00);

      is_deeply($s->bitsToInteger ('Or',   $W),  0b1110);
      is_deeply($s->bitsToInteger ('OrX',  $B),  0b11);
      is_deeply([$s->wordsToInteger('N',    @B)],  [3, 2, 1, 0]);
     }

#### orWords($chip, $name, $input, $words, $bits, %options)

**or** a bus made of words to produce a single word.

       Parameter  Description
    1  $chip      Chip
    2  $name      Name of bus
    3  $input     Name of inputs
    4  $words     Width in words of bus
    5  $bits      Width in bits of each word on bus
    6  %options   Options

**Example:**

    if (1)
     {my @B = ((my $W = 4), (my $B = 2));

      my $c = newChip();
         $c->inputWords ('i',           @B);
         $c->andWords   (qw(and  i),    @B);
         $c->andWordsX  (qw(andX i),    @B);

         $c-> orWords   (qw( or  i),    @B);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

         $c-> orWordsX  (qw( orX i),    @B);
         $c->notWords   (qw(n    i),    @B);
         $c->outputBits (qw(And  and),  $W);
         $c->outputBits (qw(AndX andX), $B);
         $c->outputBits (qw(Or   or),   $W);
         $c->outputBits (qw(OrX  orX),  $B);
         $c->outputWords(qw(N    n),    @B);

      my %d = setNN('i', $W, $B, 0b00,
                                 0b01,
                                 0b10,
                                 0b11);
      my $s = $c->simulate({%d}, svg=>"svg/andOrWords$W");

      is_deeply($s->bitsToInteger('And',  $W),  0b1000);
      is_deeply($s->bitsToInteger('AndX', $B),  0b00);

      is_deeply($s->bitsToInteger ('Or',   $W),  0b1110);
      is_deeply($s->bitsToInteger ('OrX',  $B),  0b11);
      is_deeply([$s->wordsToInteger('N',    @B)],  [3, 2, 1, 0]);
     }

    if (1)

     {my @b = ((my $W = 4), (my $B = 3));

      my $c = newChip();
         $c->inputWords ('i',      @b);
         $c->outputWords(qw(o i),  @b);

      my %d = setNN('i', $W, $B, 0b000,
                                 0b001,
                                 0b010,
                                 0b011);
      my $s = $c->simulate({%d}, svg=>"svg/words$W");

      is_deeply([$s->wordsToInteger('o', @b)], [0..3]);
      is_deeply([$s->wordXToInteger('o', @b)], [0, 12, 10]);
     }

#### orWordsX($chip, $name, $input, $words, $bits, %options)

**or** a bus made of words by oring the corresponding bits in each word to make a single word.

       Parameter  Description
    1  $chip      Chip
    2  $name      Name of bus
    3  $input     Name of inputs
    4  $words     Width in words of bus
    5  $bits      Width in bits of each word on bus
    6  %options   Options

**Example:**

    if (1)
     {my @B = ((my $W = 4), (my $B = 2));

      my $c = newChip();
         $c->inputWords ('i',           @B);
         $c->andWords   (qw(and  i),    @B);
         $c->andWordsX  (qw(andX i),    @B);
         $c-> orWords   (qw( or  i),    @B);

         $c-> orWordsX  (qw( orX i),    @B);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

         $c->notWords   (qw(n    i),    @B);
         $c->outputBits (qw(And  and),  $W);
         $c->outputBits (qw(AndX andX), $B);
         $c->outputBits (qw(Or   or),   $W);
         $c->outputBits (qw(OrX  orX),  $B);
         $c->outputWords(qw(N    n),    @B);

      my %d = setNN('i', $W, $B, 0b00,
                                 0b01,
                                 0b10,
                                 0b11);
      my $s = $c->simulate({%d}, svg=>"svg/andOrWords$W");

      is_deeply($s->bitsToInteger('And',  $W),  0b1000);
      is_deeply($s->bitsToInteger('AndX', $B),  0b00);

      is_deeply($s->bitsToInteger ('Or',   $W),  0b1110);
      is_deeply($s->bitsToInteger ('OrX',  $B),  0b11);
      is_deeply([$s->wordsToInteger('N',    @B)],  [3, 2, 1, 0]);
     }

## Install

Install a chip within a chip as a sub chip.

### install($chip, $subChip, $inputs, $outputs, %options)

Install a [chip](https://en.wikipedia.org/wiki/Integrated_circuit) within another [chip](https://en.wikipedia.org/wiki/Integrated_circuit) specifying the connections between the inner and outer [chip](https://en.wikipedia.org/wiki/Integrated_circuit).  The same [chip](https://en.wikipedia.org/wiki/Integrated_circuit) can be installed multiple times as each [chip](https://en.wikipedia.org/wiki/Integrated_circuit) description is read only.

       Parameter  Description
    1  $chip      Outer chip
    2  $subChip   Inner chip
    3  $inputs    Inputs of inner chip to to outputs of outer chip
    4  $outputs   Outputs of inner chip to inputs of outer chip
    5  %options   Options

**Example:**

    if (1)                                                                            # Install one chip inside another chip, specifically one chip that performs NOT is installed once to flip a value
     {my $i = newChip(name=>"not");
         $i->input (n('i', 1));
         $i->not   (n('n', 1), n('i', 1));
         $i->output(n('o', 1), n('n', 1));

      my $o = newChip(name=>"outer");
         $o->input (n('i', 1)); $o->output(n('n', 1), n('i', 1));
         $o->input (n('I', 1)); $o->output(n('N', 1), n('I', 1));

      my %i = connectBits($i, 'i', $o, 'n', 1);
      my %o = connectBits($i, 'o', $o, 'I', 1);

      $o->install($i, {%i}, {%o});  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my %d = setN('i', 1, 1);
      my $s = $o->simulate({%d}, dumpGatesOff=>"dump/not1", svg=>"svg/not1");

      is_deeply($s->steps,  2);
      is_deeply($s->values, {"(not 1 n_1)"=>0, "i_1"=>1, "N_1"=>0 });
     }

# Basic Circuits

Some well known basic circuits.

## n($c, $i)

Gate name from single index

       Parameter  Description
    1  $c         Gate name
    2  $i         Bit number

**Example:**

    if (1)

     {is_deeply( n(a,1),   "a_1");  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply(nn(a,1,2), "a_1_2");
     }

## nn($c, $i, $j)

Gate name from double index

       Parameter  Description
    1  $c         Gate name
    2  $i         Word number
    3  $j         Bit number

**Example:**

    if (1)
     {is_deeply( n(a,1),   "a_1");

      is_deeply(nn(a,1,2), "a_1_2");  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     }

## Comparisons

Compare unsigned binary integers of specified bit widths.

### compareEq($chip, $output, $a, $b, $bits, %options)

Compare two unsigned binary integers of a specified width returning **1** if they are equal else **0**.

       Parameter  Description
    1  $chip      Chip
    2  $output    Name of component also the output bus
    3  $a         First integer
    4  $b         Second integer
    5  $bits      Options
    6  %options

**Example:**

    if (1)                                                                           #bitsToInteger # Compare unsigned integers
     {my $B = 4;

      my $c = Silicon::Chip::newChip(name=>"eq", title=>"$B Bit Compare Equal");

      $c->inputBits($_, $B) for qw(a b);                                            # First and second numbers


      $c->compareEq(qw(out a b), $B);                                               # Compare equals  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


      my %a = setN('a', $B, 2);                                                     # Number a
      my %b = setN('b', $B, 2);                                                     # Number b

      my $s = $c->simulate({%a, %b}, svg=>"svg/CompareEq$B");                       # Svg drawing of layout
      is_deeply($s->values->{out}, 1);                                              # Equal
      is_deeply($s->steps, 3);                                                      # Number of steps to stability

      my $t = $c->simulate({%a, %b, n(b,1)=>1});                                    # No longer equal
      is_deeply($t->values->{out}, 0);                                              # Not equal
      is_deeply($t->steps, 3);                                                      # Number of steps to stability
     }

### compareGt($chip, $output, $a, $b, $bits, %options)

Compare two unsigned binary integers of specified width and return **1** if the first integer is more than **b** else **0**.

       Parameter  Description
    1  $chip      Chip
    2  $output    Name of component also the output bus
    3  $a         First integer
    4  $b         Second integer
    5  $bits      Options
    6  %options

**Example:**

    if (1)                                                                           # Compare 8 bit unsigned integers 'a' > 'b' - the pins used to input 'a' must be alphabetically less than those used for 'b'
     {my $B = 8;
      my $c = Silicon::Chip::newChip(name=>"gt", title=>"$B Bit Compare more than");

      $c->inputBits($_, $B) for qw(a b);                                            # First and second numbers


      $c->compareGt(qw(out a b), $B);                                               # Compare more than  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


      my %a = setN('a', $B, 3);                                                     # Number a
      my %b = setN('b', $B, 2);                                                     # Number b

      my $s = $c->simulate({%a, %b}, svg=>"svg/CompareGt$B");                       # Svg drawing of layout
      is_deeply($s->values->{out}, 1);                                              # More than
      is_deeply($s->steps, 4);                                                      # Number of steps to stability

      my $t = $c->simulate({%a, %b, n(b,1)=>1});                                    # No longer more than
      is_deeply($t->values->{out}, 0);                                              # Not more than
      is_deeply($t->steps, 4);                                                      # Number of steps to stability
     }

### compareLt($chip, $output, $a, $b, $bits, %options)

Compare two unsigned binary integers **a**, **b** of a specified width. Output **out** is **1** if **a** is less than **b** else **0**.

       Parameter  Description
    1  $chip      Chip
    2  $output    Name of component also the output bus
    3  $a         First integer
    4  $b         Second integer
    5  $bits      Options
    6  %options

**Example:**

    if (1)                                                                           # Compare 8 bit unsigned integers 'a' < 'b' - the pins used to input 'a' must be alphabetically less than those used for 'b'
     {my $B = 8;
      my $c = Silicon::Chip::newChip(name=>"lt", title=>"$B Bit Compare Less Than");

      $c->inputBits($_, $B) for qw(a b);                                            # First and second numbers


      $c->compareLt(qw(out a b), $B);                                               # Compare less than  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


      my %a = setN('a', $B, 2);                                                     # Number a
      my %b = setN('b', $B, 3);                                                     # Number b

      my $s = $c->simulate({%a, %b}, svg=>"svg/CompareLt$B");                       # Svg drawing of layout
      is_deeply($s->values->{out}, 1);                                               # Less than
      is_deeply($s->steps, 4);                                                      # Number of steps to stability

      my $t = $c->simulate({%a, %b, n(a,1)=>1});                                    # No longer less than
      is_deeply($t->values->{out}, 0);                                              # Not less than
      is_deeply($t->steps, 4);                                                      # Number of steps to stability
     }

## Masks

Point masks and monotone masks. A point mask has a single **1** in a sea of **0**s as in **00100**.  A monotone mask has zero or more **0**s followed by all **1**s as in: **00111**.

### pointMaskToInteger($chip, $output, $input, $bits, %options)

Convert a mask **i** known to have at most a single bit on - also known as a **point mask** - to an output number **a** representing the location in the mask of the bit set to **1**. If no such bit exists in the point mask then output number **a** is **0**.

       Parameter  Description
    1  $chip      Chip
    2  $output    Output name
    3  $input     Input mask
    4  $bits      Number of bits in mask
    5  %options   Options

**Example:**

    if (1)
     {my $B = 4;
      my $N = 2**$B-1;

      my $c = Silicon::Chip::newChip(title=>"$B bits point mask to integer");

      $c->inputBits         (qw(    i), $N);                                        # Mask with no more than one bit on

      $c->pointMaskToInteger(qw(o   i), $B);                                        # Convert  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      $c->outputBits        (qw(out o), $B);                                        # Mask with no more than one bit on

      for my $i(0..$N)                                                              # Each position of mask
       {my %i = setN('i', $N, $i ? 1<<($i-1) : 0);                                  # Point in each position with zero representing no position
        my $s = $c->simulate(\%i, $i == 5 ? (svg=>"svg/point$B") : ());
        is_deeply($s->steps, 2);
        my %o = $s->values->%*;                                                     # Output bits
        my $n = eval join '', '0b', map {$o{n(o,$_)}} reverse 1..$B;                # Output bits as number
        is_deeply($n, $i);
       }
     }

### integerToPointMask($chip, $output, $input, $bits, %options)

Convert an integer **i** of specified width to a point mask **m**. If the input integer is **0** then the mask is all zeroes as well.

       Parameter  Description
    1  $chip      Chip
    2  $output    Output name
    3  $input     Input mask
    4  $bits      Number of bits in mask
    5  %options   Options

**Example:**

    if (1)
     {my $B = 3;
      my $N = 2**$B-1;

      my $c = Silicon::Chip::newChip(title=>"$B bit integer to $N bits monotone mask");
         $c->inputBits         (qw(  i), $B);                                       # Input bus

         $c->integerToPointMask(qw(m i), $B);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

         $c->outputBits        (qw(o m), $N);

      for my $i(0..$N)                                                              # Each position of mask
       {my %i = setN('i', $B, $i);
        my $s = $c->simulate(\%i, $i == 5 ? (svg=>"svg/integerToMontoneMask$B"):());
        is_deeply($s->steps, 3);

        my $r = $s->bitsToInteger('o', $N);                                         # Mask values
        is_deeply($r, $i ? 1<<($i-1) : 0);                                          # Expected mask
       }
     }

### monotoneMaskToInteger($bits, %options)

Convert a monotone mask **i** to an output number **r** representing the location in the mask of the bit set to **1**. If no such bit exists in the point then output in **r** is **0**.

       Parameter  Description
    1  $bits      Bits
    2  %options   Options

**Example:**

    if (1)
     {my $B = 4;
      my $N = 2**$B-1;

      my $c = monotoneMaskToInteger($B);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


      for my $i(0..$N-1)                                                            # Each monotone mask
       {my %i = map {(n(i,$_)=> $i > 0 && $_ >= $i ? 1 : 0)} 1..$N;

        my $s = $c->simulate(\%i, $i == 5 ? (svg=>"svg/monotoneMaskToInteger$B") : ());  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


        is_deeply($s->steps, 4);
        my %o = $s->values->%*;                                                     # Output bits
        my $n = eval join '', '0b', map {$o{n(o,$_)}} reverse 1..$B;                # Output bits as number
        is_deeply($n, $i);
       }
     }

### integerToMonotoneMask($bits, %options)

Convert an integer **i** of specified width to a monotone mask **m**. If the input integer is **0** then the mask is all zeroes.  Otherwise the mask has **i-1** leading zeroes followed by all ones thereafter.

       Parameter  Description
    1  $bits      Bits
    2  %options   Options

**Example:**

    if (1)
     {my $B = 3;

      my $c = integerToMonotoneMask($B);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


      for my $i(0..2**$B-1)                                                         # Each position of mask
       {my @n = reverse split //, sprintf "%0${B}b", $i;
        my %i = map {(n(i,$_)=>$n[$_-1])} 1..@n;
        my $s = $c->simulate(\%i, $i == 5 ? (svg=>"svg/integerToMontoneMask$B"):());
        is_deeply($s->steps, 4);

        my %v = $s->values->%*; delete $v{$_} for grep {!m/\Am/} keys %v;           # Mask values
        my %m = map {(n('m',$_)=> ($i > 0 && $_ >= $i ? 1 : 0))} 1..2**$B-1;        # Expected mask
        is_deeply({%v}, {%m});                                                      # Expected mask
       }
     }

### chooseWordUnderMask($words, $bits, %options)

Choose one of a specified number of words **w**, each of a specified width, using a point mask **m** placing the selected word in **o**.  If no word is selected then **o** will be zero.

       Parameter  Description
    1  $words     Number of words
    2  $bits      Bits in each word
    3  %options   Options

**Example:**

    if (1)
     {my $B = 2; my $W = 2;

      my $c = chooseWordUnderMask($W, $B);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my %i = setNN('w', $B, $W, reverse 1..$W);
      my %m = setN ('m', $B, 1);

      my $s = $c->simulate({%i, %m}, svg=>"svg/choose_${W}_$B");

      is_deeply($s->steps, 3);
      is_deeply($s->values->{n(o,1)}, 1);
      is_deeply($s->values->{n(o,2)}, 0);
     }

### findWord($words, $bits, %options)

Choose one of a specified number of words **w**, each of a specified width, using a key **k**.  Return a point mask **o** indicating the locations of the key if found or or a mask equal to all zeroes if the key is not present.

       Parameter  Description
    1  $words     Number of words
    2  $bits      Bits in each word and key
    3  %options   Options

**Example:**

    if (0)
     {my $B = 2; my $W = 2;

      my $c = findWord($W, $B);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


      my %i = setNN('w', $B, $W, reverse 1..$W);
      my %m = setN ('m', $B, 0);

      if (1)                                                                        # Find key 2 at position 2
       {my $s = $c->simulate({%i, %m, n(k,2)=>1, n(k,1)=>0}, svg=>"svg/findWord_${W}_$B");
        is_deeply($s->steps, 3);
        is_deeply($s->values->{n(o,1)}, 0);
        is_deeply($s->values->{n(o,2)}, 1);
       }

      if (1)                                                                        # Find key 1 at position 1
       {my $s = $c->simulate({%i, %m, n(k,2)=>0, n(k,1)=>1});
        is_deeply($s->steps, 3);
        is_deeply($s->values->{n(o,1)}, 1);
        is_deeply($s->values->{n(o,2)}, 0);
       }

      if (1)                                                                        # Find key 0 - does not exist
       {my $s = $c->simulate({%i, %m, n(k,2)=>0, n(k,1)=>0});
        is_deeply($s->steps, 3);
        is_deeply($s->values->{n(o,1)}, 0);
        is_deeply($s->values->{n(o,2)}, 0);
       }

      if (1)                                                                        # Find key 3 - does not exist
       {my $s = $c->simulate({%i, %m, n(k,2)=>1, n(k,1)=>1});
        is_deeply($s->steps, 3);
        is_deeply($s->values->{n(o,1)}, 0);
        is_deeply($s->values->{n(o,2)}, 0);
       }
     }

# Simulate

Simulate the behavior of the [chip](https://en.wikipedia.org/wiki/Integrated_circuit) given a set of values on its input gates.

## setN($name, $width, $value)

Set an array of input gates to a number prior to running a simulation.

       Parameter  Description
    1  $name      Name of input gates
    2  $width     Number of bits in each array element
    3  $value     Number to set to

**Example:**

    if (1)

     {is_deeply({setN('a', 4, 5)}, {n(a,1)=>1, n(a,2)=>0, n(a,3)=>1, n(a,4)=>0});  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


      is_deeply({setN('a', 4, 6)}, {n(a,1)=>0, n(a,2)=>1, n(a,3)=>1, n(a,4)=>0});  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


      is_deeply({setNN('a', 4, 2, 3,2,3,1)}, {nn(a,1,1)=>1, nn(a,1,2)=>1,  nn(a,2,1)=>1, nn(a,2,2)=>0,  nn(a,3,1)=>1, nn(a,3,2)=>1,  nn(a,4,1)=>0, nn(a,4,2)=>1});
      is_deeply({setNN('a', 4, 2, 3,2,3,2)}, {nn(a,1,1)=>1, nn(a,1,2)=>1,  nn(a,2,1)=>1, nn(a,2,2)=>0,  nn(a,3,1)=>1, nn(a,3,2)=>1,  nn(a,4,1)=>1, nn(a,4,2)=>0});
     }

## setNN($name, $width1, $width2, @values)

Set an array of arrays of gates to an array of numbers prior to running a simulation.

       Parameter  Description
    1  $name      Name of input gates
    2  $width1    Number of arrays
    3  $width2    Number of bits in each array element
    4  @values    Numbers to set to

**Example:**

    if (1)
     {is_deeply({setN('a', 4, 5)}, {n(a,1)=>1, n(a,2)=>0, n(a,3)=>1, n(a,4)=>0});
      is_deeply({setN('a', 4, 6)}, {n(a,1)=>0, n(a,2)=>1, n(a,3)=>1, n(a,4)=>0});


      is_deeply({setNN('a', 4, 2, 3,2,3,1)}, {nn(a,1,1)=>1, nn(a,1,2)=>1,  nn(a,2,1)=>1, nn(a,2,2)=>0,  nn(a,3,1)=>1, nn(a,3,2)=>1,  nn(a,4,1)=>0, nn(a,4,2)=>1});  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


      is_deeply({setNN('a', 4, 2, 3,2,3,2)}, {nn(a,1,1)=>1, nn(a,1,2)=>1,  nn(a,2,1)=>1, nn(a,2,2)=>0,  nn(a,3,1)=>1, nn(a,3,2)=>1,  nn(a,4,1)=>1, nn(a,4,2)=>0});  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     }

## connectBits($oc, $o, $ic, $i, $bits, %options)

Create a connection list connecting a set of output bits on the one chip to a set of input bits on another chip.

       Parameter  Description
    1  $oc        First chip
    2  $o         Name of gates on first chip
    3  $ic        Second chip
    4  $i         Names of gates on second chip
    5  $bits      Number of bits to connect
    6  %options   Options

**Example:**

    if (1)                                                                            # Install one chip inside another chip, specifically one chip that performs NOT is installed once to flip a value
     {my $i = newChip(name=>"not");
         $i->input (n('i', 1));
         $i->not   (n('n', 1), n('i', 1));
         $i->output(n('o', 1), n('n', 1));

      my $o = newChip(name=>"outer");
         $o->input (n('i', 1)); $o->output(n('n', 1), n('i', 1));
         $o->input (n('I', 1)); $o->output(n('N', 1), n('I', 1));


      my %i = connectBits($i, 'i', $o, 'n', 1);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


      my %o = connectBits($i, 'o', $o, 'I', 1);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      $o->install($i, {%i}, {%o});
      my %d = setN('i', 1, 1);
      my $s = $o->simulate({%d}, dumpGatesOff=>"dump/not1", svg=>"svg/not1");

      is_deeply($s->steps,  2);
      is_deeply($s->values, {"(not 1 n_1)"=>0, "i_1"=>1, "N_1"=>0 });
     }

## connectWords($oc, $o, $ic, $i, $words, $bits, %options)

Create a connection list connecting a set of words on the outer chip to a set of words on the inner chip.

       Parameter  Description
    1  $oc        First chip
    2  $o         Name of gates on first chip
    3  $ic        Second chip
    4  $i         Names of gates on second chip
    5  $words     Number of words to connect
    6  $bits      Options
    7  %options

**Example:**

    if (1)                                                                           # Install one chip inside another chip, specifically one chip that performs NOT is installed three times sequentially to flip a value
     {my $i = newChip(name=>"not");
         $i->input (nn('i', 1, 1));
         $i->not   (nn('n', 1, 1), nn('i', 1, 1));
         $i->output(nn('o', 1, 1), nn('n', 1, 1));

      my $o = newChip(name=>"outer");
         $o->input (nn('i', 1, 1)); $o->output(nn('n', 1, 1), nn('i', 1, 1));
         $o->input (nn('I', 1, 1)); $o->output(nn('N', 1, 1), nn('I', 1, 1));


      my %i = connectWords($i, 'i', $o, 'n', 1, 1);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


      my %o = connectWords($i, 'o', $o, 'I', 1, 1);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      $o->install($i, {%i}, {%o});
      my %d = setNN('i', 1, 1, 1);
      my $s = $o->simulate({%d}, dumpGatesOff=>"dump/not1", svg=>"svg/not1");

      is_deeply($s->steps,  2);
      is_deeply($s->values, { "(not 1 n_1_1)" => 0, "i_1_1" => 1, "N_1_1" => 0 });
     }

## Silicon::Chip::Simulation::Results::bitsToInteger($simulation, $output, $bits, %options)

Represent the state of bits in the simulation results as an unsigned binary integer.

       Parameter    Description
    1  $simulation  Chip
    2  $output      Name of gates on bus
    3  $bits        Width in bits of bus
    4  %options     Options

**Example:**

    if (1)
     {my $W = 8;
      my $i = newChip(name=>"not");
         $i->inputBits('i',     $W);
         $i->notBits  (qw(n i), $W);
         $i->outputBits(qw(o n), $W);

      my $o = newChip(name=>"outer");
         $o->inputBits ('a',     $W);
         $o->outputBits(qw(A a), $W);
         $o->inputBits ('b',     $W);
         $o->outputBits(qw(B b), $W);

      my %i = connectBits($i, 'i', $o, 'A', $W);
      my %o = connectBits($i, 'o', $o, 'b', $W);
      $o->install($i, {%i}, {%o});

      my %d = setN('a', $W, 0b10110);
      my $s = $o->simulate({%d}, svg=>"svg/not$W");
      is_deeply($s->bitsToInteger('B', $W), 0b11101001);
     }

## Silicon::Chip::Simulation::Results::wordsToInteger($simulation, $output, $words, $bits, %options)

Represent the state of words in the simulation results as an array of unsigned binary integer.

       Parameter    Description
    1  $simulation  Chip
    2  $output      Name of gates on bus
    3  $words       Number of words
    4  $bits        Width in bits of bus
    5  %options     Options

**Example:**

    if (1)

     {my @b = ((my $W = 4), (my $B = 3));

      my $c = newChip();
         $c->inputWords ('i',      @b);
         $c->outputWords(qw(o i),  @b);

      my %d = setNN('i', $W, $B, 0b000,
                                 0b001,
                                 0b010,
                                 0b011);
      my $s = $c->simulate({%d}, svg=>"svg/words$W");

      is_deeply([$s->wordsToInteger('o', @b)], [0..3]);
      is_deeply([$s->wordXToInteger('o', @b)], [0, 12, 10]);
     }

## Silicon::Chip::Simulation::Results::wordXToInteger($simulation, $output, $words, $bits, %options)

Represent the state of words in the simulation results as an array of unsigned binary integer.

       Parameter    Description
    1  $simulation  Chip
    2  $output      Name of gates on bus
    3  $words       Number of words
    4  $bits        Width in bits of bus
    5  %options     Options

**Example:**

    if (1)

     {my @b = ((my $W = 4), (my $B = 3));

      my $c = newChip();
         $c->inputWords ('i',      @b);
         $c->outputWords(qw(o i),  @b);

      my %d = setNN('i', $W, $B, 0b000,
                                 0b001,
                                 0b010,
                                 0b011);
      my $s = $c->simulate({%d}, svg=>"svg/words$W");

      is_deeply([$s->wordsToInteger('o', @b)], [0..3]);
      is_deeply([$s->wordXToInteger('o', @b)], [0, 12, 10]);
     }

## simulate($chip, $inputs, %options)

Simulate the action of the [logic gates](https://en.wikipedia.org/wiki/Logic_gate) on a [chip](https://en.wikipedia.org/wiki/Integrated_circuit) for a given set of inputs until the output value of each [logic gate](https://en.wikipedia.org/wiki/Logic_gate) stabilizes.

       Parameter  Description
    1  $chip      Chip
    2  $inputs    Hash of input names to values
    3  %options   Options

**Example:**

    if (1)
     {my $i = newChip(name=>"inner");
         $i->input ("Ii");
         $i->not   ("In", "Ii");
         $i->output( "Io", "In");

      my $o = newChip(name=>"outer");
         $o->input ("Oi1");
         $o->output("Oo1", "Oi1");
         $o->input ("Oi2");
         $o->output("Oo2", "Oi2");
         $o->input ("Oi3");
         $o->output("Oo3", "Oi3");
         $o->input ("Oi4");
         $o->output("Oo",  "Oi4");

      $o->install($i, {Ii=>"Oo1"}, {Io=>"Oi2"});
      $o->install($i, {Ii=>"Oo2"}, {Io=>"Oi3"});
      $o->install($i, {Ii=>"Oo3"}, {Io=>"Oi4"});


      my $s = $o->simulate({Oi1=>1}, dumpGatesOff=>"dump/not3", svg=>"svg/not3");  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply($s->values->{Oo}, 0);
      is_deeply($s->steps,        4);
     }

# Hash Definitions

## Silicon::Chip Definition

Chip description

### Output fields

#### gateSeq

Gate sequence number - this allows us to display the gates in the order they were defined ti simplify the understanding of drawn layouts

#### gates

Gates in chip

#### installs

Chips installed within the chip

#### name

Name of chip

#### title

Title if known

# Private Methods

## AUTOLOAD($chip, @options)

Autoload by [logic gate](https://en.wikipedia.org/wiki/Logic_gate) name to provide a more readable way to specify the [logic gates](https://en.wikipedia.org/wiki/Logic_gate) on a [chip](https://en.wikipedia.org/wiki/Integrated_circuit).

       Parameter  Description
    1  $chip      Chip
    2  @options   Options

# Index

1 [andBits](#andbits) - **and** a bus made of bits.

2 [andWords](#andwords) - **and** a bus made of words to produce a single word

3 [andWordsX](#andwordsx) - **and** a bus made of words by anding the corresponding bits in each word to mak a single word.

4 [AUTOLOAD](#autoload) - Autoload by [logic gate](https://en.wikipedia.org/wiki/Logic_gate) name to provide a more readable way to specify the [logic gates](https://en.wikipedia.org/wiki/Logic_gate) on a [chip](https://en.wikipedia.org/wiki/Integrated_circuit).

5 [chooseWordUnderMask](#choosewordundermask) - Choose one of a specified number of words **w**, each of a specified width, using a point mask **m** placing the selected word in **o**.

6 [compareEq](#compareeq) - Compare two unsigned binary integers of a specified width returning **1** if they are equal else **0**.

7 [compareGt](#comparegt) - Compare two unsigned binary integers of specified width and return **1** if the first integer is more than **b** else **0**.

8 [compareLt](#comparelt) - Compare two unsigned binary integers **a**, **b** of a specified width.

9 [connectBits](#connectbits) - Create a connection list connecting a set of output bits on the one chip to a set of input bits on another chip.

10 [connectWords](#connectwords) - Create a connection list connecting a set of words on the outer chip to a set of words on the inner chip.

11 [findWord](#findword) - Choose one of a specified number of words **w**, each of a specified width, using a key **k**.

12 [gate](#gate) - A [logic gate](https://en.wikipedia.org/wiki/Logic_gate) of some sort to be added to the [chip](https://en.wikipedia.org/wiki/Integrated_circuit).

13 [inputBits](#inputbits) - Create an **input** bus made of bits.

14 [inputWords](#inputwords) - Create an **input** bus made of words.

15 [install](#install) - Install a [chip](https://en.wikipedia.org/wiki/Integrated_circuit) within another [chip](https://en.wikipedia.org/wiki/Integrated_circuit) specifying the connections between the inner and outer [chip](https://en.wikipedia.org/wiki/Integrated_circuit).

16 [integerToMonotoneMask](#integertomonotonemask) - Convert an integer **i** of specified width to a monotone mask **m**.

17 [integerToPointMask](#integertopointmask) - Convert an integer **i** of specified width to a point mask **m**.

18 [monotoneMaskToInteger](#monotonemasktointeger) - Convert a monotone mask **i** to an output number **r** representing the location in the mask of the bit set to **1**.

19 [n](#n) - Gate name from single index

20 [newChip](#newchip) - Create a new [chip](https://en.wikipedia.org/wiki/Integrated_circuit).

21 [nn](#nn) - Gate name from double index

22 [notBits](#notbits) - Create a **not** bus made of bits.

23 [notWords](#notwords) - Create a **not** bus made of words.

24 [orBits](#orbits) - **or** a bus made of bits.

25 [orWords](#orwords) - **or** a bus made of words to produce a single word.

26 [orWordsX](#orwordsx) - **or** a bus made of words by oring the corresponding bits in each word to make a single word.

27 [outputBits](#outputbits) - Create an **output** bus made of bits.

28 [outputWords](#outputwords) - Create an **output** bus made of words.

29 [pointMaskToInteger](#pointmasktointeger) - Convert a mask **i** known to have at most a single bit on - also known as a **point mask** - to an output number **a** representing the location in the mask of the bit set to **1**.

30 [setN](#setn) - Set an array of input gates to a number prior to running a simulation.

31 [setNN](#setnn) - Set an array of arrays of gates to an array of numbers prior to running a simulation.

32 [Silicon::Chip::Simulation::Results::bitsToInteger](#silicon-chip-simulation-results-bitstointeger) - Represent the state of bits in the simulation results as an unsigned binary integer.

33 [Silicon::Chip::Simulation::Results::wordsToInteger](#silicon-chip-simulation-results-wordstointeger) - Represent the state of words in the simulation results as an array of unsigned binary integer.

34 [Silicon::Chip::Simulation::Results::wordXToInteger](#silicon-chip-simulation-results-wordxtointeger) - Represent the state of words in the simulation results as an array of unsigned binary integer.

35 [simulate](#simulate) - Simulate the action of the [logic gates](https://en.wikipedia.org/wiki/Logic_gate) on a [chip](https://en.wikipedia.org/wiki/Integrated_circuit) for a given set of inputs until the output value of each [logic gate](https://en.wikipedia.org/wiki/Logic_gate) stabilizes.

# Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via **cpan**:

    sudo cpan install Silicon::Chip

# Author

[philiprbrenan@gmail.com](mailto:philiprbrenan@gmail.com)

[http://www.appaapps.com](http://www.appaapps.com)

# Copyright

Copyright (c) 2016-2023 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

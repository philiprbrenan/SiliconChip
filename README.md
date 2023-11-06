<div>
    <p><a href="https://github.com/philiprbrenan/SiliconChip"><img src="https://github.com/philiprbrenan/SiliconChip/workflows/Test/badge.svg"></a>
</div>

# Name

Silicon::Chip - Design a [silicon](https://en.wikipedia.org/wiki/Silicon) [chip](https://en.wikipedia.org/wiki/Integrated_circuit) by combining [logic gates](https://en.wikipedia.org/wiki/Logic_gate) and sub [chips](https://en.wikipedia.org/wiki/Integrated_circuit).

# Synopsis

Create a chip to compare two 4 bit big endian unsigned integers for equality:

    my $B = 4;                                              # Number of bits

    my $c = Silicon::Chip::newChip(title=>"$B Bit Equals"); # Create chip

    $c->input ("a$_")                       for 1..$B;      # First number
    $c->input ("b$_")                       for 1..$B;      # Second number

    $c->nxor  ("e$_", {1=>"a$_", 2=>"b$_"}) for 1..$B;      # Test each bit for equality
    $c->and   ("and", {map{$_=>"e$_"}           1..$B});    # And tests together to get total equality

    $c->output("out", "and");                               # Output gate

    my $s = $c->simulate({a1=>1, a2=>0, a3=>1, a4=>0,       # Input gate values
                          b1=>1, b2=>0, b3=>1, b4=>0},
                          svg=>"svg/Equals$B");             # Svg drawing of layout

    is_deeply($s->steps,         3);                        # Three steps
    is_deeply($s->values->{out}, 1);                        # Out is 1 for equals

    my $t = $c->simulate({a1=>1, a2=>1, a3=>1, a4=>0,
                          b1=>1, b2=>0, b3=>1, b4=>0});
    is_deeply($t->values->{out}, 0);                        # Out is 0 for not equals

To obtain:

<div>
    <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/Equals4.svg">
</div>

Other circuit diagrams can be seen in folder: [lib/Silicon/svg](https://github.com/philiprbrenan/SiliconChip/tree/main/lib/Silicon/svg)

# Description

Design a [silicon](https://en.wikipedia.org/wiki/Silicon) [chip](https://en.wikipedia.org/wiki/Integrated_circuit) by combining [logic gates](https://en.wikipedia.org/wiki/Logic_gate) and sub [chips](https://en.wikipedia.org/wiki/Integrated_circuit).

Version 20231103.

The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see [Index](#index).

# Construct

Construct a [Silicon](https://en.wikipedia.org/wiki/Silicon) [chip](https://en.wikipedia.org/wiki/Integrated_circuit) using standard [logic gates](https://en.wikipedia.org/wiki/Logic_gate), components and sub chips combined via buses.

## newChip (%options)

Create a new [chip](https://en.wikipedia.org/wiki/Integrated_circuit).

       Parameter  Description
    1  %options   Options

**Example:**

    if (1)                                                                          
    
     {my $c = Silicon::Chip::newChip;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      $c->one ("one");
      $c->zero("zero");
      $c->or  ("or",   [qw(one zero)]);
      $c->and ("and",  [qw(one zero)]);
      $c->output("o1", "or");
      $c->output("o2", "and");
      my $s = $c->simulate({}, svg=>q(svg/oneZero));
      is_deeply($s->steps       , 3);
      is_deeply($s->values->{o1}, 1);
      is_deeply($s->values->{o2}, 0);
     }
    

<div>
    <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/oneZero.svg">
</div>

    if (1)                                                                           # Single AND gate
    
     {my $c = Silicon::Chip::newChip;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      $c->input ("i1");
      $c->input ("i2");
      $c->and   ("and1", [qw(i1 i2)]);
      $c->output("o", "and1");
      my $s = $c->simulate({i1=>1, i2=>1});
      ok($s->steps          == 2);
      ok($s->values->{and1} == 1);
     }
    
    if (1)                                                                          # 4 bit equal 
     {my $B = 4;                                                                    # Number of bits
    
    
      my $c = Silicon::Chip::newChip(title=>"$B Bit Equals");                       # Create chip  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      $c->input ("a$_")                 for 1..$B;                                  # First number
      $c->input ("b$_")                 for 1..$B;                                  # Second number
    
      $c->nxor  ("e$_", "a$_", "b$_")   for 1..$B;                                  # Test each bit for equality
      $c->and   ("and", {map{$_=>"e$_"}     1..$B});                                # And tests together to get total equality
    
      $c->output("out", "and");                                                     # Output gate
    
      my $s = $c->simulate({a1=>1, a2=>0, a3=>1, a4=>0,                             # Input gate values
                            b1=>1, b2=>0, b3=>1, b4=>0},
                            svg=>q(svg/Equals));                                    # Svg drawing of layout
    
      is_deeply($s->steps,         3);                                              # Three steps
      is_deeply($s->values->{out}, 1);                                              # Out is 1 for equals
    
      my $t = $c->simulate({a1=>1, a2=>1, a3=>1, a4=>0,
                            b1=>1, b2=>0, b3=>1, b4=>0});
      is_deeply($t->values->{out}, 0);                                              # Out is 0 for not equals
     }
    

<div>
    <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/Equals.svg">
</div>

## gate($chip, $type, $output, $input1, $input2)

A [logic gate](https://en.wikipedia.org/wiki/Logic_gate) chosen from **and|continue|gt|input|lt|nand|nor|not|nxor|one|or|output|xor|zero**.  The gate type can be used as a method name, so **->gate("and",** can be reduced to **->and(**

       Parameter  Description
    1  $chip      Chip
    2  $type      Gate type
    3  $output    Output name
    4  $input1    Input from another gate
    5  $input2    Input from another gate

**Example:**

    if (1)                                                                           # Two AND gates driving an OR gate  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     {my $c = newChip;
      $c->input ("i11");
      $c->input ("i12");
      $c->and   ("and1", [qw(i11   i12)]);
      $c->input ("i21");
      $c->input ("i22");
      $c->and   ("and2", [qw(i21   i22 )]);
      $c->or    ("or",   [qw(and1  and2)]);
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

#### bits($chip, $name, $bits, $value, %options)

Create a bus set to a specified number.

       Parameter  Description
    1  $chip      Chip
    2  $name      Name of bus
    3  $bits      Width in bits of bus
    4  $value     Value of bus
    5  %options   Options

**Example:**

    if (1)                                                                          
     {my $N = 4;
      for my $i(0..2**$N-1)
       {my $c = Silicon::Chip::newChip;
    
        $c->bits      ("c",      $N, $i);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        $c->outputBits("o", "c", $N);
    
        my $s = $c->simulate({}, $i == 3 ? (svg=>q(svg/bits)) : ());  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        is_deeply($s->steps       , 2);
        is_deeply($s->bitsToInteger("o", $N), $i);
       }
     }
    
    

<div>
    <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/bits.svg">  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲
</div>

#### inputBits   ($chip, $name, $bits, %options)

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
    
         $i->inputBits('i',      $W);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

         $i->notBits  (qw(n i),  $W);
         $i->outputBits(qw(o n), $W);
    
      my $o = newChip(name=>"outer");
    
         $o->inputBits ('a',     $W);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

         $o->outputBits(qw(A a), $W);
    
         $o->inputBits ('b',     $W);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

         $o->outputBits(qw(B b), $W);
    
      my %i = connectBits($i, 'i', $o, 'A', $W);
      my %o = connectBits($i, 'o', $o, 'b', $W);
      $o->install($i, {%i}, {%o});
    
      my %d = setBits('a', $W, 0b10110);
      my $s = $o->simulate({%d}, svg=>"svg/not$W");
      is_deeply($s->bitsToInteger('B', $W), 0b11101001);
     }
    

#### outputBits  ($chip, $name, $input, $bits, %options)

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
         $i->inputBits('i',      $W);
         $i->notBits  (qw(n i),  $W);
    
         $i->outputBits(qw(o n), $W);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      my $o = newChip(name=>"outer");
         $o->inputBits ('a',     $W);
    
         $o->outputBits(qw(A a), $W);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

         $o->inputBits ('b',     $W);
    
         $o->outputBits(qw(B b), $W);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      my %i = connectBits($i, 'i', $o, 'A', $W);
      my %o = connectBits($i, 'o', $o, 'b', $W);
      $o->install($i, {%i}, {%o});
    
      my %d = setBits('a', $W, 0b10110);
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
    
      my %d = setWords('i', $W, $B, 0b00,
                                 0b01,
                                 0b10,
                                 0b11);
      my $s = $c->simulate({%d}, svg=>"svg/andOrWords$W");
    
      is_deeply($s->bitsToInteger('And',  $W),  0b1000);
      is_deeply($s->bitsToInteger('AndX', $B),  0b00);
    
      is_deeply($s->bitsToInteger ('Or',   $W), 0b1110);
      is_deeply($s->bitsToInteger ('OrX', $B),  0b11);
      is_deeply([$s->wordsToInteger('N',  @B)],  [3, 2, 1, 0]);
     }
    

#### notBits ($chip, $name, $input, $bits, %options)

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
         $i->inputBits('i',      $W);
    
         $i->notBits  (qw(n i),  $W);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

         $i->outputBits(qw(o n), $W);
    
      my $o = newChip(name=>"outer");
         $o->inputBits ('a',     $W);
         $o->outputBits(qw(A a), $W);
         $o->inputBits ('b',     $W);
         $o->outputBits(qw(B b), $W);
    
      my %i = connectBits($i, 'i', $o, 'A', $W);
      my %o = connectBits($i, 'o', $o, 'b', $W);
      $o->install($i, {%i}, {%o});
    
      my %d = setBits('a', $W, 0b10110);
      my $s = $o->simulate({%d}, svg=>"svg/not$W");
      is_deeply($s->bitsToInteger('B', $W), 0b11101001);
     }
    

#### andBits ($chip, $name, $input, $bits, %options)

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
    
         $c->   andBits(qw(and  i),  $W);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

         $c->    orBits(qw(or   i),  $W);
         $c->  nandBits(qw(nand i),  $W);
         $c->   norBits(qw(nor  i),  $W);
         $c->output    (qw(And  and));
         $c->output    (qw(Or   or));
         $c->output    (qw(nAnd nand));
         $c->output    (qw(nOr  nor));
    
      my %d = setBits('i', $W, 0b10110);
      my $s = $c->simulate({%d}, svg=>"svg/andOrBits$W");
    
      is_deeply($s->values->{And},  0);
      is_deeply($s->values->{Or},   1);
      is_deeply($s->values->{nAnd}, 1);
      is_deeply($s->values->{nOr},  0);
     }
    

#### nandBits($chip, $name, $input, $bits, %options)

**nand** a bus made of bits.

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
         $c->   andBits(qw(and  i),  $W);
         $c->    orBits(qw(or   i),  $W);
    
         $c->  nandBits(qw(nand i),  $W);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

         $c->   norBits(qw(nor  i),  $W);
         $c->output    (qw(And  and));
         $c->output    (qw(Or   or));
         $c->output    (qw(nAnd nand));
         $c->output    (qw(nOr  nor));
    
      my %d = setBits('i', $W, 0b10110);
      my $s = $c->simulate({%d}, svg=>"svg/andOrBits$W");
    
      is_deeply($s->values->{And},  0);
      is_deeply($s->values->{Or},   1);
      is_deeply($s->values->{nAnd}, 1);
      is_deeply($s->values->{nOr},  0);
     }
    

#### orBits  ($chip, $name, $input, $bits, %options)

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
         $c->   andBits(qw(and  i),  $W);
    
         $c->    orBits(qw(or   i),  $W);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

         $c->  nandBits(qw(nand i),  $W);
         $c->   norBits(qw(nor  i),  $W);
         $c->output    (qw(And  and));
         $c->output    (qw(Or   or));
         $c->output    (qw(nAnd nand));
         $c->output    (qw(nOr  nor));
    
      my %d = setBits('i', $W, 0b10110);
      my $s = $c->simulate({%d}, svg=>"svg/andOrBits$W");
    
      is_deeply($s->values->{And},  0);
      is_deeply($s->values->{Or},   1);
      is_deeply($s->values->{nAnd}, 1);
      is_deeply($s->values->{nOr},  0);
     }
    

#### norBits ($chip, $name, $input, $bits, %options)

**nor** a bus made of bits.

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
         $c->   andBits(qw(and  i),  $W);
         $c->    orBits(qw(or   i),  $W);
         $c->  nandBits(qw(nand i),  $W);
    
         $c->   norBits(qw(nor  i),  $W);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

         $c->output    (qw(And  and));
         $c->output    (qw(Or   or));
         $c->output    (qw(nAnd nand));
         $c->output    (qw(nOr  nor));
    
      my %d = setBits('i', $W, 0b10110);
      my $s = $c->simulate({%d}, svg=>"svg/andOrBits$W");
    
      is_deeply($s->values->{And},  0);
      is_deeply($s->values->{Or},   1);
      is_deeply($s->values->{nAnd}, 1);
      is_deeply($s->values->{nOr},  0);
     }
    

### Words

An array of arrays of bits that can be manipulated via one name.

#### inputWords  ($chip, $name, $words, $bits, %options)

Create an **input** bus made of words.

       Parameter  Description
    1  $chip      Chip
    2  $name      Name of bus
    3  $words     Width in words of bus
    4  $bits      Width in bits of each word on bus
    5  %options   Options

**Example:**

    if (1)                                                                                
     {my @b = ((my $W = 4), (my $B = 3));
    
      my $c = newChip();
    
         $c->inputWords ('i',      @b);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

         $c->outputWords(qw(o i),  @b);
    
      my %d = setWords('i', $W, $B, 0b000,
                                    0b001,
                                    0b010,
                                    0b011);
      my $s = $c->simulate({%d}, svg=>"svg/words$W");
    
      is_deeply([$s->wordsToInteger('o', @b)], [0..3]);
      is_deeply([$s->wordXToInteger('o', @b)], [10, 12, 0]);
     }
    

#### outputWords ($chip, $name, $input, $words, $bits, %options)

Create an **output** bus made of words.

       Parameter  Description
    1  $chip      Chip
    2  $name      Name of bus
    3  $input     Name of inputs
    4  $words     Width in words of bus
    5  $bits      Width in bits of each word on bus
    6  %options   Options

**Example:**

    if (1)                                                                                
     {my @b = ((my $W = 4), (my $B = 3));
    
      my $c = newChip();
         $c->inputWords ('i',      @b);
    
         $c->outputWords(qw(o i),  @b);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      my %d = setWords('i', $W, $B, 0b000,
                                    0b001,
                                    0b010,
                                    0b011);
      my $s = $c->simulate({%d}, svg=>"svg/words$W");
    
      is_deeply([$s->wordsToInteger('o', @b)], [0..3]);
      is_deeply([$s->wordXToInteger('o', @b)], [10, 12, 0]);
     }
    

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
    
      my %d = setWords('i', $W, $B, 0b00,
                                 0b01,
                                 0b10,
                                 0b11);
      my $s = $c->simulate({%d}, svg=>"svg/andOrWords$W");
    
      is_deeply($s->bitsToInteger('And',  $W),  0b1000);
      is_deeply($s->bitsToInteger('AndX', $B),  0b00);
    
      is_deeply($s->bitsToInteger ('Or',   $W), 0b1110);
      is_deeply($s->bitsToInteger ('OrX', $B),  0b11);
      is_deeply([$s->wordsToInteger('N',  @B)],  [3, 2, 1, 0]);
     }
    

#### andWords($chip, $name, $input, $words, $bits, %options)

**and** a bus made of words to produce a single word.

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
    
      my %d = setWords('i', $W, $B, 0b00,
                                 0b01,
                                 0b10,
                                 0b11);
      my $s = $c->simulate({%d}, svg=>"svg/andOrWords$W");
    
      is_deeply($s->bitsToInteger('And',  $W),  0b1000);
      is_deeply($s->bitsToInteger('AndX', $B),  0b00);
    
      is_deeply($s->bitsToInteger ('Or',   $W), 0b1110);
      is_deeply($s->bitsToInteger ('OrX', $B),  0b11);
      is_deeply([$s->wordsToInteger('N',  @B)],  [3, 2, 1, 0]);
     }
    
    if (1)                                                                                
     {my @b = ((my $W = 4), (my $B = 3));
    
      my $c = newChip();
         $c->inputWords ('i',      @b);
         $c->outputWords(qw(o i),  @b);
    
      my %d = setWords('i', $W, $B, 0b000,
                                    0b001,
                                    0b010,
                                    0b011);
      my $s = $c->simulate({%d}, svg=>"svg/words$W");
    
      is_deeply([$s->wordsToInteger('o', @b)], [0..3]);
      is_deeply([$s->wordXToInteger('o', @b)], [10, 12, 0]);
     }
    

#### andWordsX   ($chip, $name, $input, $words, $bits, %options)

**and** a bus made of words by and-ing the corresponding bits in each word to make a single word.

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
    
      my %d = setWords('i', $W, $B, 0b00,
                                 0b01,
                                 0b10,
                                 0b11);
      my $s = $c->simulate({%d}, svg=>"svg/andOrWords$W");
    
      is_deeply($s->bitsToInteger('And',  $W),  0b1000);
      is_deeply($s->bitsToInteger('AndX', $B),  0b00);
    
      is_deeply($s->bitsToInteger ('Or',   $W), 0b1110);
      is_deeply($s->bitsToInteger ('OrX', $B),  0b11);
      is_deeply([$s->wordsToInteger('N',  @B)],  [3, 2, 1, 0]);
     }
    

#### orWords ($chip, $name, $input, $words, $bits, %options)

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
    
      my %d = setWords('i', $W, $B, 0b00,
                                 0b01,
                                 0b10,
                                 0b11);
      my $s = $c->simulate({%d}, svg=>"svg/andOrWords$W");
    
      is_deeply($s->bitsToInteger('And',  $W),  0b1000);
      is_deeply($s->bitsToInteger('AndX', $B),  0b00);
    
      is_deeply($s->bitsToInteger ('Or',   $W), 0b1110);
      is_deeply($s->bitsToInteger ('OrX', $B),  0b11);
      is_deeply([$s->wordsToInteger('N',  @B)],  [3, 2, 1, 0]);
     }
    
    if (1)                                                                                
     {my @b = ((my $W = 4), (my $B = 3));
    
      my $c = newChip();
         $c->inputWords ('i',      @b);
         $c->outputWords(qw(o i),  @b);
    
      my %d = setWords('i', $W, $B, 0b000,
                                    0b001,
                                    0b010,
                                    0b011);
      my $s = $c->simulate({%d}, svg=>"svg/words$W");
    
      is_deeply([$s->wordsToInteger('o', @b)], [0..3]);
      is_deeply([$s->wordXToInteger('o', @b)], [10, 12, 0]);
     }
    

#### orWordsX($chip, $name, $input, $words, $bits, %options)

**or** a bus made of words by or-ing the corresponding bits in each word to make a single word.

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
    
      my %d = setWords('i', $W, $B, 0b00,
                                 0b01,
                                 0b10,
                                 0b11);
      my $s = $c->simulate({%d}, svg=>"svg/andOrWords$W");
    
      is_deeply($s->bitsToInteger('And',  $W),  0b1000);
      is_deeply($s->bitsToInteger('AndX', $B),  0b00);
    
      is_deeply($s->bitsToInteger ('Or',   $W), 0b1110);
      is_deeply($s->bitsToInteger ('OrX', $B),  0b11);
      is_deeply([$s->wordsToInteger('N',  @B)],  [3, 2, 1, 0]);
     }
    

## Install

Install a chip within a chip as a sub chip.

### install ($chip, $subChip, $inputs, $outputs, %options)

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

      my %d = setBits('i', 1, 1);
      my $s = $o->simulate({%d}, dumpGatesOff=>"dump/not1", svg=>"svg/not1");
    
      is_deeply($s->steps,  2);
      is_deeply($s->values, {"(not 1 n_1)"=>0, "i_1"=>1, "N_1"=>0 });
     }
    

# Visualize

Visualize the [chip](https://en.wikipedia.org/wiki/Integrated_circuit) in various ways.

## Silicon::Chip::Simulation::print($sim, %options)

Print simulation results as text.

       Parameter  Description
    1  $sim       Simulation
    2  %options   Options

**Example:**

    if (1)                                                                           
     {my $c = Silicon::Chip::newChip(title=>"And gate");
      $c->input ("i1");
      $c->input ("i2");
      $c->and   ("and1", [qw(i1 i2)]);
      $c->output("o", "and1");
      my $s = $c->simulate({i1=>1, i2=>1});
    
      is_deeply($s->print, <<END);
    i1                              :   1 input                           i1
    i2                              :   1 input                           i2
    and1                            :   1 and                             i1 i2
    o                               :   1 output                          and1
    END
    
      is_deeply ($s->printSvg, <<END);
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.0//EN" "http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd">
    <svg height="100%" viewBox="0 0 5 4" width="100%" xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
    <text fill="darkGreen" font-size="0.4" stroke-width="0.04" text-anchor="end" x="4" y="0.5">And gate</text>
    <rect fill="transparent" font-size="0.2" height="1" stroke="green" stroke-width="0.02" width="2" x="1" y="2"/>
    <text dominant-baseline="auto" fill="red" font-size="0.2" stroke-width="0.02" text-anchor="middle" x="2" y="2.41666666666667">and</text>
    <text dominant-baseline="hanging" fill="darkblue" font-size="0.2" stroke-width="0.02" text-anchor="middle" x="2" y="2.58333333333333">and1</text>
    <line font-size="0.2" stroke="black" stroke-width="0.02" x1="1" x2="1.5" y1="0.5" y2="0.5"/>
    <line font-size="0.2" stroke="purple" stroke-width="0.02" x1="1.5" x2="1.5" y1="0.5" y2="2"/>
    <circle cx="1.5" cy="0.5" fill="red" font-size="0.2" r="0.06" stroke-width="0.02"/>
    <circle cx="1.5" cy="2" fill="blue" font-size="0.2" r="0.04" stroke-width="0.02"/>
    <circle cx="1" cy="0.5" fill="red" font-size="0.2" r="0.04" stroke-width="0.02"/>
    <line font-size="0.2" stroke="black" stroke-width="0.02" x1="1" x2="2.5" y1="1.5" y2="1.5"/>
    <line font-size="0.2" stroke="purple" stroke-width="0.02" x1="2.5" x2="2.5" y1="1.5" y2="2"/>
    <circle cx="2.5" cy="1.5" fill="red" font-size="0.2" r="0.06" stroke-width="0.02"/>
    <circle cx="2.5" cy="2" fill="blue" font-size="0.2" r="0.04" stroke-width="0.02"/>
    <circle cx="1" cy="1.5" fill="red" font-size="0.2" r="0.04" stroke-width="0.02"/>
    <rect fill="transparent" font-size="0.2" height="1" stroke="green" stroke-width="0.02" width="1" x="0" y="0"/>
    <text dominant-baseline="auto" fill="red" font-size="0.2" stroke-width="0.02" text-anchor="middle" x="0.5" y="0.416666666666667">input</text>
    <text dominant-baseline="hanging" fill="darkblue" font-size="0.2" stroke-width="0.02" text-anchor="middle" x="0.5" y="0.583333333333333">i1</text>
    <line font-size="0.2" stroke="darkBlue" stroke-width="0.02" x1="0" x2="0.5" y1="0.5" y2="0.5"/>
    <line font-size="0.2" stroke="darkRed" stroke-width="0.02" x1="0.5" x2="0.5" y1="0.5" y2="1"/>
    <circle cx="0.5" cy="0.5" fill="red" font-size="0.2" r="0.06" stroke-width="0.02"/>
    <circle cx="0.5" cy="1" fill="blue" font-size="0.2" r="0.04" stroke-width="0.02"/>
    <circle cx="1" cy="0.5" fill="red" font-size="0.2" r="0.04" stroke-width="0.02"/>
    <rect fill="transparent" font-size="0.2" height="1" stroke="green" stroke-width="0.02" width="1" x="0" y="1"/>
    <text dominant-baseline="auto" fill="red" font-size="0.2" stroke-width="0.02" text-anchor="middle" x="0.5" y="1.41666666666667">input</text>
    <text dominant-baseline="hanging" fill="darkblue" font-size="0.2" stroke-width="0.02" text-anchor="middle" x="0.5" y="1.58333333333333">i2</text>
    <line font-size="0.2" stroke="darkBlue" stroke-width="0.02" x1="0" x2="0.5" y1="1.5" y2="1.5"/>
    <line font-size="0.2" stroke="darkRed" stroke-width="0.02" x1="0.5" x2="0.5" y1="1.5" y2="2"/>
    <circle cx="0.5" cy="1.5" fill="red" font-size="0.2" r="0.06" stroke-width="0.02"/>
    <circle cx="0.5" cy="2" fill="blue" font-size="0.2" r="0.04" stroke-width="0.02"/>
    <circle cx="1" cy="1.5" fill="red" font-size="0.2" r="0.04" stroke-width="0.02"/>
    <rect fill="transparent" font-size="0.2" height="1" stroke="green" stroke-width="0.02" width="1" x="3" y="2"/>
    <text dominant-baseline="auto" fill="red" font-size="0.2" stroke-width="0.02" text-anchor="middle" x="3.5" y="2.41666666666667">output</text>
    <text dominant-baseline="hanging" fill="darkblue" font-size="0.2" stroke-width="0.02" text-anchor="middle" x="3.5" y="2.58333333333333">o</text>
    <line font-size="0.2" stroke="black" stroke-width="0.02" x1="3" x2="3.5" y1="2.5" y2="2.5"/>
    <line font-size="0.2" stroke="darkRed" stroke-width="0.02" x1="3.5" x2="3.5" y1="2.5" y2="3"/>
    <circle cx="3.5" cy="2.5" fill="red" font-size="0.2" r="0.06" stroke-width="0.02"/>
    <circle cx="3.5" cy="3" fill="blue" font-size="0.2" r="0.04" stroke-width="0.02"/>
    <circle cx="3" cy="2.5" fill="red" font-size="0.2" r="0.04" stroke-width="0.02"/>
    </svg>
    END
     }
    

## Silicon::Chip::Simulation::printSvg ($sim, %options)

Print simulation results as svg.

       Parameter  Description
    1  $sim       Simulation
    2  %options   Options

**Example:**

    if (1)                                                                           
     {my $c = Silicon::Chip::newChip(title=>"And gate");
      $c->input ("i1");
      $c->input ("i2");
      $c->and   ("and1", [qw(i1 i2)]);
      $c->output("o", "and1");
      my $s = $c->simulate({i1=>1, i2=>1});
    
      is_deeply($s->print, <<END);
    i1                              :   1 input                           i1
    i2                              :   1 input                           i2
    and1                            :   1 and                             i1 i2
    o                               :   1 output                          and1
    END
    
      is_deeply ($s->printSvg, <<END);
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.0//EN" "http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd">
    <svg height="100%" viewBox="0 0 5 4" width="100%" xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
    <text fill="darkGreen" font-size="0.4" stroke-width="0.04" text-anchor="end" x="4" y="0.5">And gate</text>
    <rect fill="transparent" font-size="0.2" height="1" stroke="green" stroke-width="0.02" width="2" x="1" y="2"/>
    <text dominant-baseline="auto" fill="red" font-size="0.2" stroke-width="0.02" text-anchor="middle" x="2" y="2.41666666666667">and</text>
    <text dominant-baseline="hanging" fill="darkblue" font-size="0.2" stroke-width="0.02" text-anchor="middle" x="2" y="2.58333333333333">and1</text>
    <line font-size="0.2" stroke="black" stroke-width="0.02" x1="1" x2="1.5" y1="0.5" y2="0.5"/>
    <line font-size="0.2" stroke="purple" stroke-width="0.02" x1="1.5" x2="1.5" y1="0.5" y2="2"/>
    <circle cx="1.5" cy="0.5" fill="red" font-size="0.2" r="0.06" stroke-width="0.02"/>
    <circle cx="1.5" cy="2" fill="blue" font-size="0.2" r="0.04" stroke-width="0.02"/>
    <circle cx="1" cy="0.5" fill="red" font-size="0.2" r="0.04" stroke-width="0.02"/>
    <line font-size="0.2" stroke="black" stroke-width="0.02" x1="1" x2="2.5" y1="1.5" y2="1.5"/>
    <line font-size="0.2" stroke="purple" stroke-width="0.02" x1="2.5" x2="2.5" y1="1.5" y2="2"/>
    <circle cx="2.5" cy="1.5" fill="red" font-size="0.2" r="0.06" stroke-width="0.02"/>
    <circle cx="2.5" cy="2" fill="blue" font-size="0.2" r="0.04" stroke-width="0.02"/>
    <circle cx="1" cy="1.5" fill="red" font-size="0.2" r="0.04" stroke-width="0.02"/>
    <rect fill="transparent" font-size="0.2" height="1" stroke="green" stroke-width="0.02" width="1" x="0" y="0"/>
    <text dominant-baseline="auto" fill="red" font-size="0.2" stroke-width="0.02" text-anchor="middle" x="0.5" y="0.416666666666667">input</text>
    <text dominant-baseline="hanging" fill="darkblue" font-size="0.2" stroke-width="0.02" text-anchor="middle" x="0.5" y="0.583333333333333">i1</text>
    <line font-size="0.2" stroke="darkBlue" stroke-width="0.02" x1="0" x2="0.5" y1="0.5" y2="0.5"/>
    <line font-size="0.2" stroke="darkRed" stroke-width="0.02" x1="0.5" x2="0.5" y1="0.5" y2="1"/>
    <circle cx="0.5" cy="0.5" fill="red" font-size="0.2" r="0.06" stroke-width="0.02"/>
    <circle cx="0.5" cy="1" fill="blue" font-size="0.2" r="0.04" stroke-width="0.02"/>
    <circle cx="1" cy="0.5" fill="red" font-size="0.2" r="0.04" stroke-width="0.02"/>
    <rect fill="transparent" font-size="0.2" height="1" stroke="green" stroke-width="0.02" width="1" x="0" y="1"/>
    <text dominant-baseline="auto" fill="red" font-size="0.2" stroke-width="0.02" text-anchor="middle" x="0.5" y="1.41666666666667">input</text>
    <text dominant-baseline="hanging" fill="darkblue" font-size="0.2" stroke-width="0.02" text-anchor="middle" x="0.5" y="1.58333333333333">i2</text>
    <line font-size="0.2" stroke="darkBlue" stroke-width="0.02" x1="0" x2="0.5" y1="1.5" y2="1.5"/>
    <line font-size="0.2" stroke="darkRed" stroke-width="0.02" x1="0.5" x2="0.5" y1="1.5" y2="2"/>
    <circle cx="0.5" cy="1.5" fill="red" font-size="0.2" r="0.06" stroke-width="0.02"/>
    <circle cx="0.5" cy="2" fill="blue" font-size="0.2" r="0.04" stroke-width="0.02"/>
    <circle cx="1" cy="1.5" fill="red" font-size="0.2" r="0.04" stroke-width="0.02"/>
    <rect fill="transparent" font-size="0.2" height="1" stroke="green" stroke-width="0.02" width="1" x="3" y="2"/>
    <text dominant-baseline="auto" fill="red" font-size="0.2" stroke-width="0.02" text-anchor="middle" x="3.5" y="2.41666666666667">output</text>
    <text dominant-baseline="hanging" fill="darkblue" font-size="0.2" stroke-width="0.02" text-anchor="middle" x="3.5" y="2.58333333333333">o</text>
    <line font-size="0.2" stroke="black" stroke-width="0.02" x1="3" x2="3.5" y1="2.5" y2="2.5"/>
    <line font-size="0.2" stroke="darkRed" stroke-width="0.02" x1="3.5" x2="3.5" y1="2.5" y2="3"/>
    <circle cx="3.5" cy="2.5" fill="red" font-size="0.2" r="0.06" stroke-width="0.02"/>
    <circle cx="3.5" cy="3" fill="blue" font-size="0.2" r="0.04" stroke-width="0.02"/>
    <circle cx="3" cy="2.5" fill="red" font-size="0.2" r="0.04" stroke-width="0.02"/>
    </svg>
    END
     }
    

# Basic Circuits

Some well known basic circuits.

## n   ($c, $i)

Gate name from single index.

       Parameter  Description
    1  $c         Gate name
    2  $i         Bit number

**Example:**

    if (1)                                                                           
    
     {is_deeply( n(a,1),   "a_1");  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply(nn(a,1,2), "a_1_2");
     }
    

## nn  ($c, $i, $j)

Gate name from double index.

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

### compareEq   ($chip, $output, $a, $b, $bits, %options)

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
     {my $B = 2;
    
      my $c = Silicon::Chip::newChip(name=>"eq", title=>"$B Bit Compare Equal");
    
      $c->inputBits($_, $B) for qw(a b);                                            # First and second numbers
    
      $c->compareEq(qw(o a b), $B);                                                 # Compare equals  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      $c->output   (qw(out o));                                                     # Comparison result
    
      for   my $i(0..2**$B-1)                                                       # Each possible number
       {for my $j(0..2**$B-1)                                                       # Each possible number
         {my %a = setBits('a', $B, $i);                                             # Number a
          my %b = setBits('b', $B, $j);                                             # Number b
    
          my $s = $c->simulate({%a, %b}, $i==1&&$j==1?(svg=>"svg/CompareEq$B"):()); # Svg drawing of layout
    
          is_deeply($s->values->{out}, $i == $j ? 1 : 0);                           # Equal
          is_deeply($s->steps, 3);                                                  # Number of steps to stability
         }
       }
     }
    

### compareGt   ($chip, $output, $a, $b, $bits, %options)

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
     {my $B = 3;
      my $c = Silicon::Chip::newChip(name=>"gt", title=>"$B Bit Compare more than");
    
      $c->inputBits($_, $B) for qw(a b);                                            # First and second numbers
    
      $c->compareGt(qw(o a b), $B);                                                 # Compare more than  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      $c->output   (qw(out o));                                                     # Comparison result
    
      for   my $i(0..2**$B-1)                                                       # Each possible number
       {for my $j(0..2**$B-1)                                                       # Each possible number
         {my %a = setBits('a', $B, $i);                                             # Number a
          my %b = setBits('b', $B, $j);                                             # Number b
    
          my $s = $c->simulate({%a, %b}, $i==2&&$j==1?(svg=>"svg/CompareGt$B"):()); # Svg drawing of layout
          is_deeply($s->values->{out}, $i > $j ? 1 : 0);                            # More than
          is_deeply($s->steps, 4);                                                  # Number of steps to stability
         }
       }
     }
    

### compareLt   ($chip, $output, $a, $b, $bits, %options)

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
     {my $B = 3;
      my $c = Silicon::Chip::newChip(name=>"lt", title=>"$B Bit Compare Less Than");
    
      $c->inputBits($_, $B) for qw(a b);                                            # First and second numbers
    
      $c->compareLt(qw(o a b), $B);                                                 # Compare less than  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      $c->output   (qw(out o));                                                     # Comparison result
    
      for   my $i(0..2**$B-1)                                                       # Each possible number
       {for my $j(0..2**$B-1)                                                       # Each possible number
         {my %a = setBits('a', $B, $i);                                             # Number a
          my %b = setBits('b', $B, $j);                                             # Number b
    
          my $s = $c->simulate({%a, %b}, $i==1&&$j==2?(svg=>"svg/CompareLt$B"):()); # Svg drawing of layout
          is_deeply($s->values->{out}, $i < $j ? 1 : 0);                            # More than
          is_deeply($s->steps, 4);                                                  # Number of steps to stability
         }
       }
     }
    

### chooseFromTwoWords  ($chip, $output, $a, $b, $choose, $bits, %options)

Choose one of two words based on a bit.  The first word is chosen if the bit is **0** otherwise the second word is chose

       Parameter  Description
    1  $chip      Chip
    2  $output    Name of component also the chosen word
    3  $a         The first word
    4  $b         The second word
    5  $choose    The choosing bit
    6  $bits      The width of the words in bits
    7  %options   Options

**Example:**

    if (1)                                                                          
     {my $B = 4;
    
      my $c = newChip();
         $c->inputBits('a', $B);                                                    # First word
         $c->inputBits('b', $B);                                                    # Second word
         $c->input    ('c');                                                        # Chooser
    
         $c->chooseFromTwoWords(qw(o a b c), $B);                                   # Generate gates  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

         $c->outputBits('out', 'o',          $B);                                   # Result
    
      my %a = setBits('a', $B, 0b0011);
      my %b = setBits('b', $B, 0b1100);
    
    
      my $s = $c->simulate({%a, %b, c=>1}, svg=>"svg/chooseFromTwoWords$B");  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply($s->steps,               4);
      is_deeply($s->bitsToInteger('out', $B), 0b1100);
    
      my $t = $c->simulate({%a, %b, c=>0});
      is_deeply($t->steps,               4);
      is_deeply($t->bitsToInteger('out', $B), 0b0011);
     }
    

### enableWord  ($chip, $output, $a, $enable, $bits, %options)

Output a word or zeros depending on a choice bit.  The first word is chosen if the choice bit is **1** otherwise all zeroes are choosen.

       Parameter  Description
    1  $chip      Chip
    2  $output    Name of component also the chosen word
    3  $a         The first word
    4  $enable    The second word
    5  $bits      The choosing bit
    6  %options   The width of the words in bits

**Example:**

    if (1)                                                                          
     {my $B = 4;
    
      my $c = newChip();
         $c->inputBits ('a',       $B);                                             # Word
         $c->input     ('c');                                                       # Choice bit
    
         $c->enableWord(qw(o a c), $B);                                             # Generate gates  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

         $c->outputBits(qw(out o), $B);                                             # Result
    
      my %a = setBits('a', $B, 0b0011);
    
    
      my $s = $c->simulate({%a, c=>1}, svg=>"svg/enableWord");  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply($s->steps,               4);
      is_deeply($s->bitsToInteger('out', $B), 0b0011);
    
      my $t = $c->simulate({%a, c=>0});
      is_deeply($t->steps,               4);
      is_deeply($t->bitsToInteger('out', $B), 0b0000);
     }
    

## Masks

Point masks and monotone masks. A point mask has a single **1** in a sea of **0**s as in **00100**.  A monotone mask has zero or more **0**s followed by all **1**s as in: **00111**.

### pointMaskToInteger  ($chip, $output, $input, $bits, %options)

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
       {my %i = setBits('i', $N, $i ? 1<<($i-1) : 0);                                  # Point in each position with zero representing no position
        my $s = $c->simulate(\%i, $i == 5 ? (svg=>"svg/point$B") : ());
        is_deeply($s->steps, 2);
        my %o = $s->values->%*;                                                     # Output bits
        my $n = eval join '', '0b', map {$o{n(o,$_)}} reverse 1..$B;                # Output bits as number
        is_deeply($n, $i);
       }
     }
    

### integerToPointMask  ($chip, $output, $input, $bits, %options)

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
       {my %i = setBits('i', $B, $i);
        my $s = $c->simulate(\%i, $i == 5 ? (svg=>"svg/integerToMontoneMask$B"):());
        is_deeply($s->steps, 3);
    
        my $r = $s->bitsToInteger('o', $N);                                         # Mask values
        is_deeply($r, $i ? 1<<($i-1) : 0);                                          # Expected mask
       }
     }
    

### monotoneMaskToInteger   ($chip, $output, $input, $bits, %options)

Convert a monotone mask **i** to an output number **r** representing the location in the mask of the bit set to **1**. If no such bit exists in the point then output in **r** is **0**.

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
    
      my $c = Silicon::Chip::newChip(title=>"$N bits monotone mask to $B bit integer");
         $c->inputBits            ('i',     $N);
    
         $c->monotoneMaskToInteger(qw(m i), $B);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

         $c->outputBits           (qw(o m), $B);
    
      for my $i(0..$N-1)                                                            # Each monotone mask
       {my %i = setBits('i', $N, $i > 0 ? 1<<$i-1 : 0);
    
        my $s = $c->simulate(\%i, $i == 5 ? (svg=>"svg/monotoneMaskToInteger$B") : ());  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
        is_deeply($s->steps, 4);
        is_deeply($s->bitsToInteger('m', $B), $i);
       }
     }
    

### monotoneMaskToPointMask ($chip, $output, $input, $bits, %options)

Convert a monotone mask **i** to a point mask **o** representing the location in the mask of the first bit set to **1**. If the monotone mask is all **0**s then point mask is too.

       Parameter  Description
    1  $chip      Chip
    2  $output    Output name
    3  $input     Input mask
    4  $bits      Number of bits in mask
    5  %options   Options

**Example:**

    if (1)                                                                          
     {my $B = 4;
    
      my $c = newChip();
         $c->inputBits('m', $B);                                                    # Monotone mask
    
         $c->monotoneMaskToPointMask(qw(o m), $B);                                  # Generate gates  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

         $c->outputBits('out', 'o',           $B);                                  # Point mask
    
      for my $i(0..$B)
       {my %m = setBits('m', $B, eval '0b'.(1 x $i).('0' x ($B-$i)));
        my $s = $c->simulate({%m});
        is_deeply($s->steps,                    2);
        is_deeply($s->bitsToInteger('out', $B), $i ? (1<<($B-1)) / (1<<($i-1)) : 0);
       }
     }
    

### integerToMonotoneMask   ($chip, $output, $input, $bits, %options)

Convert an integer **i** of specified width to a monotone mask **m**. If the input integer is **0** then the mask is all zeroes.  Otherwise the mask has **i-1** leading zeroes followed by all ones thereafter.

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
    
      my $c = Silicon::Chip::newChip(title=>"$B bit integer to $N bit monotone mask");
         $c->inputBits            ('i', $B);                                        # Input gates
    
         $c->integerToMonotoneMask(qw(m i), $B);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

         $c->outputBits           (qw(o m), $N);                                    # Output gates
    
      for my $i(0..$N)                                                              # Each position of mask
       {my %i = setBits('i', $B, $i);                                               # The number to convert
        my $s = $c->simulate(\%i, $i == 2 ? (svg=>"svg/integerToMontoneMask$B"):());
        is_deeply($s->steps, 4);
        is_deeply($s->bitsToInteger('o', $N),                                       # Expected mask
          $i > 0 ? ((1<<$N)-1)>>($i-1)<<($i-1) : 0);
       }
     }
    

### chooseWordUnderMask ($chip, $output, $input, $mask, $words, $bits, %options)

Choose one of a specified number of words **w**, each of a specified width, using a point mask **m** placing the selected word in **o**.  If no word is selected then **o** will be zero.

       Parameter  Description
    1  $chip      Chip
    2  $output    Output
    3  $input     Inputs
    4  $mask      Mask
    5  $words     Number of words
    6  $bits      Number of bits per word
    7  %options   Options

**Example:**

    if (1)                                                                            
     {my $B = 3; my $W = 4;
    
      my $c = Silicon::Chip::newChip(title=>"Choose one of $W words of $B bits");
         $c->inputWords         ('w',       $W, $B);
         $c->inputBits          ('m',       $W);
    
         $c->chooseWordUnderMask(qw(W w m), $W, $B);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

         $c->outputBits         (qw(o W),       $B);
    
      my %i = setWords('w', $W, $B, 0b000, 0b001, 0b010, 0b0100);
      my %m = setBits ('m', $W, 1<<2);                                              # Choose the third word
    
      my $s = $c->simulate({%i, %m}, svg=>"svg/choose_${W}_$B");
    
      is_deeply($s->steps, 3);
      is_deeply($s->bitsToInteger('o', $B), 0b010);
     }
    

### findWord($chip, $output, $key, $words, $bits, %options)

Choose one of a specified number of words **w**, each of a specified width, using a key **k**.  Return a point mask **o** indicating the locations of the key if found or or a mask equal to all zeroes if the key is not present.

       Parameter  Description
    1  $chip      Chip
    2  $output    Found point mask
    3  $key       Key
    4  $words     Words to search
    5  $bits      Number of bits per key
    6  %options   Options

**Example:**

    if (1)                                                                          
     {my $B = 3; my $W = 2**$B-1;
    
      my $c = Silicon::Chip::newChip(title=>"Search $W words of $B bits");
         $c->inputBits ('k',       $B);                                             # Search key
         $c->inputWords('w',       2**$B-1, $B);                                    # Words to search
    
         $c->findWord  (qw(m k w), $B);                                             # Find the word  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

         $c->outputBits(qw(M m),   $W);                                             # Output mask
    
      my %w = setWords('w', $W, $B, reverse 1..$W);
    
      for my $k(0..$W)                                                              # Each possible key
       {my %k = setBits('k', $B, $k);
        my $s = $c->simulate({%k, %w}, svg=>"svg/findWord_${W}_$B");
        is_deeply($s->steps, 3);
        is_deeply($s->bitsToInteger('M', $W),$k ? 2**($W-$k) : 0);
       }
     }
    

# Simulate

Simulate the behavior of the [chip](https://en.wikipedia.org/wiki/Integrated_circuit) given a set of values on its input gates.

## setBits ($name, $bits, $value)

Set an array of input gates to a number prior to running a simulation.

       Parameter  Description
    1  $name      Name of input gates
    2  $bits      Number of bits in each array element
    3  $value     Number to set to

**Example:**

    if (1)                                                                           # Compare two 4 bit unsigned integers 'a' > 'b' - the pins used to input 'a' must be alphabetically less than those used for 'b'
     {my $B = 4;                                                                    # Number of bits
      my $c = Silicon::Chip::newChip(title=>"$B Bit Compare");
    
      $c->input(n(a,$_))                   for 1..$B;                               # First number
      $c->input(n(b,$_))                   for 1..$B;                               # Second number
      $c->nxor (n(e,$_), n(a,$_), n(b,$_)) for 1..$B-1;                             # Test each bit for equality
      $c->gt   (n(g,$_), n(a,$_), n(b,$_)) for 1..$B;                               # Test each bit pair for greater
    
      for my $b(2..$B)
       {$c->and(n(c,$b), [(map {n(e, $_)} 1..$b-1), n(g,$b)]);                      # Greater on one bit and all preceding bits are equal
       }
      $c->or    ("or",  [n(g,1), (map {n(c, $_)} 2..$B)]);                          # Any set bit indicates that 'a' is more than 'b'
      $c->output("out", "or");                                                      # Output 1 if a > b else 0
    
    
      my %a = setBits('a', $B, 0);                                                  # Number a  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      my %b = setBits('b', $B, 0);                                                  # Number b  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      my $s = $c->simulate({%a, %b, n(a,2)=>1, n(b,2)=>1});                         # Two equal numbers
      is_deeply($s->values->{out}, 0);
    
      my $t = $c->simulate({%a, %b, n(a,2)=>1}, svg=>q(svg/Compare$B));             # Svg drawing of layout
      is_deeply($t->values->{out}, 1);
     }
    

<div>
    <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/Compare$B.svg">
</div>

    if (1)                                                                            
     {my $B = 3; my $W = 4;
    
      my $c = Silicon::Chip::newChip(title=>"Choose one of $W words of $B bits");
         $c->inputWords         ('w',       $W, $B);
         $c->inputBits          ('m',       $W);
         $c->chooseWordUnderMask(qw(W w m), $W, $B);
         $c->outputBits         (qw(o W),       $B);
    
      my %i = setWords('w', $W, $B, 0b000, 0b001, 0b010, 0b0100);
    
      my %m = setBits ('m', $W, 1<<2);                                              # Choose the third word  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      my $s = $c->simulate({%i, %m}, svg=>"svg/choose_${W}_$B");
    
      is_deeply($s->steps, 3);
      is_deeply($s->bitsToInteger('o', $B), 0b010);
     }
    

## setWords($name, $words, $bits, @values)

Set an array of arrays of gates to an array of numbers prior to running a simulation.

       Parameter  Description
    1  $name      Name of input gates
    2  $words     Number of arrays
    3  $bits      Number of bits in each array element
    4  @values    Numbers to set to

**Example:**

    if (1)                                                                            
     {my $B = 3; my $W = 4;
    
      my $c = Silicon::Chip::newChip(title=>"Choose one of $W words of $B bits");
         $c->inputWords         ('w',       $W, $B);
         $c->inputBits          ('m',       $W);
         $c->chooseWordUnderMask(qw(W w m), $W, $B);
         $c->outputBits         (qw(o W),       $B);
    
    
      my %i = setWords('w', $W, $B, 0b000, 0b001, 0b010, 0b0100);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my %m = setBits ('m', $W, 1<<2);                                              # Choose the third word
    
      my $s = $c->simulate({%i, %m}, svg=>"svg/choose_${W}_$B");
    
      is_deeply($s->steps, 3);
      is_deeply($s->bitsToInteger('o', $B), 0b010);
     }
    

## connectBits ($oc, $o, $ic, $i, $bits, %options)

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
      my %d = setBits('i', 1, 1);
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
      my %d = setWords('i', 1, 1, 1);
      my $s = $o->simulate({%d}, dumpGatesOff=>"dump/not1", svg=>"svg/not1");
    
      is_deeply($s->steps,  2);
      is_deeply($s->values, { "(not 1 n_1_1)" => 0, "i_1_1" => 1, "N_1_1" => 0 });
     }
    

## Silicon::Chip::Simulation::bitsToInteger($simulation, $output, $bits, %options)

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
         $i->inputBits('i',      $W);
         $i->notBits  (qw(n i),  $W);
         $i->outputBits(qw(o n), $W);
    
      my $o = newChip(name=>"outer");
         $o->inputBits ('a',     $W);
         $o->outputBits(qw(A a), $W);
         $o->inputBits ('b',     $W);
         $o->outputBits(qw(B b), $W);
    
      my %i = connectBits($i, 'i', $o, 'A', $W);
      my %o = connectBits($i, 'o', $o, 'b', $W);
      $o->install($i, {%i}, {%o});
    
      my %d = setBits('a', $W, 0b10110);
      my $s = $o->simulate({%d}, svg=>"svg/not$W");
      is_deeply($s->bitsToInteger('B', $W), 0b11101001);
     }
    

## Silicon::Chip::Simulation::wordsToInteger   ($simulation, $output, $words, $bits, %options)

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
    
      my %d = setWords('i', $W, $B, 0b000,
                                    0b001,
                                    0b010,
                                    0b011);
      my $s = $c->simulate({%d}, svg=>"svg/words$W");
    
      is_deeply([$s->wordsToInteger('o', @b)], [0..3]);
      is_deeply([$s->wordXToInteger('o', @b)], [10, 12, 0]);
     }
    

## Silicon::Chip::Simulation::wordXToInteger   ($simulation, $output, $words, $bits, %options)

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
    
      my %d = setWords('i', $W, $B, 0b000,
                                    0b001,
                                    0b010,
                                    0b011);
      my $s = $c->simulate({%d}, svg=>"svg/words$W");
    
      is_deeply([$s->wordsToInteger('o', @b)], [0..3]);
      is_deeply([$s->wordXToInteger('o', @b)], [10, 12, 0]);
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

2 [andWords](#andwords) - **and** a bus made of words to produce a single word.

3 [andWordsX](#andwordsx) - **and** a bus made of words by and-ing the corresponding bits in each word to make a single word.

4 [AUTOLOAD](#autoload) - Autoload by [logic gate](https://en.wikipedia.org/wiki/Logic_gate) name to provide a more readable way to specify the [logic gates](https://en.wikipedia.org/wiki/Logic_gate) on a [chip](https://en.wikipedia.org/wiki/Integrated_circuit).

5 [bits](#bits) - Create a bus set to a specified number.

6 [chooseFromTwoWords](#choosefromtwowords) - Choose one of two words based on a bit.

7 [chooseWordUnderMask](#choosewordundermask) - Choose one of a specified number of words **w**, each of a specified width, using a point mask **m** placing the selected word in **o**.

8 [compareEq](#compareeq) - Compare two unsigned binary integers of a specified width returning **1** if they are equal else **0**.

9 [compareGt](#comparegt) - Compare two unsigned binary integers of specified width and return **1** if the first integer is more than **b** else **0**.

10 [compareLt](#comparelt) - Compare two unsigned binary integers **a**, **b** of a specified width.

11 [connectBits](#connectbits) - Create a connection list connecting a set of output bits on the one chip to a set of input bits on another chip.

12 [connectWords](#connectwords) - Create a connection list connecting a set of words on the outer chip to a set of words on the inner chip.

13 [enableWord](#enableword) - Output a word or zeros depending on a choice bit.

14 [findWord](#findword) - Choose one of a specified number of words **w**, each of a specified width, using a key **k**.

15 [gate](#gate) - A [logic gate](https://en.wikipedia.org/wiki/Logic_gate) chosen from **and|continue|gt|input|lt|nand|nor|not|nxor|one|or|output|xor|zero**.

16 [inputBits](#inputbits) - Create an **input** bus made of bits.

17 [inputWords](#inputwords) - Create an **input** bus made of words.

18 [install](#install) - Install a [chip](https://en.wikipedia.org/wiki/Integrated_circuit) within another [chip](https://en.wikipedia.org/wiki/Integrated_circuit) specifying the connections between the inner and outer [chip](https://en.wikipedia.org/wiki/Integrated_circuit).

19 [integerToMonotoneMask](#integertomonotonemask) - Convert an integer **i** of specified width to a monotone mask **m**.

20 [integerToPointMask](#integertopointmask) - Convert an integer **i** of specified width to a point mask **m**.

21 [monotoneMaskToInteger](#monotonemasktointeger) - Convert a monotone mask **i** to an output number **r** representing the location in the mask of the bit set to **1**.

22 [monotoneMaskToPointMask](#monotonemasktopointmask) - Convert a monotone mask **i** to a point mask **o** representing the location in the mask of the first bit set to **1**.

23 [n](#n) - Gate name from single index.

24 [nandBits](#nandbits) - **nand** a bus made of bits.

25 [newChip](#newchip) - Create a new [chip](https://en.wikipedia.org/wiki/Integrated_circuit).

26 [nn](#nn) - Gate name from double index.

27 [norBits](#norbits) - **nor** a bus made of bits.

28 [notBits](#notbits) - Create a **not** bus made of bits.

29 [notWords](#notwords) - Create a **not** bus made of words.

30 [orBits](#orbits) - **or** a bus made of bits.

31 [orWords](#orwords) - **or** a bus made of words to produce a single word.

32 [orWordsX](#orwordsx) - **or** a bus made of words by or-ing the corresponding bits in each word to make a single word.

33 [outputBits](#outputbits) - Create an **output** bus made of bits.

34 [outputWords](#outputwords) - Create an **output** bus made of words.

35 [pointMaskToInteger](#pointmasktointeger) - Convert a mask **i** known to have at most a single bit on - also known as a **point mask** - to an output number **a** representing the location in the mask of the bit set to **1**.

36 [setBits](#setbits) - Set an array of input gates to a number prior to running a simulation.

37 [setWords](#setwords) - Set an array of arrays of gates to an array of numbers prior to running a simulation.

38 [Silicon::Chip::Simulation::bitsToInteger](#silicon-chip-simulation-bitstointeger) - Represent the state of bits in the simulation results as an unsigned binary integer.

39 [Silicon::Chip::Simulation::print](#silicon-chip-simulation-print) - Print simulation results as text.

40 [Silicon::Chip::Simulation::printSvg](#silicon-chip-simulation-printsvg) - Print simulation results as svg.

41 [Silicon::Chip::Simulation::wordsToInteger](#silicon-chip-simulation-wordstointeger) - Represent the state of words in the simulation results as an array of unsigned binary integer.

42 [Silicon::Chip::Simulation::wordXToInteger](#silicon-chip-simulation-wordxtointeger) - Represent the state of words in the simulation results as an array of unsigned binary integer.

43 [simulate](#simulate) - Simulate the action of the [logic gates](https://en.wikipedia.org/wiki/Logic_gate) on a [chip](https://en.wikipedia.org/wiki/Integrated_circuit) for a given set of inputs until the output value of each [logic gate](https://en.wikipedia.org/wiki/Logic_gate) stabilizes.

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

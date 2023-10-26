# Name

Silicon::Chip - Design a [Silicon](https://en.wikipedia.org/wiki/Silicon) chip by combining gates and [sub](https://perldoc.perl.org/perlsub.html) chips.

# Synopsis

# Description

Design a [Silicon](https://en.wikipedia.org/wiki/Silicon) chip by combining gates and [sub](https://perldoc.perl.org/perlsub.html) chips.

Version 20231025.

The following sections describe the methods in each functional area of this [module](https://en.wikipedia.org/wiki/Modular_programming).  For an alphabetic listing of all methods by name see [Index](#index).

# Construct

Construct a representation of a digital circuit using standard gates.

## newChip(%options)

Create a new chip

       Parameter  Description
    1  %options   Options

**Example:**

    if (1)                                                                           Single AND gate

     {my $c = newChip;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      $c->gate("input",  "i1");
      $c->gate("input",  "i2");
      $c->gate("and",    "and1", {1=>q(i1), 2=>q(i2)});
      $c->gate("output", "o", "and1");
      my $s = $c->simulate({i1=>1, i2=>1});
      ok($s->steps          == 2);
      ok($s->values->{and1} == 1);
     }

    if (1)                                                                           Single AND gate

     {my $c = newChip;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      $c->input ("i1");
      $c->input ("i2");
      $c->and   ("and1", {1=>q(i1), 2=>q(i2)});
      $c->output("o", "and1");
      my $s = $c->simulate({i1=>1, i2=>1});
      ok($s->steps          == 2);
      ok($s->values->{and1} == 1);
     }

## gate($chip, $type, $output, $inputs)

A gate of some [sort](https://en.wikipedia.org/wiki/Sorting) to be added to the chip.

       Parameter  Description
    1  $chip      Chip
    2  $type      Gate type
    3  $output    Output name
    4  $inputs    Input names to output from another gate

**Example:**

    if (1)                                                                           Two AND gates driving an OR gate a [tree](https://en.wikipedia.org/wiki/Tree_(data_structure))  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     {my $c = newChip;

      $c->gate("input",  "i11");  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


      $c->gate("input",  "i12");  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


      $c->gate("and",    "and1", {1=>q(i11),  2=>q(i12)});  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


      $c->gate("input",  "i21");  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


      $c->gate("input",  "i22");  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


      $c->gate("and",    "and2", {1=>q(i21),  2=>q(i22)});  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


      $c->gate("or",     "or",   {1=>q(and1), 2=>q(and2)});  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


      $c->gate("output", "o", "or");  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

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

## install($chip, $subChip, $inputs, $outputs, %options)

Install a chip within another chip specifying the connections between the inner and outer chip.  The same chip can be installed multiple times as each chip description is read only.

       Parameter  Description
    1  $chip      Outer chip
    2  $subChip   Inner chip
    3  $inputs    Inputs of inner chip to to outputs of outer chip
    4  $outputs   Outputs of inner chip to inputs of outer chip
    5  %options   Options

**Example:**

    if (1)                                                                           Install one inside another chip, specifically one chip that performs NOT is installed three times sequentially to flip a value
     {my $i = newChip(name=>"inner");
         $i->gate("input", "Ii");
         $i->gate("not",   "In", "Ii");
         $i->gate("output","Io", "In");

      my $o = newChip(name=>"outer");
         $o->gate("input",    "Oi1");
         $o->gate("output",   "Oo1", "Oi1");
         $o->gate("input",    "Oi2");
         $o->gate("output",    "Oo", "Oi2");


      $o->install($i, {Ii=>"Oo1"}, {Io=>"Oi2"});  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $s = $o->simulate({Oi1=>1}, dumpGatesOff=>"dump/not1", svg=>"svg/not1");
      is_deeply($s, {steps  => 2, values => { "(inner 1 In)" => 0, "Oi1" => 1, "Oo" => 0 }});
     }

# Visualize

Visualize the chip in various ways.

# Simulate

Simulate the behavior of the chip.

## simulate($chip, $inputs, %options)

Simulate the set of gates until nothing changes.  This should be possible as feedback loops are banned.

       Parameter  Description
    1  $chip      Chip
    2  $inputs    Hash of input names to values
    3  %options   Options

**Example:**

    if (1)
     {my $i = newChip(name=>"inner");
         $i->gate("input", "Ii");
         $i->gate("not",   "In", "Ii");
         $i->gate("output","Io", "In");

      my $o = newChip(name=>"outer");
         $o->gate("input",    "Oi1");
         $o->gate("output",   "Oo1", "Oi1");
         $o->gate("input",    "Oi2");
         $o->gate("output",   "Oo2", "Oi2");
         $o->gate("input",    "Oi3");
         $o->gate("output",   "Oo3", "Oi3");
         $o->gate("input",    "Oi4");
         $o->gate("output",    "Oo", "Oi4");

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

#### gates

Gates in chip

#### installs

Chips installed within the chip

#### name

Name of chip

# Private Methods

## AUTOLOAD($chip, @options)

Autoload by gate name to provide a more readable way to specify the gates on a chip.

       Parameter  Description
    1  $chip      Chip
    2  @options   Options

# Index

1 [AUTOLOAD](#autoload) - Autoload by gate name to provide a more readable way to specify the gates on a chip.

2 [gate](#gate) - A gate of some [sort](https://en.wikipedia.org/wiki/Sorting) to be added to the chip.

3 [install](#install) - Install a chip within another chip specifying the connections between the inner and outer chip.

4 [newChip](#newchip) - Create a new chip

5 [simulate](#simulate) - Simulate the set of gates until nothing changes.

# Installation

This [module](https://en.wikipedia.org/wiki/Modular_programming) is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and [install](https://en.wikipedia.org/wiki/Installation_(computer_programs)) via **cpan**:

    sudo [CPAN](https://metacpan.org/author/PRBRENAN) [install](https://en.wikipedia.org/wiki/Installation_(computer_programs)) Silicon::Chip

# Author

[philiprbrenan@gmail.com](mailto:philiprbrenan@gmail.com)

[http://www.appaapps.com](http://www.appaapps.com)

# Copyright

Copyright (c) 2016-2023 Philip R Brenan.

This [module](https://en.wikipedia.org/wiki/Modular_programming) is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

<div>
    <p><a href="https://github.com/philiprbrenan/SiliconChip"><img src="https://github.com/philiprbrenan/SiliconChip/workflows/Test/badge.svg"></a>
</div>

# Name

Silicon::Chip - Design a [silicon](https://en.wikipedia.org/wiki/Silicon) [chip](https://en.wikipedia.org/wiki/Integrated_circuit) by combining [logic gates](https://en.wikipedia.org/wiki/Logic_gate) and sub [chips](https://en.wikipedia.org/wiki/Integrated_circuit).

# Synopsis

Create and simulate a 4 bit comparator:

    use Silicon::Chip;

    my $B = 4;
    my $c = Silicon::Chip::newChip(title=>"$B Bit Comparator");
    $c->input ("a$_") for 1..$B;                                                  # First number
    $c->input ("b$_") for 1..$B;                                                  # Second number
    $c->nxor  ("e$_", {1=>"a$_", 2=>"b$_"}) for 1..$B;                            # Test each bit for equality
    $c->and   ("and", {map{$_=>"e$_"}           1..$B});                          # And tests together to get equality
    $c->output("out", "and");

    my $s = $c->simulate({a1=>1, a2=>0, a3=>1, a4=>0,
                          b1=>1, b2=>0, b3=>1, b4=>0}, svg=>"svg/Compare4");
    is_deeply($s->steps, 3);                                                      # Three steps
    is_deeply($s->values->{out}, 1);                                              # Result is 1

To obtain:

<div>
    <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/Compare4.svg">
</div>

# Description

Design a [silicon](https://en.wikipedia.org/wiki/Silicon) [chip](https://en.wikipedia.org/wiki/Integrated_circuit) by combining [logic gates](https://en.wikipedia.org/wiki/Logic_gate) and sub [chips](https://en.wikipedia.org/wiki/Integrated_circuit).

Version 20231026.

The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see [Index](#index).

# Construct

Construct a [Silicon](https://en.wikipedia.org/wiki/Silicon) [chip](https://en.wikipedia.org/wiki/Integrated_circuit) using standard [logic gates](https://en.wikipedia.org/wiki/Logic_gate).

## newChip(%options)

Create a new [chip](https://en.wikipedia.org/wiki/Integrated_circuit).

       Parameter  Description
    1  %options   Options

**Example:**

    if (1)                                                                           Single AND gate
    
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

    if (1)                                                                           Two AND gates driving an OR gate a tree  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

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

Install a [chip](https://en.wikipedia.org/wiki/Integrated_circuit) within another [chip](https://en.wikipedia.org/wiki/Integrated_circuit) specifying the connections between the inner and outer [chip](https://en.wikipedia.org/wiki/Integrated_circuit).  The same [chip](https://en.wikipedia.org/wiki/Integrated_circuit) can be installed multiple times as each [chip](https://en.wikipedia.org/wiki/Integrated_circuit) description is read only.

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
    
      is_deeply($s, {steps  => 2,
        changed => { "(inner 1 In)" => 0,             "Oo" => 1 },
        values  => { "(inner 1 In)" => 0, "Oi1" => 1, "Oo" => 0 }});
     }
    

# Simulate

Simulate the behavior of the [chip](https://en.wikipedia.org/wiki/Integrated_circuit).

## simulate($chip, $inputs, %options)

Simulate the action of the [logic gates](https://en.wikipedia.org/wiki/Logic_gate) on a [chip](https://en.wikipedia.org/wiki/Integrated_circuit) for a given set of inputs until the output values of each [logic gate](https://en.wikipedia.org/wiki/Logic_gate) stabilize.

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

#### title

Title if known

# Private Methods

## AUTOLOAD($chip, @options)

Autoload by [logic gate](https://en.wikipedia.org/wiki/Logic_gate) name to provide a more readable way to specify the [logic gates](https://en.wikipedia.org/wiki/Logic_gate) on a [chip](https://en.wikipedia.org/wiki/Integrated_circuit).

       Parameter  Description
    1  $chip      Chip
    2  @options   Options

# Index

1 [AUTOLOAD](#autoload) - Autoload by [logic gate](https://en.wikipedia.org/wiki/Logic_gate) name to provide a more readable way to specify the [logic gates](https://en.wikipedia.org/wiki/Logic_gate) on a [chip](https://en.wikipedia.org/wiki/Integrated_circuit).

2 [gate](#gate) - A [logic gate](https://en.wikipedia.org/wiki/Logic_gate) of some sort to be added to the [chip](https://en.wikipedia.org/wiki/Integrated_circuit).

3 [install](#install) - Install a [chip](https://en.wikipedia.org/wiki/Integrated_circuit) within another [chip](https://en.wikipedia.org/wiki/Integrated_circuit) specifying the connections between the inner and outer [chip](https://en.wikipedia.org/wiki/Integrated_circuit).

4 [newChip](#newchip) - Create a new [chip](https://en.wikipedia.org/wiki/Integrated_circuit).

5 [simulate](#simulate) - Simulate the action of the [logic gates](https://en.wikipedia.org/wiki/Logic_gate) on a [chip](https://en.wikipedia.org/wiki/Integrated_circuit) for a given set of inputs until the output values of each [logic gate](https://en.wikipedia.org/wiki/Logic_gate) stabilize.

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

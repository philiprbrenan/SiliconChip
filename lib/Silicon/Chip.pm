#!/usr/bin/perl -I/home/phil/perl/cpan/SvgSimple/lib/
#-------------------------------------------------------------------------------
# Design a silicon chip by combining gates and sub chips.
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2023
#-------------------------------------------------------------------------------
# Provide two parameter versions of all gates that can take two inputs to avoid complicated hash
use v5.34;
package Silicon::Chip;
our $VERSION = 20231103;                                                        # Version
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use Svg::Simple;

makeDieConfess;

my sub maxSimulationSteps {100}                                                 # Maximum simulation steps
my sub gateNotIO          {0}                                                   # Not an input or output gate
my sub gateInternalInput  {1}                                                   # Input gate on an internal chip
my sub gateInternalOutput {2}                                                   # Output gate on an internal chip
my sub gateExternalInput  {3}                                                   # Input gate on the external chip
my sub gateExternalOutput {4}                                                   # Output gate on the external chip
my sub gateOuterInput     {5}                                                   # Input gate on the external chip connecting to the outer world
my sub gateOuterOutput    {6}                                                   # Output gate on the external chip connecting to the outer world

my $possibleTypes = q(and|continue|gt|input|lt|nand|nor|not|nxor|one|or|output|xor|zero);#Substitute: possible gate types

#D1 Construct                                                                   # Construct a L<silicon> L<chip> using standard L<lgs>, components and sub chips combined via buses.

sub newChip(%)                                                                  # Create a new L<chip>.
 {my (%options) = @_;                                                           # Options
  !@_ or !ref($_[0]) or confess "Call as a sub not as a method";
  genHash(__PACKAGE__,                                                          # Chip description
    name    => $options{name} // $options{title}  // "Unnamed chip: ".timeStamp,# Name of chip
    gates   => $options{gates} // {},                                           # Gates in chip
    installs=> $options{installs} // [],                                        # Chips installed within the chip
    title   => $options{title},                                                 # Title if known
    gateSeq => 0,                                                               # Gate sequence number - this allows us to display the gates in the order they were defined ti simplify the understanding of drawn layouts
   );
 }

my sub newGate($$$$)                                                            # Make a L<lg>.
 {my ($chip, $type, $output, $inputs) = @_;                                     # Chip, gate type, output name, input names to output from another gate

  my $g = genHash("Silicon::Chip::Gate",                                        # Gate
   type     => $type,                                                           # Gate type
   output   => $output,                                                         # Output name which is used as the name of the gate as well
   inputs   => $inputs,                                                         # Input names to driving outputs
   io       => gateNotIO,                                                       # Whether an input/output gate or not
   seq      => ++$chip->gateSeq,                                                # Sequence number for this gate
  );
 }

my sub validateName($$%)                                                        # Confirm that a component name looks like a variable name and has not already been used
 {my ($chip, $output, %options) = @_;                                           # Chip, name, options

  my $gates = $chip->gates;                                                     # Gates implementing the chip

  $output =~ m(\A[a-z][a-z0-9_.:]*\Z)i or confess <<"END";
Invalid gate name: '$output'
END

  $$gates{$output} and confess <<"END";
Gate: '$output' has already been specified
END
  1
 }

sub gate($$$;$$)                                                                # A L<lg> chosen from B<possibleTypes>.  The gate type can be used as a method name, so B<-E<gt>gate("and",> can be reduced to B<-E<gt>and(>.
 {my ($chip, $type, $output, $input1, $input2) = @_;                            # Chip, gate type, output name, input from another gate, input from another gate
  @_ >= 3 or confess "Three or more parameters";
  my $gates = $chip->gates;                                                     # Gates implementing the chip

  my $inputs;                                                                   # Input hash mapping used to accept outputs from other gates as inputs for this gate

  validateName $chip, $output;                                                  # Validate the name of the gate

  if ($type =~ m(\A(input)\Z)i)                                                 # Input gates input to themselves unless they have been connected to an output gate during sub chip expansion
   {@_> 3 and confess <<"END";
No input hash allowed for input gate: '$output'
END
    $inputs = {$output=>$output};                                               # Convert convenient scalar name to hash for consistency with gates in general
   }
  elsif ($type =~ m(\A(one|zero)\Z)i)                                           # Input gates input to themselves unless they have been connected to an output gate during sub chip expansion
   {@_> 3 and confess <<"END";
No input hash allowed for '$type' gate: '$output'
END
    $inputs = {};                                                               # Convert convenient scalar name to hash for consistency with gates in general
   }
  elsif ($type =~ m(\A(output)\Z)i)                                             # Output has one optional scalar value naming its input if known at this point
   {if (defined($input1))
     {ref($input1) and confess <<"END";
Scalar input name required for input on output gate: '$output'
END
      $inputs = {$output=>$input1};                                             # Convert convenient scalar name to hash for consistency with gates in general
     }
   }
  elsif ($type =~ m(\A(continue|not)\Z)i)                                       # These gates have one input expressed as a name rather than a hash
   {!defined($input1) and confess "Input name required for gate: '$output'\n";
    $type =~ m(\Anot\Z)i and ref($input1) =~ m(hash)i and confess <<"END";
Scalar input name required for: '$output'
END
    $inputs = {$output=>$input1};                                               # Convert convenient scalar name to hash for consistency with gates in general
   }
  elsif ($type =~ m(\A(nxor|xor|gt|ngt|lt|nlt)\Z)i)                             # These gates must have exactly two inputs expressed as a hash mapping input pin name to connection to a named gate.  These operations are associative.
   {!defined($input1) and confess <<"END" =~ s/\n/ /gsr;
Input one required for gate: '$output'
END
    !defined($input2) and confess <<"END" =~ s/\n/ /gsr;
Input two required for gate: '$output'
END
    ref($input1) and confess <<"END" =~ s/\n/ /gsr;
Input one must be the name of the connecting gate.
END
    ref($input2) and confess <<"END" =~ s/\n/ /gsr;
Input two must be the name of the connecting gate.
END
    $inputs = {1=>$input1, 2=>$input2};                                         # Construct the inputs hash expected in general for these two input gates
   }
  elsif ($type =~ m(\A(and|nand|nor|or)\Z)i)                                    # These gates must have two or more inputs expressed as a hash mapping input pin name to connection to a named gate.  These operations are associative.
   {!defined($input1) and confess <<"END" =~ s/\n/ /gsr;
Input hash required for gate: '$output'
END
    if (ref($input1) =~ m(hash)i)
     {$inputs = $input1;
     }
    elsif (ref($input1) =~ m(array)i)
     {$inputs = {map {$_=>$$input1[$_]} keys @$input1};
     }
    else
     {confess <<"END" =~ s/\n/ /gsr;
Inputs must be either a hash of input gate
names to output gate names or an array of input gate name for gate: '$output'
END
     }
   }
  else                                                                          # Unknown gate type
   {confess <<"END" =~ s/\n/ /gsr;
Unknown gate type: '$type' for gate: '$output',
possible types are: '$possibleTypes
END
   }

  $chip->gates->{$output} = newGate($chip, $type, $output, $inputs);            # Construct gate, save it and return it
 }

our $AUTOLOAD;                                                                  # The method to be autoloaded appears here. This allows us to have gate names like 'or' and 'and' without overwriting the existing Perl operators with these names.

sub AUTOLOAD($@)                                                                #P Autoload by L<lg> name to provide a more readable way to specify the L<lgs> on a L<chip>.
 {my ($chip, @options) = @_;                                                    # Chip, options
  my $type = $AUTOLOAD =~ s(\A.*::) ()r;
  if ($type !~ m(\A($possibleTypes|DESTROY)\Z))                                 # Select autoload requests we can process as gate names
   {confess <<"END" =~ s/\n/ /gsr;
Unknown method: '$type'
END
   }
  &gate($chip, $type, @options) if $type =~ m(\A($possibleTypes)\Z);
 }

my sub cloneGate($$)                                                            # Clone a L<lg> on a L<chip>.
 {my ($chip, $gate) = @_;                                                       # Chip, gate
  my %i = $gate->inputs ? $gate->inputs->%* : ();                               # Copy inputs
  newGate($chip, $gate->type, $gate->output, {%i})
 }

my sub renameGateInputs($$$)                                                    # Rename the inputs of a L<lg> on a L<chip>.
 {my ($chip, $gate, $name) = @_;                                                # Chip, gate, prefix name
  for my $p(qw(inputs))
   {my %i;
    my $i = $gate->inputs;
    for my $n(sort keys %$i)
     {$i{$n} = sprintf "(%s %s)", $name, $$i{$n};
     }
    $gate->inputs = \%i;
   }
  $gate
 }

my sub renameGate($$$)                                                          # Rename a L<lg> on a L<chip> by adding a prefix.
 {my ($chip, $gate, $name) = @_;                                                # Chip, gate, prefix name
  $gate->output = sprintf "(%s %s)", $name, $gate->output;
  $gate
 }

#D2 Buses                                                                       # A bus is an array of bits or an array of arrays of bits

#D3 Bits                                                                        # An array of bits that can be manipulated via one name.

sub bits($$$$%)                                                                 # Create a bus set to a specified number.
 {my ($chip, $name, $bits, $value, %options) = @_;                              # Chip, name of bus, width in bits of bus, value of bus, options
  @_ >= 4 or confess "Four or more parameters";
  my @b = reverse split //, sprintf "%0${bits}b", $value;                       # Bits needed
  for my $b(1..@b)                                                              # Generate constant
   {my $v = $b[$b-1];                                                           # Bit value
    $chip->one (n($name, $b)) if     $v;                                        # Set 1
    $chip->zero(n($name, $b)) unless $v;                                        # Set 0
   }
 }

sub inputBits($$$%)                                                             # Create an B<input> bus made of bits.
 {my ($chip, $name, $bits, %options) = @_;                                      # Chip, name of bus, width in bits of bus, options
  @_ >= 3 or confess "Three or more parameters";
  map {$chip->input(n($name, $_))} 1..$bits;                                    # Bus of input gates
 }

sub outputBits($$$$%)                                                           # Create an B<output> bus made of bits.
 {my ($chip, $name, $input, $bits, %options) = @_;                              # Chip, name of bus, name of inputs, width in bits of bus, options
  @_ >= 4 or confess "Four or more parameters";
  map {$chip->output(n($name, $_), n($input, $_))} 1..$bits;                    # Bus of output gates
 }

sub notBits($$$$%)                                                              # Create a B<not> bus made of bits.
 {my ($chip, $name, $input, $bits, %options) = @_;                              # Chip, name of bus, name of inputs, width in bits of bus, options
  @_ >= 4 or confess "Four or more parameters";
  map {$chip->not(n($name, $_), n($input, $_))} 1..$bits;                       # Bus of not gates
 }

sub andBits($$$$%)                                                              # B<and> a bus made of bits.
 {my ($chip, $name, $input, $bits, %options) = @_;                              # Chip, name of bus, name of inputs, width in bits of bus, options
  @_ >= 4 or confess "Four or more parameters";
  $chip->and($name, {map {($_=>n($input, $_))} 1..$bits});                      # Combine inputs in one B<and> gate
 }

sub nandBits($$$$%)                                                             # B<nand> a bus made of bits.
 {my ($chip, $name, $input, $bits, %options) = @_;                              # Chip, name of bus, name of inputs, width in bits of bus, options
  @_ >= 4 or confess "Four or more parameters";
  $chip->nand($name, {map {($_=>n($input, $_))} 1..$bits});                     # Combine inputs in one B<nand> gate
 }

sub orBits($$$$%)                                                               # B<or> a bus made of bits.
 {my ($chip, $name, $input, $bits, %options) = @_;                              # Chip, name of bus, name of inputs, width in bits of bus, options
  @_ >= 4 or confess "Four or more parameters";
  $chip->or($name,  {map {($_=>n($input, $_))} 1..$bits});                      # Combine inputs in one B<or> gate
 }

sub norBits($$$$%)                                                              # B<nor> a bus made of bits.
 {my ($chip, $name, $input, $bits, %options) = @_;                              # Chip, name of bus, name of inputs, width in bits of bus, options
  @_ >= 4 or confess "Four or more parameters";
  $chip->nor($name,  {map {($_=>n($input, $_))} 1..$bits});                     # Combine inputs in one B<nor> gate
 }

#D3 Words                                                                       # An array of arrays of bits that can be manipulated via one name.

sub inputWords($$$$%)                                                           # Create an B<input> bus made of words.
 {my ($chip, $name, $words, $bits, %options) = @_;                              # Chip, name of bus, width in words of bus, width in bits of each word on bus, options
  @_ >= 4 or confess "Four or more parameters";
  for my $w(1..$words)                                                          # Each word on the bus
   {map {$chip->input(nn($name, $w, $_))} 1..$bits;                             # Bus of input gates
   }
 }

sub outputWords($$$$$%)                                                         # Create an B<output> bus made of words.
 {my ($chip, $name, $input, $words, $bits, %options) = @_;                      # Chip, name of bus, name of inputs, width in words of bus, width in bits of each word on bus, options
  @_ >= 5 or confess "Five or more parameters";
  for my $w(1..$words)                                                          # Each word on the bus
   {map {$chip->output(nn($name, $w, $_), nn($input, $w, $_))} 1..$bits;        # Bus of output gates
   }
 }

sub notWords($$$$$%)                                                            # Create a B<not> bus made of words.
 {my ($chip, $name, $input, $words, $bits, %options) = @_;                      # Chip, name of bus, name of inputs, width in words of bus, width in bits of each word on bus, options
  @_ >= 5 or confess "Five or more parameters";
  for my $w(1..$words)                                                          # Each word on the bus
   {map {$chip->not(nn($name, $w, $_), nn($input, $w, $_))} 1..$bits;           # Bus of not gates
   }
 }

sub andWords($$$$$%)                                                            # B<and> a bus made of words to produce a single word.
 {my ($chip, $name, $input, $words, $bits, %options) = @_;                      # Chip, name of bus, name of inputs, width in words of bus, width in bits of each word on bus, options
  @_ >= 5 or confess "Five or more parameters";
  for my $w(1..$words)                                                          # Each word on the bus
   {$chip->and(n($name, $w), {map {($_=>nn($input, $w, $_))} 1..$bits});        # Combine inputs using B<and> gates
   }
 }

sub andWordsX($$$$$%)                                                           # B<and> a bus made of words by and-ing the corresponding bits in each word to make a single word.
 {my ($chip, $name, $input, $words, $bits, %options) = @_;                      # Chip, name of bus, name of inputs, width in words of bus, width in bits of each word on bus, options
  @_ >= 5 or confess "Five or more parameters";
  for my $b(1..$bits)                                                           # Each word on the bus
   {$chip->and(n($name, $b), {map {($_=>nn($input, $_, $b))} 1..$words});       # Combine inputs using B<and> gates
   }
 }

sub orWords($$$$$%)                                                             # B<or> a bus made of words to produce a single word.
 {my ($chip, $name, $input, $words, $bits, %options) = @_;                      # Chip, name of bus, name of inputs, width in words of bus, width in bits of each word on bus, options
  @_ >= 5 or confess "Five or more parameters";
  for my $w(1..$words)                                                          # Each word on the bus
   {$chip->or(n($name, $w), {map {($_=>nn($input, $w, $_))} 1..$bits});         # Combine inputs using B<or> gates
   }
 }

sub orWordsX($$$$$%)                                                            # B<or> a bus made of words by or-ing the corresponding bits in each word to make a single word.
 {my ($chip, $name, $input, $words, $bits, %options) = @_;                      # Chip, name of bus, name of inputs, width in words of bus, width in bits of each word on bus, options
  @_ >= 5 or confess "Five or more parameters";
  for my $b(1..$bits)                                                           # Each word on the bus
   {$chip->or (n($name, $b), {map {($_=>nn($input, $_, $b))} 1..$words});       # Combine inputs using B<or> gates
   }
 }

#D2 Install                                                                     # Install a chip within a chip as a sub chip.

sub install($$$$%)                                                              # Install a L<chip> within another L<chip> specifying the connections between the inner and outer L<chip>.  The same L<chip> can be installed multiple times as each L<chip> description is read only.
 {my ($chip, $subChip, $inputs, $outputs, %options) = @_;                       # Outer chip, inner chip, inputs of inner chip to to outputs of outer chip, outputs of inner chip to inputs of outer chip, options
  @_ >= 4 or confess "Four or more parameters";
  my $c = genHash("Silicon::Chip::Install",                                     # Installation of a chip within a chip
    chip    => $subChip,                                                        # Chip being installed
    inputs  => $inputs,                                                         # Outputs of outer chip to inputs of inner chip
    outputs => $outputs,                                                        # Outputs of inner chip to inputs of outer chip
   );
  push $chip->installs->@*, $c;                                                 # Install chip
  $c
 }

my sub getGates($%)                                                             # Get the L<lgs> of a L<chip> and all it installed sub chips.
 {my ($chip, %options) = @_;                                                    # Chip, options

  my %outerGates;
  for my $g(sort {$a->seq <=> $b->seq} values $chip->gates->%*)                 # Copy gates from outer chip
   {my $G = $outerGates{$g->output} = cloneGate($chip, $g);
    if    ($G->type =~ m(\Ainput\Z)i)  {$G->io = gateExternalInput}             # Input gate on outer chip
    elsif ($G->type =~ m(\Aoutput\Z)i) {$G->io = gateExternalOutput}            # Output gate on outer chip
   }

  my @installs = $chip->installs->@*;                                           # Each sub chip used in this chip

  for my $install(keys @installs)                                               # Each sub chip
   {my $s = $installs[$install];                                                # Sub chip installed in this chip
    my $n = $s->chip->name;                                                     # Name of sub chip
    my $innerGates = __SUB__->($s->chip);                                       # Gates in sub chip

    for my $G(sort {$$innerGates{$a}->seq <=> $$innerGates{$b}->seq}
              keys  %$innerGates)                                               # Each gate in sub chip on definition order
     {my $g = $$innerGates{$G};                                                 # Gate in sub chip
      my $o = $g->output;                                                       # Name of gate
      my $copy = cloneGate $chip, $g;                                           # Clone gate from chip description
      my $newGateName = sprintf "$n %d", $install+1;                            # Rename gates to prevent name collisions from the expansions of the definitions of the inner chips

      if ($copy->type =~ m(\Ainput\Z)i)                                         # Input gate on inner chip - connect to corresponding output gate on containing chip
       {my $in = $copy->output;                                                 # Name of input gate on inner chip
        my $o  = $s->inputs->{$in};
           $o or confess <<"END";
No connection specified to inner input gate: '$in' on sub chip: '$n'
END
        my $O  = $outerGates{$o};
           $O or confess <<"END" =~ s(\n) ( )gsr;
No outer output gate '$o' to connect to inner input gate: '$in'
on sub chip: '$n'
END
        my $ot = $O->type;
        my $on = $O->output;
           $ot =~ m(\Aoutput\Z)i or confess <<"END" =~ s(\n) ( )gsr;
Output gate required for connection to: '$in' on sub chip $n,
not: '$ot' gate: '$on'
END
        $copy->inputs = {1 => $o};                                              # Connect inner input gate to outer output gate
        renameGate $chip, $copy, $newGateName;                                  # Add chip name to gate to disambiguate it from any other gates
        $copy->io = gateInternalInput;                                          # Mark this as an internal input gate
       }

      elsif ($copy->type =~ m(\Aoutput\Z)i)                                     # Output gate on inner chip - connect to corresponding input gate on containing chip
       {my $on = $copy->output;                                                 # Name of output gate on outer chip
        my $i  = $s->outputs->{$on};
           $i or confess <<"END";
No connection specified to inner output gate: '$on' on sub chip: '$n'
END
        my $I  = $outerGates{$i};
           $I or confess <<"END";
No outer input gate: '$i' to connect to inner output gate: $on on sub chip: '$n'
END
        my $it = $I->type;
        my $in = $I->output;
           $it =~ m(\Ainput\Z)i or confess <<"END" =~ s(\n) ( )gsr;
Input gate required for connection to '$in' on sub chip '$n',
not gate '$in' of type '$it'
END
        renameGateInputs $chip, $copy, $newGateName;
        renameGate       $chip, $copy, $newGateName;
        $I->inputs = {11 => $copy->output};                                     # Connect inner output gate to outer input gate
        $copy->io  = gateInternalOutput;                                        # Mark this as an internal output gate
       }
      else                                                                      # Rename all other gate inputs
       {renameGateInputs $chip, $copy, $newGateName;
        renameGate       $chip, $copy, $newGateName;
       }

      $outerGates{$copy->output} = $copy;                                       # Install gate with new name now it has been connected up
     }
   }
  \%outerGates                                                                  # Return all the gates in the chip extended by its sub chips
 }

my sub checkIO($%)                                                              # Check that each input L<lg> is connected to one output  L<lg>.
 {my ($chip, %options) = @_;                                                    # Chip, options
  my $gates = $chip->gates;                                                     # Gates on chip

  my %o;
  for my $G(sort keys %$gates)                                                  # Find all inputs and outputs
   {my $g = $$gates{$G};                                                        # Address gate
    my $t = $g->type;                                                           # Type of gate
    my %i = $g->inputs->%*;                                                     # Inputs for gate
    for my $i(sort keys %i)                                                     # Each input
     {my $o = $i{$i};                                                           # Output driving input
      defined($o) or  confess <<"END";                                          # No driving output
No output driving input pin '$i' on '$t' gate '$G'
END
      my $O = $$gates{$o};
      defined($O) or  confess <<"END";                                          # No driving output
No output driving input '$o' on '$t' gate '$G'
END
      if ($g->io != gateOuterInput)                                             # The gate must inputs driven by the outputs of other gates
       {$o{$o}++;                                                               # Show that this output has been used
        my $T = $O->type;
        if ($g->type =~ m(\Ainput\Z)i)
         {$O->type =~ m(\Aoutput\Z)i or confess <<"END" =~ s(\n) ( )gsr;
Input gate: '$G' must connect to an output gate on pin: '$i'
not to '$T' gate: '$o'
END
         }
        elsif (!$g->io)                                                         # Not an io gate so it cannot have an input from an output gate
         {$O->type =~ m(\Aoutput\Z) and confess <<"END";
Cannot drive a '$t' gate: '$G' using output gate: '$o'
END
         }
       }
     }
   }

  for my $G(sort keys %$gates)                                                  # Check all inputs and outputs are being used
   {my $g = $$gates{$G};                                                        # Address gate
    next if $g->type =~ m(\Aoutput\Z)i;
    $o{$G} or confess <<"END" =~ s/\n/ /gsr;
Output from gate '$G' is never used
END
   }
 }

my sub setOuterGates($$%)                                                       # Set outer  L<lgs> on external chip that connect to the outer world.
 {my ($chip, $gates, %options) = @_;                                            # Chip, gates in chip plus all sub chips as supplied by L<getGates>.

  for my $G(sort keys %$gates)                                                  # Find all inputs and outputs
   {my $g = $$gates{$G};                                                        # Address gate
    next unless $g->io == gateExternalInput;                                    # Input on external chip
    my ($i) = values $g->inputs->%*;
    $g->io = gateOuterInput if $g->output eq $i;                                # Unconnected input gates reflect back on themselves - this is a short hand way of discovering such gates
   }

  gate: for my $G(sort keys %$gates)                                            # Find all inputs and outputs
   {my $g = $$gates{$G};                                                        # Address gate
    next unless $g->io == gateExternalOutput;                                   # Output on external chip
    for my $H(sort keys %$gates)                                                # Gates driven by this gate
     {next if $G eq $H;
      my %i = $$gates{$H}->inputs->%*;                                          # Inputs to this gate
      for my $I(sort keys %i)                                                   # Each input
       {next gate if $i{$I} eq $G;                                              # Found a gate that accepts input from this gate
       }
     }
    $g->io = gateOuterOutput;                                                   # Does not drive any other gate
   }
 }

my sub removeExcessIO($$%)                                                      # Remove unneeded IO L<lgs> .
 {my ($chip, $gates, %options) = @_;                                            # Chip, gates in chip plus all sub chips as supplied by L<getGates>.

  my %d;                                                                        # Names of gates to delete
  for(;;)                                                                       # Multiple passes until no more gates can be replaced
   {my $changes = 0;

    gate: for my $G(sort keys %$gates)                                          # Find all inputs and outputs
     {my $g = $$gates{$G};                                                      # Address gate
      next unless $g->io;                                                       # Skip non IO gates
      next if     $g->io == gateOuterInput or $g->io == gateOuterOutput;        # Cannot be collapsed
      my ($n) = values $g->inputs->%*;                                          # Name of the gate driving this gate

      for my $H(sort keys %$gates)                                              # Gates driven by this gate
       {next if $G eq $H;
        my $h = $$gates{$H};                                                    # Address gate
        my %i = $h->inputs->%*;                                                 # Inputs
        for my $i(sort keys %i)                                                 # Each input
         {if ($i{$i} eq $G)                                                     # Found a gate that accepts input from this gate
           {my $replace = $h->inputs->{$i};
            $h->inputs->{$i} = $n;                                              # Bypass io gate
            $d{$G}++;                                                           # Delete this gate
            ++$changes;                                                         # Count changes in this pass
           }
         }
       }
     }
    last unless $changes;
   }
  for my $d(sort keys %d)                                                       # Gates to delete
   {delete $$gates{$d};
   }
 }

#D1 Visualize                                                                   # Visualize the L<chip> in various ways.

my sub orderGates($%)                                                           # Order the L<lgs> on a L<chip> so that input L<lg> are first, the output L<lgs> are last and the non io L<lgs> are in between. All L<lgs> are first ordered alphabetically. The non io L<lgs> are then ordered by the step number at which they last changed during simulation of the L<chip>.
 {my ($chip, %options) = @_;                                                    # Chip, options

  my $gates = $chip->gates;                                                     # Gates on chip
  my @i; my @n; my @o;

  for my $G(sort {$$gates{$a}->seq <=> $$gates{$b}->seq} keys %$gates)          # Dump each gate one per line in definition order
   {my $g = $$gates{$G};
    push @i, $G if $g->type =~ m(\Ainput\Z)i;
    push @n, $G if $g->type !~ m(\A(in|out)put\Z)i;
    push @o, $G if $g->type =~ m(\Aoutput\Z)i;
   }

  if (my $c = $options{changed})                                                # Order non IO gates by last change time during simulation if possible
   {@n = sort {($$c{$a}//0) <=> ($$c{$b}//0)} @n;
   }

  (\@i, \@n, \@o)
 }

sub dumpGates($%)                                                               # Dump the L<lgs> present on a L<chip>.
 {my ($chip, %options) = @_;                                                    # Chip, gates, options
  my $gates  = $chip->gates;                                                    # Gates on chip
  my $values = $options{values};                                                # Values of each gate if known
  my @s;
  my ($i, $n, $o) = orderGates $chip, %options;                                 # Gates by type
  for my $G(@$i, @$n, @$o)                                                      # Dump each gate one per line
   {my $g = $$gates{$G};
    my %i = $g->inputs ? $g->inputs->%* : ();

    my $p = sub                                                                 # Instruction name and type
     {my $v = $$values{$G};                                                     # Value if known for this gate
      my $o = $g->output;
      my $t = $g->type;
      return sprintf "%-32s: %3d %-32s", $o, $v, $t if defined($v);             # With value
      return sprintf "%-32s:     %-32s", $o,     $t;                            # Without value
     }->();

    if (my @i = map {$i{$_}} sort keys %i)                                      # Add actual inputs in same line sorted in input pin name
     {$p .= join " ", @i;
     }
    push @s, $p;
   }
  my $s = join "\n", @s, '';                                                    # Representation of gates as text
  owf fpe($options{dumpGates}, q(txt)), $s if $options{dumpGates};              # Write representation of gates as text to the named file
  $s
 }

sub Silicon::Chip::Simulation::print($%)                                        # Print simulation results as text.
 {my ($sim, %options) = @_;                                                     # Simulation, options
  dumpGates($sim->chip, %options, values=>$sim->values);
 }

my sub newGatePosition(%)                                                       # Specify the position of a L<lg> on a drawing of the containing L<chip>.
 {my (%options) = @_;                                                           # Options

  genHash("Silicon::Chip::Gate::Position",                                      # Gate position
    gate  => $options{gate}  // undef,                                          # Gate
    x     => $options{x}     // undef,                                          # X position of gate
    y     => $options{y}     // undef,                                          # Y position of gate
    width => $options{width} // undef,                                          # Width of gate
   )
 }

sub svgGates($%)                                                                # Dump the L<lgs> on a L<chip> as an L<svg> drawing to help visualize the structure of the L<chip>.
 {my ($chip, %options) = @_;                                                    # Chip, options
  my $gates   = $chip->gates;                                                   # Gates on chip
  my $title   = $chip->title;                                                   # Title of chip
  my $changed = $options{changed};                                              # Step at which gate last changed in simulation
  my $values  = $options{values};                                               # Values of each gate if known
  my $steps   = $options{steps};                                                # Number of steps to equilibrium

  my $fs = 0.2; my $fw = 0.02;                                                  # Font sizes
  my $Fs = 0.4; my $Fw = 0.04;
  my $op0 = q(transparent);

  my $s = Svg::Simple::new(defaults=>{stroke_width=>$fw, font_size=>$fs});      # Draw each gate via Svg

  my %p;                                                                        # Dimensions and drawing positions of gates
  my ($iG, $nG, $oG) = orderGates $chip, %options;                              # Gates by type

  for my $i(keys @$iG)                                                          # Index of each input gate
   {my $G = $$iG[$i];                                                           # Gate name
    my $g = $$gates{$G};                                                        # Gate
    $p{$G} = newGatePosition(gate=>$g, x=>0, y=>$i, width=>1);                  # Position input gate
   }

  my $W = 0;                                                                    # Number of inputs to all the non IO gates
  for my $i(keys @$nG)                                                          # Index of each non IO gate
   {my $G = $$nG[$i];                                                           # Gate name
    my $g = $$gates{$G};                                                        # Gate
    my $w = keys($g->inputs->%*) || 1;                                          # Width of gate has to be wide enough to accommodate all inputs
    $p{$G} = newGatePosition(gate=>$g, x=>$W+1, y=>@$iG+$i, width=>$w);         # Position non io gate
    $W   += $w;                                                                 # Width of area needed for non io gates
   }

  for my $i(keys @$oG)                                                          # Index of each output gate
   {my $G = $$oG[$i];                                                           # Gate name
    my $g = $$gates{$G};                                                        # Gate
    my %i = $g->inputs ? $g->inputs->%* : ();                                   # Inputs to gate
    my ($d) = values %i;                                                        # The one driver for this gate
    next unless defined $p{$d};
    my $y = $p{$d}->y;
    $p{$G} = newGatePosition(gate=>$g, x=>1+$W, y=>$y, width=>1);               # Position output gate
   }

  my $pageWidth = $W + 2;                                                       # Width of input, output and non io gates as laid out.

  if (defined($title))                                                          # Title if known
   {$s->text(x=>$pageWidth, y=>0.5, fill=>"darkGreen", text_anchor=>"end",
      stroke_width=>$Fw, font_size=>$Fs,
      cdata=>$title);
   }

  if (defined($steps))                                                          # Number of steps taken if known
   {$s->text(x=>$pageWidth, y=>1.5, fill=>"darkGreen", text_anchor=>"end",
      stroke_width=>$Fw, font_size=>$Fs,
      cdata=>"$steps steps");
   }

  for my $P(sort keys %p)                                                       # Each gate with text describing it
   {my $p = $p{$P};
    my $x = $p->x; my $y = $p->y; my $w = $p->width; my $g = $p->gate;          # Position of gate

    my $color = sub
     {return "red"  if $g->io == gateOuterOutput;
      return "blue" if $g->io == gateOuterInput;
      "green"
     }->();

    if ($g->io)                                                                 # Circle for io pin
     {$s->circle(cx=>$x+1/2, cy=>$y+1/2, r=>1/2,   fill=>$op0, stroke=>$color);
     }
    else                                                                        # Rectangle for non io gate
     {$s->rect(x=>$x, y=>$y, width=>$w, height=>1, fill=>$op0, stroke=>$color);
     }

    if (defined(my $v = $$values{$g->output}))                                  # Value of gate if known
     {$s->text(
       x                 => $g->io != gateOuterOutput ? $x : $x + 1,
       y                 => $y,
       fill              =>"black",
       stroke_width      =>$Fw, font_size=>$Fs,
       text_anchor       => $g->io != gateOuterOutput ? "start": "end",
       dominant_baseline => "hanging",
       cdata             => $v ? "1" : "0");
     }

    my sub ot($$$$)                                                             # Output svg text
     {my ($dy, $fill, $pos, $text) = @_;
      $s->text(x                 => $x+$w/2,
               y                 => $y+$dy,
               fill              => $fill,
               text_anchor       => "middle",
               dominant_baseline => $pos,
               cdata             => $text);
      }

    ot(5/12, "red",      "auto",    $g->type);                                  # Type of gate
    ot(7/12, "darkblue", "hanging", $g->output);

    if ($g->io != gateOuterInput)                                               # Not an input pin
     {my %i = $g->inputs ? $g->inputs->%* : ();
      my @i = sort values %i;                                                   # Connections to each gate

      for my $i(keys @i)                                                        # Connections to each gate
       {my $P = $p{$i[$i]};                                                     # Source gate
        defined($P) or confess "No such gate as: '$i[$i]'\n";
        my $X = $P->x; my $Y = $P->y; my $W = $P->width; my $G = $P->gate;      # Position of gate
        my $dx = $i + 1/2;
        my $dy = $Y < $y ?  0 : 1;
        my $dX = $X < $x ? $W : 0;
        my $dY = $Y < $y ?  0 : 0;
        my $cx = $x+$dx;                                                        # Horizontal line corner x
        my $cy = $Y+$dY+1/2;                                                    # Horizontal line corner y

        my $xc = $X < $x ? q(black) : q(darkBlue);                              # Horizontal line color
        my $x2 = $g->io == gateOuterOutput ? $cx - 1/2 : $cx;
        $s->line(x1=>$X+$dX, x2=>$x2, y1=>$cy, y2=>$cy,    stroke=>$xc);        # Outgoing value along horizontal lines

        my $yc = $Y < $y ? q(purple) : q(darkRed);                              # Vertical lines

        if ($g->io != gateOuterOutput)                                          # Incoming value along vertical line - not needed for outer output gates
         {$s->line(x1=>$cx,   x2=>$cx, y1=>$cy, y2=>$y+$dy, stroke=>$yc);
          $s->circle(cx=>$cx, cy=>$cy,    r=>0.06, fill=>"red");                # Line corner
          $s->circle(cx=>$x2, cy=>$y+$dy, r=>0.04, fill=>"blue");               # Line entering gate
         }
        else                                                                    # External output gate
         {$s->circle(cx=>$x2,   cy=>$y+$dy-1/2, r=>0.04, fill=>"blue");         # Line entering output
         }

        $s->circle(cx=>$X+$W, cy=>$cy,    r=>0.04, fill=>"red");                # Line exiting gate

        if (defined(my $v = $$values{$G->output}) and $g->io != gateOuterOutput)# Value of gate if known except for output gates written else where
         {$s->text(
            x           => $cx,
            y           => $y+$dy+($X < $x ? 0.1 : -0.1),
            fill        => "black", stroke_width=>$fw, font_size=>$fs,
            text_anchor => "middle",
            $X < $x ? (dominant_baseline=>"hanging") : (),
            cdata       =>  $v ? "1" : "0");
         }
       }
     }
   }
  my $t = $s->print;
  return owf(fpe($options{svg}, q(svg)), $t) if $options{svg};
  $t
 }

sub Silicon::Chip::Simulation::printSvg($%)                                     # Print simulation results as svg.
 {my ($sim, %options) = @_;                                                     # Simulation, options
  svgGates($sim->chip, %options);
 }

#D1 Basic Circuits                                                              # Some well known basic circuits.

sub n(*$)                                                                       # Gate name from single index.
 {my ($c, $i) = @_;                                                             # Gate name, bit number
  !@_ or !ref($_[0]) or confess <<"END";
Call as a sub not as a method
END
  "${c}_$i"
 }

sub nn(*$$)                                                                     # Gate name from double index.
 {my ($c, $i, $j) = @_;                                                         # Gate name, word number, bit number
  !@_ or !ref($_[0]) or confess confess <<"END";
Call as a sub not as a method
END
 "${c}_${i}_$j"
 }

#D2 Comparisons                                                                 # Compare unsigned binary integers of specified bit widths.

sub compareEq($$$$$%)                                                           # Compare two unsigned binary integers of a specified width returning B<1> if they are equal else B<0>.
 {my ($chip, $output, $a, $b, $bits, %options) = @_;                            # Chip, name of component also the output bus, first integer, second integer, options
  @_ >= 5 or confess "Five or more parameters";
  my $o = $output;

  $chip->nxor(n("$o.e", $_), n($a, $_), n($b, $_)) for 1..$bits;                # Test each bit pair for equality
  $chip->andBits($o, "$o.e", $bits);                                            # All bits must be equal

  $chip
 }

sub compareGt($$$$$%)                                                           # Compare two unsigned binary integers of specified width and return B<1> if the first integer is more than B<b> else B<0>.
 {my ($chip, $output, $a, $b, $bits, %options) = @_;                            # Chip, name of component also the output bus, first integer, second integer, options
  @_ >= 5 or confess "Five or more parameters";
  my $B = $bits;
  my $o = $output;

  $chip->nxor (n("$o.e", $_), n($a, $_), n($b, $_)) for 2..$B;                  # Test all but the lowest bit pair for equality
  $chip->gt   (n("$o.g", $_), n($a, $_), n($b, $_)) for 1..$B;                  # Test each bit pair for more than

  for my $b(2..$B)                                                              # More than on one bit and all preceding bits are equal
   {$chip->and(n("$o.c", $b),
     {(map {$_=>n("$o.e", $_)} $b..$B), ($b-1)=>n("$o.g", $b-1)});
   }

  $chip->or   ($o, {$B=>n("$o.g", $B),  (map {($_-1)=>n("$o.c", $_)} 2..$B)});  # Any set bit indicates that B<a> is more than B<b>

  $chip
 }

sub compareLt($$$$$%)                                                           # Compare two unsigned binary integers B<a>, B<b> of a specified width. Output B<out> is B<1> if B<a> is less than B<b> else B<0>.
 {my ($chip, $output, $a, $b, $bits, %options) = @_;                            # Chip, name of component also the output bus, first integer, second integer, options
  @_ >= 5 or confess "Five or more parameters";
  my $B = $bits;
  my $o = $output;

  $chip->nxor (n("$o.e", $_), n($a, $_), n($b, $_)) for 2..$B;                  # Test all but the lowest bit pair for equality
  $chip->lt   (n("$o.l", $_), n($a, $_), n($b, $_)) for 1..$B;                  # Test each bit pair for less than

  for my $b(2..$B)                                                              # More than on one bit and all preceding bits are equal
   {$chip->and(n("$o.c", $b),
     {(map {$_=>n("$o.e", $_)} $b..$B), ($b-1)=>n("$o.l", $b-1)});
   }

  $chip->or   ($o, {$B=>n("$o.l", $B),  (map {($_-1)=>n("$o.c", $_)} 2..$B)});  # Any set bit indicates that B<a> is less than B<b>

  $chip
 }

sub chooseFromTwoWords($$$$$$%)                                                 # Choose one of two words based on a bit.  The first word is chosen if the bit is B<0> otherwise the second word is chosen.
 {my ($chip, $output, $a, $b, $choose, $bits, %options) = @_;                   # Chip, name of component also the chosen word, the first word, the second word, the choosing bit, the width of the words in bits, options
  @_ >= 6 or confess "Six or more parameters";
  my $o = $output;

  $chip->not("$o.n", $choose);                                                  # Not of the choosing bit
  for my $i(1..$bits)
   {$chip->and(n("$o.a", $i), [n($a, $i),     "$o.n"       ]);                  # Choose first word
    $chip->and(n("$o.b", $i), [n($b, $i),     $choose      ]);                  # Choose second word
    $chip->or (n($o,     $i), [n("$o.a", $i), n("$o.b", $i)]);                  # Or results of choice
   }

  $chip
 }

sub enableWord($$$$$%)                                                          # Output a word or zeros depending on a choice bit.  The first word is chosen if the choice bit is B<1> otherwise all zeroes are chosen.
 {my ($chip, $output, $a, $enable, $bits, %options) = @_;                       # Chip, name of component also the chosen word, the first word, the second word, the choosing bit, the width of the words in bits, options
  @_ >= 5 or confess "Five or more parameters";
  my $o = $output;

  $chip->not ("$o.n", $enable);                                                 # Not of the choosing bit
  $chip->bits("$o.z", $bits, 0);                                                # Zero value to transmit if choice bit is B<0>
  for my $i(1..$bits)
   {$chip->and(n("$o.a", $i), [n($a,     $i), $enable      ]);                  # Choose second word
    $chip->and(n("$o.b", $i), [n("$o.z", $i),   "$o.n"     ]);                  # Choose first word
    $chip->or (n( $o,    $i), [n("$o.a", $i), n("$o.b", $i)]);                  # Or results of choice
   }

  $chip
 }

#D2 Masks                                                                       # Point masks and monotone masks. A point mask has a single B<1> in a sea of B<0>s as in B<00100>.  A monotone mask has zero or more B<0>s followed by all B<1>s as in: B<00111>.

sub pointMaskToInteger($$$$%)                                                   # Convert a mask B<i> known to have at most a single bit on - also known as a B<point mask> - to an output number B<a> representing the location in the mask of the bit set to B<1>. If no such bit exists in the point mask then output number B<a> is B<0>.
 {my ($chip, $output, $input, $bits, %options) = @_;                            # Chip, output name, input mask, number of bits in mask, options
  @_ >= 4 or confess "Four or more parameters";
  my $B = 2**$bits-1;
  my $i = $input;                                                               # The bits in the input mask
  my $o = $output;                                                              # The name of the output bus

  my %b;
  for my $b(1..$B)                                                              # Bits in mask to bits in resulting number
   {my $s = sprintf "%b", $b;
    for my $p(1..length($s))
     {$b{$p}{$b}++ if substr($s, -$p, 1);
     }
   }

  for my $b(sort keys %b)
   {$chip->or    (n($o, $b), {map {$_=>n($i, $_)} sort keys $b{$b}->%*});       # Bits needed to drive a bit in the resulting number
   }

  $chip
 }

sub integerToPointMask($$$$%)                                                   # Convert an integer B<i> of specified width to a point mask B<m>. If the input integer is B<0> then the mask is all zeroes as well.
 {my ($chip, $output, $input, $bits, %options) = @_;                            # Chip, output name, input mask, number of bits in mask, options
  my $B = 2**$bits-1;
  my $o = $output;                                                              # Output mask

  $chip->notBits("$o.n", $input, $bits);                                        # Not of each input

  for my $b(1..$B)                                                              # Each bit of the mask
   {my @s = reverse split //, sprintf "%0${bits}b", $b;                         # Bits for this point in the mask
    my %a;
    for my $i(1..@s)
     {$a{$i} = n($s[$i-1] ? 'i' : "$o.n", $i);                                  # Combination of bits to enable this mask bit
     }
    $chip->and(n($output, $b), {%a});                                           # And to set this point in the mask
   }

  $chip
 }

sub monotoneMaskToInteger($$$$%)                                                # Convert a monotone mask B<i> to an output number B<r> representing the location in the mask of the bit set to B<1>. If no such bit exists in the point then output in B<r> is B<0>.
 {my ($chip, $output, $input, $bits, %options) = @_;                            # Chip, output name, input mask, number of bits in mask, options
  @_ >= 4 or confess "Four or more parameters";
  my $B = 2**$bits-1;
  my $o = $output;

  my %b;
  for my $b(1..$B)
   {my $s = sprintf "%b", $b;
    for my $p(1..length($s))
     {$b{$p}{$b}++ if substr($s, -$p, 1);
     }
   }
  $chip->notBits ("$o.n", $input, $B-1);                                        # Not of each input
  $chip->continue(n("$o.a", 1),  n($input, 1));
  $chip->and     (n("$o.a", $_), [n("$o.n", $_-1), n('i', $_)]) for 2..$B;      # Look for trailing edge

  for my $b(sort keys %b)
   {$chip->or    (n($o, $b), [map {n("$o.a", $_)} sort keys $b{$b}->%*]);       # Bits needed to drive a bit in the resulting number
   }

  $chip
 }

sub monotoneMaskToPointMask($$$$%)                                              # Convert a monotone mask B<i> to a point mask B<o> representing the location in the mask of the first bit set to B<1>. If the monotone mask is all B<0>s then point mask is too.
 {my ($chip, $output, $input, $bits, %options) = @_;                            # Chip, output name, input mask, number of bits in mask, options
  @_ >= 4 or confess "Four or more parameters";
  my $o = $output;

  $chip->continue(n($o, 1), n($input, 1));                                      # The first bit in the monotone mask matches the first bit of the point mask
  for my $b(2..$bits)
   {$chip->xor(n($o, $b), n($input, $b-1), n($input, $b));                      # Detect transition
   }

  $chip
 }

sub integerToMonotoneMask($$$$%)                                                # Convert an integer B<i> of specified width to a monotone mask B<m>. If the input integer is B<0> then the mask is all zeroes.  Otherwise the mask has B<i-1> leading zeroes followed by all ones thereafter.
 {my ($chip, $output, $input, $bits, %options) = @_;                            # Chip, output name, input mask, number of bits in mask, options
  @_ >= 4 or confess "Four or more parameters";
  my $B = 2**$bits-1;
  my $o = $output;

  $chip->notBits("$o.n", $input, $bits);                                        # Not of each input

  for my $b(1..$B)                                                              # Each bit of the mask
   {my @s = (reverse split //, sprintf "%0${bits}b", $b);                       # Bits for this point in the mask
    my %a;
    for  my $i(1..@s)
     {$a{$i} = n($s[$i-1] ? $input : "$o.n", $i);                               # Choose either the input bit or the not of the input but depending on the number being converted to binary
     }
    $chip->and(n("$o.a", $b), {%a});                                            # Set at this point and beyond
    $chip-> or(n($o, $b), [map {n("$o.a", $_)} 1..$b]);                         # Set mask
   }

  $chip
 }

sub chooseWordUnderMask($$$$$$%)                                                # Choose one of a specified number of words B<w>, each of a specified width, using a point mask B<m> placing the selected word in B<o>.  If no word is selected then B<o> will be zero.
 {my ($chip, $output, $input, $mask, $words, $bits, %options) = @_;             # Chip, output, inputs, mask, number of words, number of bits per word, options
  @_ >= 5 or confess "Five or more parameters";
  my $o = $output;

  for   my $w(1..$words)                                                        # And each bit of each word with the mask
   {for my $b(1..$bits)                                                         # Bits in each word
     {$chip->and(nn("$o.a", $w, $b), [n($mask, $w), nn($input, $w, $b)]);
     }
   }

  for   my $b(1..$bits)                                                         # Bits in each word
   {$chip->or(n($o, $b), [map {nn("$o.a", $_, $b)} 1..$words]);
   }

  $chip
 }

sub findWord($$$$$%)                                                            # Choose one of a specified number of words B<w>, each of a specified width, using a key B<k>.  Return a point mask B<o> indicating the locations of the key if found or or a mask equal to all zeroes if the key is not present.
 {my ($chip, $output, $key, $words, $bits, %options) = @_;                      # Chip, found point mask, key, words to search, number of bits per key, options
  @_ >= 5 or confess "Five or more parameters";
  my $o = $output;

  for   my $w(1..2**$bits-1)                                                    # Input words
   {$chip->compareEq(n($o, $w), n($words, $w), $key, $bits);                    # Compare each input word with the key to make a mask
   }

  $chip
 }

#D1 Simulate                                                                    # Simulate the behavior of the L<chip> given a set of values on its input gates.

sub setBits(*$$)                                                                # Set an array of input gates to a number prior to running a simulation.
 {my ($name, $bits, $value) = @_;                                               # Name of input gates, number of bits in each array element, number to set to
  !@_ or !ref($_[0]) or confess <<"END";
Call as a sub not as a method
END
  my $W = 2**$bits;
  $value >= 0 or confess <<"END";
Value $value is less than 0
END
  $value < $W or confess <<"END";
Value $value is greater then or equal to $W
END
  my @b = reverse split //,  sprintf "%0${bits}b", $value;
  my %i = map {n($name, $_) => $b[$_-1]} 1..$bits;
  %i
 }

sub setWords(*$$@)                                                              # Set an array of arrays of gates to an array of numbers prior to running a simulation.
 {my ($name, $words, $bits, @values) = @_;                                      # Name of input gates, number of arrays, number of bits in each array element, numbers to set to
  !@_ or !ref($_[0]) or confess "Call as a sub not as a method";
  my %i;
  my $W = 2**$words;
  for   my $w(1..$words)                                                        # Each word
   {my $n = shift @values;
    $n >= 0 or confess <<"END";
Value $n is less than 0
END
    $n < $W or confess <<"END";
 "Value $n is greater then or equal to $W";
END
    my @b = split //,  sprintf "%0${bits}b", $n;
    for my $b(1..$bits)                                                         # Each bit
     {$i{nn($name, $w, $b)} = $b[-$b];
     }
   }
  %i
 }

sub connectBits($*$*$%)                                                         # Create a connection list connecting a set of output bits on the one chip to a set of input bits on another chip.
 {my ($oc, $o, $ic, $i, $bits, %options) = @_;                                  # First chip, name of gates on first chip, second chip, names of gates on second chip, number of bits to connect, options
 @_ >= 5 or confess "Five or more parameters";
  my %c;
  for my $b(1..$bits)                                                           # Bit to connect
   {$c{n($o, $b)} = n($i, $b);                                                  # Connect bits
   }
  %c                                                                            # Connection list
 }

sub connectWords($*$*$$%)                                                       # Create a connection list connecting a set of words on the outer chip to a set of words on the inner chip.
 {my ($oc, $o, $ic, $i, $words, $bits, %options) = @_;                          # First chip, name of gates on first chip, second chip, names of gates on second chip, number of words to connect, options
  @_ >= 6 or confess "Six or more parameters";
  my %c;
  for   my $w(1..$bits)                                                         # Word to connect
   {for my $b(1..$bits)                                                         # Bit to connect
     {$c{nn($o, $w, $b)} = nn($i, $w, $b);                                      # Connection list
     }
   }
  %c                                                                            # Connection list
 }

my sub merge($%)                                                                # Merge a L<chip> and all its sub L<chips> to make a single L<chip>.
 {my ($chip, %options) = @_;                                                    # Chip, options

  my $gates = getGates $chip;                                                   # Gates implementing the chip and all of its sub chips
  setOuterGates ($chip, $gates);                                                # Set the outer gates which are to be connected to in the real word
  removeExcessIO($chip, $gates);                                                # By pass and then remove all interior IO gates as they are no longer needed

  my $c = newChip %$chip, %options, gates=>$gates, installs=>[];                # Create the new chip with all installs expanded
  dumpGates($c, %options) if $options{dumpGates};                               # Print the gates
  svgGates ($c, %options) if $options{svg};                                     # Draw the gates using svg
  checkIO $c;                                                                   # Check all inputs are connected to valid gates and that all outputs are used

  $c
 }

my sub simulationResults($%)                                                    # Simulation results obtained by specifying the inputs to all the L<lgs> on the L<chip> and allowing its output L<lgs> to stabilize.
 {my ($chip, %options) = @_;                                                    # Chip, hash of final values for each gate, options

  genHash("Silicon::Chip::Simulation",                                          # Simulation results
    chip    => $chip,                                                           # Chip being simulated
    changed => $options{changed},                                               # Last time this gate changed
    steps   => $options{steps},                                                 # Number of steps to reach stability
    values  => $options{values},                                                # Values of every output at point of stability
    svg     => $options{svg},                                                   # Name of file containing svg drawing if requested
   );
 }

my sub checkInputs($$%)                                                         # Check that an input value has been provided for every input pin on the chip.
 {my ($chip, $inputs, %options) = @_;                                           # Chip, inputs, hash of final values for each gate, options

  for my $g(values $chip->gates->%*)                                            # Each gate on chip
   {if   ($g->io == gateOuterInput)                                             # Outer input gate
     {my ($i) = values $g->inputs->%*;                                          # Inputs
      if (!defined($$inputs{$i}))                                               # Check we have a corresponding input
       {my $n = $g->output;
        confess "No input value for input gate: $n\n";
       }
     }
   }
 }

sub Silicon::Chip::Simulation::bitsToInteger($$$%)                              # Represent the state of bits in the simulation results as an unsigned binary integer.
 {my ($simulation, $output, $bits, %options) = @_;                              # Chip, name of gates on bus, width in bits of bus, options
  @_ >= 3 or confess "Three or more parameters";
  my %v = $simulation->values->%*;
  my @b;
  for my $b(1..$bits)                                                           # Bits
   {push @b, $v{n $output, $b};
   }

  eval join '', '0b', reverse @b;                                               # Convert to number
 }

sub Silicon::Chip::Simulation::wordsToInteger($$$$%)                            # Represent the state of words in the simulation results as an array of unsigned binary integer.
 {my ($simulation, $output, $words, $bits, %options) = @_;                      # Chip, name of gates on bus, number of words, width in bits of bus, options
  @_ >= 4 or confess "Four or more parameters";
  my %v = $simulation->values->%*;
  my @w;
  for my $w(1..$words)                                                          # Words
   {my @b;
    for my $b(1..$bits)                                                         # Bits
     {push @b, $v{nn $output, $w, $b};
     }

    push @w,  eval join '', '0b', reverse @b;                                   # Convert to number
   }
  @w
 }

sub Silicon::Chip::Simulation::wordXToInteger($$$$%)                            # Represent the state of words in the simulation results as an array of unsigned binary integer.
 {my ($simulation, $output, $words, $bits, %options) = @_;                      # Chip, name of gates on bus, number of words, width in bits of bus, options
  @_ >= 4 or confess "Four or more parameters";
  my %v = $simulation->values->%*;
  my @w;
  for my $b(1..$bits)                                                           # Bits
   {my @b;
    for my $w(1..$words)                                                        # Words
     {push @b, $v{nn $output, $w, $b};
     }

    push @w,  eval join '', '0b', reverse @b;                                   # Convert to number
   }
  @w
 }

my sub simulationStep($$%)                                                      # One step in the simulation of the L<chip> after expansion of inner L<chips>.
 {my ($chip, $values, %options) = @_;                                           # Chip, current value of each gate, options
  my $gates = $chip->gates;                                                     # Gates on chip
  my %changes;                                                                  # Changes made

  for my $G(sort {$$gates{$a}->seq <=> $$gates{$b}->seq} keys %$gates)          # Each gate in sub chip on definition order to get a repeatable order
   {my $g = $$gates{$G};                                                        # Address gate
    my $t = $g->type;                                                           # Gate type
    my $n = $g->output;                                                         # Gate name
    my %i = $g->inputs->%*;                                                     # Inputs to gate
    my @i = map {$$values{$i{$_}}} sort keys %i;                                # Values of inputs to gates in input pin name order

    my $u = 0;                                                                  # Number of undefined inputs
    for my $i(@i)
     {++$u unless defined $i;
     }

    if ($u == 0)                                                                # All inputs defined
     {my $r;                                                                    # Result of gate operation
      if ($t =~ m(\Aand|nand\Z)i)                                               # Elaborate and B<and> and B<nand> gates
       {my $z = grep {!$_} @i;                                                  # Count zero inputs
        $r = $z ? 0 : 1;
        $r = !$r if $t =~ m(\Anand\Z)i;
       }
      elsif ($t =~ m(\A(input)\Z)i)                                             # An B<input> gate takes its value from the list of inputs or from an output gate in an inner chip
       {if (my @i = values $g->inputs->%*)                                      # Get the value of the input gate from the current values
         {my $n = $i[0];
             $r = $$values{$n};
         }
        else
         {confess "No driver for input gate: $n\n";
         }
       }
      elsif ($t =~ m(\A(continue|nor|not|or|output)\Z)i)                        # Elaborate B<not>, B<or> or B<output> gate. A B<continue> gate places its single input unchanged on its output
       {my $o = grep {$_} @i;                                                   # Count one inputs
        $r = $o ? 1 : 0;
        $r = $r ? 0 : 1 if $t =~ m(\Anor|not\Z)i;
       }
      elsif ($t =~ m(\A(nxor|xor)\Z)i)                                          # Elaborate B<xor>
       {@i == 2 or confess "$t gate: '$n' must have exactly two inputs\n";
        $r = $i[0] ^ $i[1] ? 1 : 0;
        $r = $r ? 0 : 1 if $t =~ m(\Anxor\Z)i;
       }
      elsif ($t =~ m(\A(gt|ngt)\Z)i)                                            # Elaborate B<a> more than B<b> - the input pins are assumed to be sorted by name with the first pin as B<a> and the second as B<b>
       {@i == 2 or confess "$t gate: '$n' must have exactly two inputs\n";
        $r = $i[0] > $i[1] ? 1 : 0;
        $r = $r ? 0 : 1 if $t =~ m(\Angt\Z)i;
       }
      elsif ($t =~ m(\A(lt|nlt)\Z)i)                                            # Elaborate B<a> less than B<b> - the input pins are assumed to be sorted by name with the first pin as B<a> and the second as B<b>
       {@i == 2 or confess "$t gate: '$n' must have exactly two inputs\n";
        $r = $i[0] < $i[1] ? 1 : 0;
        $r = $r ? 0 : 1 if $t =~ m(\Anlt\Z)i;
       }
      elsif ($t =~ m(\Aone\Z)i)                                                 # One
       {@i == 0 or confess "$t gate: '$n' must have no inputs\n";
        $r = 1;
       }
      elsif ($t =~ m(\Azero\Z)i)                                                # Zero
       {@i == 0 or confess "$t gate: '$n' must have no inputs\n";
        $r = 0;
       }
      else                                                                      # Unknown gate type
       {confess "Need implementation for '$t' gates";
       }
      $changes{$G} = $r unless defined($$values{$G}) and $$values{$G} == $r;    # Value computed by this gate
     }
   }
  %changes
 }

sub simulate($$%)                                                               # Simulate the action of the L<lgs> on a L<chip> for a given set of inputs until the output value of each L<lg> stabilizes.
 {my ($chip, $inputs, %options) = @_;                                           # Chip, Hash of input names to values, options
  @_ >= 2 or confess "Two or more parameters";
  my $c = merge($chip, %options);                                               # Merge all the sub chips to make one chip with no sub chips
  checkInputs($c, $inputs);                                                     # Confirm that there is an input value for every input to the chip

  my %values = %$inputs;                                                        # The current set of values contains just the inputs at the start of the simulation
  my %changed;                                                                  # Last step on which this gate changed.  We use this to order the gates on layout

  my $T = maxSimulationSteps;                                                   # Maximum steps
  for my $t(0..$T)                                                              # Steps in time
   {my %changes = simulationStep $c, \%values;                                  # Changes made

    if (!keys %changes)                                                         # Keep going until nothing changes
     {my $svg;
      if ($options{svg})                                                        # Draw the gates using svg with the final values attached
       {$svg = svgGates $c, values=>\%values, changed=>\%changed,
                        steps=>$t, %options;
       }
      return simulationResults $chip, values=>\%values, changed=>\%changed,     # Keep going until nothing changes
               steps=>$t, svg=>$svg;
     }

    for my $c(keys %changes)                                                    # Update state of circuit
     {$values{$c} = $changes{$c};
      $changed{$c} = $t;                                                        # Last time we changed this gate
     }
   }

  confess "Out of time after $T steps";                                         # Not enough steps available
 }

#-------------------------------------------------------------------------------
# Export
#-------------------------------------------------------------------------------

use Exporter qw(import);

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

# containingFolder

@ISA          = qw(Exporter);
@EXPORT       = qw();
@EXPORT_OK    = qw(connectBits connectWords n nn setBits setWords);
%EXPORT_TAGS = (all=>[@EXPORT, @EXPORT_OK]);

#Images https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/

=pod

=encoding utf-8

=for html <p><a href="https://github.com/philiprbrenan/SiliconChip"><img src="https://github.com/philiprbrenan/SiliconChip/workflows/Test/badge.svg"></a>

=head1 Name

Silicon::Chip - Design a L<silicon|https://en.wikipedia.org/wiki/Silicon> L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> by combining L<logic gates|https://en.wikipedia.org/wiki/Logic_gate> and sub L<chips|https://en.wikipedia.org/wiki/Integrated_circuit>.

=head1 Synopsis

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

=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/Equals4.svg">

Other circuit diagrams can be seen in folder: L<lib/Silicon/svg|https://github.com/philiprbrenan/SiliconChip/tree/main/lib/Silicon/svg>

=head1 Description

Design a L<silicon|https://en.wikipedia.org/wiki/Silicon> L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> by combining L<logic gates|https://en.wikipedia.org/wiki/Logic_gate> and sub L<chips|https://en.wikipedia.org/wiki/Integrated_circuit>.


Version 20231103.


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Construct

Construct a L<Silicon|https://en.wikipedia.org/wiki/Silicon> L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> using standard L<logic gates|https://en.wikipedia.org/wiki/Logic_gate>, components and sub chips combined via buses.

=head2 newChip (%options)

Create a new L<chip|https://en.wikipedia.org/wiki/Integrated_circuit>.

     Parameter  Description
  1  %options   Options

B<Example:>


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
  

=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/oneZero.svg">
  
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
  

=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/Equals.svg">
  

=head2 gate($chip, $type, $output, $input1, $input2)

A L<logic gate|https://en.wikipedia.org/wiki/Logic_gate> chosen from B<and|continue|gt|input|lt|nand|nor|not|nxor|one|or|output|xor|zero>.  The gate type can be used as a method name, so B<-E<gt>gate("and",> can be reduced to B<-E<gt>and(>.

     Parameter  Description
  1  $chip      Chip
  2  $type      Gate type
  3  $output    Output name
  4  $input1    Input from another gate
  5  $input2    Input from another gate

B<Example:>


  
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
  

=head2 Buses

A bus is an array of bits or an array of arrays of bits

=head3 Bits

An array of bits that can be manipulated via one name.

=head4 bits($chip, $name, $bits, $value, %options)

Create a bus set to a specified number.

     Parameter  Description
  1  $chip      Chip
  2  $name      Name of bus
  3  $bits      Width in bits of bus
  4  $value     Value of bus
  5  %options   Options

B<Example:>


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
  

=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/bits.svg">
  

=head4 inputBits   ($chip, $name, $bits, %options)

Create an B<input> bus made of bits.

     Parameter  Description
  1  $chip      Chip
  2  $name      Name of bus
  3  $bits      Width in bits of bus
  4  %options   Options

B<Example:>


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
    my $s = $o->simulate({%d}, svg=>q(svg/not));
    is_deeply($s->bitsToInteger('B', $W), 0b11101001);
   }
  

=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/not.svg">
  

=head4 outputBits  ($chip, $name, $input, $bits, %options)

Create an B<output> bus made of bits.

     Parameter  Description
  1  $chip      Chip
  2  $name      Name of bus
  3  $input     Name of inputs
  4  $bits      Width in bits of bus
  5  %options   Options

B<Example:>


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
    my $s = $o->simulate({%d}, svg=>q(svg/not));
    is_deeply($s->bitsToInteger('B', $W), 0b11101001);
   }
  

=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/not.svg">
  
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
  
    is_deeply($s->bitsToInteger ('Or',  $W),  0b1110);
    is_deeply($s->bitsToInteger ('OrX', $B),  0b11);
    is_deeply([$s->wordsToInteger('N',  @B)], [3, 2, 1, 0]);
   }
  

=head4 notBits ($chip, $name, $input, $bits, %options)

Create a B<not> bus made of bits.

     Parameter  Description
  1  $chip      Chip
  2  $name      Name of bus
  3  $input     Name of inputs
  4  $bits      Width in bits of bus
  5  %options   Options

B<Example:>


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
    my $s = $o->simulate({%d}, svg=>q(svg/not));
    is_deeply($s->bitsToInteger('B', $W), 0b11101001);
   }
  

=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/not.svg">
  

=head4 andBits ($chip, $name, $input, $bits, %options)

B<and> a bus made of bits.

     Parameter  Description
  1  $chip      Chip
  2  $name      Name of bus
  3  $input     Name of inputs
  4  $bits      Width in bits of bus
  5  %options   Options

B<Example:>


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
    my $s = $c->simulate({%d}, svg=>q(svg/andOrBits));
  
    is_deeply($s->values->{And},  0);
    is_deeply($s->values->{Or},   1);
    is_deeply($s->values->{nAnd}, 1);
    is_deeply($s->values->{nOr},  0);
   }
  

=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/andOrBits.svg">
  

=head4 nandBits($chip, $name, $input, $bits, %options)

B<nand> a bus made of bits.

     Parameter  Description
  1  $chip      Chip
  2  $name      Name of bus
  3  $input     Name of inputs
  4  $bits      Width in bits of bus
  5  %options   Options

B<Example:>


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
    my $s = $c->simulate({%d}, svg=>q(svg/andOrBits));
  
    is_deeply($s->values->{And},  0);
    is_deeply($s->values->{Or},   1);
    is_deeply($s->values->{nAnd}, 1);
    is_deeply($s->values->{nOr},  0);
   }
  

=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/andOrBits.svg">
  

=head4 orBits  ($chip, $name, $input, $bits, %options)

B<or> a bus made of bits.

     Parameter  Description
  1  $chip      Chip
  2  $name      Name of bus
  3  $input     Name of inputs
  4  $bits      Width in bits of bus
  5  %options   Options

B<Example:>


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
    my $s = $c->simulate({%d}, svg=>q(svg/andOrBits));
  
    is_deeply($s->values->{And},  0);
    is_deeply($s->values->{Or},   1);
    is_deeply($s->values->{nAnd}, 1);
    is_deeply($s->values->{nOr},  0);
   }
  

=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/andOrBits.svg">
  

=head4 norBits ($chip, $name, $input, $bits, %options)

B<nor> a bus made of bits.

     Parameter  Description
  1  $chip      Chip
  2  $name      Name of bus
  3  $input     Name of inputs
  4  $bits      Width in bits of bus
  5  %options   Options

B<Example:>


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
    my $s = $c->simulate({%d}, svg=>q(svg/andOrBits));
  
    is_deeply($s->values->{And},  0);
    is_deeply($s->values->{Or},   1);
    is_deeply($s->values->{nAnd}, 1);
    is_deeply($s->values->{nOr},  0);
   }
  

=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/andOrBits.svg">
  

=head3 Words

An array of arrays of bits that can be manipulated via one name.

=head4 inputWords  ($chip, $name, $words, $bits, %options)

Create an B<input> bus made of words.

     Parameter  Description
  1  $chip      Chip
  2  $name      Name of bus
  3  $words     Width in words of bus
  4  $bits      Width in bits of each word on bus
  5  %options   Options

B<Example:>


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
  

=head4 outputWords ($chip, $name, $input, $words, $bits, %options)

Create an B<output> bus made of words.

     Parameter  Description
  1  $chip      Chip
  2  $name      Name of bus
  3  $input     Name of inputs
  4  $words     Width in words of bus
  5  $bits      Width in bits of each word on bus
  6  %options   Options

B<Example:>


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
  

=head4 notWords($chip, $name, $input, $words, $bits, %options)

Create a B<not> bus made of words.

     Parameter  Description
  1  $chip      Chip
  2  $name      Name of bus
  3  $input     Name of inputs
  4  $words     Width in words of bus
  5  $bits      Width in bits of each word on bus
  6  %options   Options

B<Example:>


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
  
    is_deeply($s->bitsToInteger ('Or',  $W),  0b1110);
    is_deeply($s->bitsToInteger ('OrX', $B),  0b11);
    is_deeply([$s->wordsToInteger('N',  @B)], [3, 2, 1, 0]);
   }
  

=head4 andWords($chip, $name, $input, $words, $bits, %options)

B<and> a bus made of words to produce a single word.

     Parameter  Description
  1  $chip      Chip
  2  $name      Name of bus
  3  $input     Name of inputs
  4  $words     Width in words of bus
  5  $bits      Width in bits of each word on bus
  6  %options   Options

B<Example:>


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
  
    is_deeply($s->bitsToInteger ('Or',  $W),  0b1110);
    is_deeply($s->bitsToInteger ('OrX', $B),  0b11);
    is_deeply([$s->wordsToInteger('N',  @B)], [3, 2, 1, 0]);
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
  

=head4 andWordsX   ($chip, $name, $input, $words, $bits, %options)

B<and> a bus made of words by and-ing the corresponding bits in each word to make a single word.

     Parameter  Description
  1  $chip      Chip
  2  $name      Name of bus
  3  $input     Name of inputs
  4  $words     Width in words of bus
  5  $bits      Width in bits of each word on bus
  6  %options   Options

B<Example:>


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
  
    is_deeply($s->bitsToInteger ('Or',  $W),  0b1110);
    is_deeply($s->bitsToInteger ('OrX', $B),  0b11);
    is_deeply([$s->wordsToInteger('N',  @B)], [3, 2, 1, 0]);
   }
  

=head4 orWords ($chip, $name, $input, $words, $bits, %options)

B<or> a bus made of words to produce a single word.

     Parameter  Description
  1  $chip      Chip
  2  $name      Name of bus
  3  $input     Name of inputs
  4  $words     Width in words of bus
  5  $bits      Width in bits of each word on bus
  6  %options   Options

B<Example:>


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
  
    is_deeply($s->bitsToInteger ('Or',  $W),  0b1110);
    is_deeply($s->bitsToInteger ('OrX', $B),  0b11);
    is_deeply([$s->wordsToInteger('N',  @B)], [3, 2, 1, 0]);
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
  

=head4 orWordsX($chip, $name, $input, $words, $bits, %options)

B<or> a bus made of words by or-ing the corresponding bits in each word to make a single word.

     Parameter  Description
  1  $chip      Chip
  2  $name      Name of bus
  3  $input     Name of inputs
  4  $words     Width in words of bus
  5  $bits      Width in bits of each word on bus
  6  %options   Options

B<Example:>


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
  
    is_deeply($s->bitsToInteger ('Or',  $W),  0b1110);
    is_deeply($s->bitsToInteger ('OrX', $B),  0b11);
    is_deeply([$s->wordsToInteger('N',  @B)], [3, 2, 1, 0]);
   }
  

=head2 Install

Install a chip within a chip as a sub chip.

=head3 install ($chip, $subChip, $inputs, $outputs, %options)

Install a L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> within another L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> specifying the connections between the inner and outer L<chip|https://en.wikipedia.org/wiki/Integrated_circuit>.  The same L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> can be installed multiple times as each L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> description is read only.

     Parameter  Description
  1  $chip      Outer chip
  2  $subChip   Inner chip
  3  $inputs    Inputs of inner chip to to outputs of outer chip
  4  $outputs   Outputs of inner chip to inputs of outer chip
  5  %options   Options

B<Example:>


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
  

=head1 Visualize

Visualize the L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> in various ways.

=head2 dumpGates   ($chip, %options)

Dump the L<logic gates|https://en.wikipedia.org/wiki/Logic_gate> present on a L<chip|https://en.wikipedia.org/wiki/Integrated_circuit>.

     Parameter  Description
  1  $chip      Chip
  2  %options   Gates

=head2 Silicon::Chip::Simulation::print($sim, %options)

Print simulation results as text.

     Parameter  Description
  1  $sim       Simulation
  2  %options   Options

B<Example:>


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
   }
  

=head2 svgGates($chip, %options)

Dump the L<logic gates|https://en.wikipedia.org/wiki/Logic_gate> on a L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> as an L<Scalar Vector Graphics|https://en.wikipedia.org/wiki/Scalable_Vector_Graphics> drawing to help visualize the structure of the L<chip|https://en.wikipedia.org/wiki/Integrated_circuit>.

     Parameter  Description
  1  $chip      Chip
  2  %options   Options

=head2 Silicon::Chip::Simulation::printSvg ($sim, %options)

Print simulation results as svg.

     Parameter  Description
  1  $sim       Simulation
  2  %options   Options

B<Example:>


  if (1)                                                                          
   {my $c = Silicon::Chip::newChip(title=>"And gate");
    $c->input ("i1");
    $c->input ("i2");
    $c->and   ("and1", [qw(i1 i2)]);
    $c->output("o", "and1");
    my $s = $c->simulate({i1=>1, i2=>1});
  
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
  

=head1 Basic Circuits

Some well known basic circuits.

=head2 n   ($c, $i)

Gate name from single index.

     Parameter  Description
  1  $c         Gate name
  2  $i         Bit number

B<Example:>


  if (1)                                                                           
  
   {is_deeply( n(a,1),   "a_1");  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply(nn(a,1,2), "a_1_2");
   }
  

=head2 nn  ($c, $i, $j)

Gate name from double index.

     Parameter  Description
  1  $c         Gate name
  2  $i         Word number
  3  $j         Bit number

B<Example:>


  if (1)                                                                           
   {is_deeply( n(a,1),   "a_1");
  
    is_deeply(nn(a,1,2), "a_1_2");  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

   }
  

=head2 Comparisons

Compare unsigned binary integers of specified bit widths.

=head3 compareEq   ($chip, $output, $a, $b, $bits, %options)

Compare two unsigned binary integers of a specified width returning B<1> if they are equal else B<0>.

     Parameter  Description
  1  $chip      Chip
  2  $output    Name of component also the output bus
  3  $a         First integer
  4  $b         Second integer
  5  $bits      Options
  6  %options

B<Example:>


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
  

=head3 compareGt   ($chip, $output, $a, $b, $bits, %options)

Compare two unsigned binary integers of specified width and return B<1> if the first integer is more than B<b> else B<0>.

     Parameter  Description
  1  $chip      Chip
  2  $output    Name of component also the output bus
  3  $a         First integer
  4  $b         Second integer
  5  $bits      Options
  6  %options

B<Example:>


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
  

=head3 compareLt   ($chip, $output, $a, $b, $bits, %options)

Compare two unsigned binary integers B<a>, B<b> of a specified width. Output B<out> is B<1> if B<a> is less than B<b> else B<0>.

     Parameter  Description
  1  $chip      Chip
  2  $output    Name of component also the output bus
  3  $a         First integer
  4  $b         Second integer
  5  $bits      Options
  6  %options

B<Example:>


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
  

=head3 chooseFromTwoWords  ($chip, $output, $a, $b, $choose, $bits, %options)

Choose one of two words based on a bit.  The first word is chosen if the bit is B<0> otherwise the second word is chosen.

     Parameter  Description
  1  $chip      Chip
  2  $output    Name of component also the chosen word
  3  $a         The first word
  4  $b         The second word
  5  $choose    The choosing bit
  6  $bits      The width of the words in bits
  7  %options   Options

B<Example:>


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
  
  
    my $s = $c->simulate({%a, %b, c=>1}, svg=>q(svg/chooseFromTwoWords));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply($s->steps,               4);
    is_deeply($s->bitsToInteger('out', $B), 0b1100);
  
    my $t = $c->simulate({%a, %b, c=>0});
    is_deeply($t->steps,               4);
    is_deeply($t->bitsToInteger('out', $B), 0b0011);
   }
  

=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/chooseFromTwoWords.svg">
  

=head3 enableWord  ($chip, $output, $a, $enable, $bits, %options)

Output a word or zeros depending on a choice bit.  The first word is chosen if the choice bit is B<1> otherwise all zeroes are chosen.

     Parameter  Description
  1  $chip      Chip
  2  $output    Name of component also the chosen word
  3  $a         The first word
  4  $enable    The second word
  5  $bits      The choosing bit
  6  %options   The width of the words in bits

B<Example:>


  if (1)                                                                          
   {my $B = 4;
  
    my $c = newChip();
       $c->inputBits ('a',       $B);                                             # Word
       $c->input     ('c');                                                       # Choice bit
  
       $c->enableWord(qw(o a c), $B);                                             # Generate gates  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       $c->outputBits(qw(out o), $B);                                             # Result
  
    my %a = setBits('a', $B, 3);
  
  
    my $s = $c->simulate({%a, c=>1}, svg=>q(svg/enableWord));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply($s->steps,               4);
    is_deeply($s->bitsToInteger('out', $B), 3);
  
    my $t = $c->simulate({%a, c=>0});
    is_deeply($t->steps,               4);
    is_deeply($t->bitsToInteger('out', $B), 0);
   }
  

=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/enableWord.svg">
  

=head2 Masks

Point masks and monotone masks. A point mask has a single B<1> in a sea of B<0>s as in B<00100>.  A monotone mask has zero or more B<0>s followed by all B<1>s as in: B<00111>.

=head3 pointMaskToInteger  ($chip, $output, $input, $bits, %options)

Convert a mask B<i> known to have at most a single bit on - also known as a B<point mask> - to an output number B<a> representing the location in the mask of the bit set to B<1>. If no such bit exists in the point mask then output number B<a> is B<0>.

     Parameter  Description
  1  $chip      Chip
  2  $output    Output name
  3  $input     Input mask
  4  $bits      Number of bits in mask
  5  %options   Options

B<Example:>


  if (1)                                                                          
   {my $B = 4;
    my $N = 2**$B-1;
  
    my $c = Silicon::Chip::newChip(title=>"$B bits point mask to integer");
  
    $c->inputBits         (qw(    i), $N);                                        # Mask with no more than one bit on
  
    $c->pointMaskToInteger(qw(o   i), $B);                                        # Convert  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    $c->outputBits        (qw(out o), $B);                                        # Mask with no more than one bit on
  
    for my $i(0..$N)                                                              # Each position of mask
     {my %i = setBits('i', $N, $i ? 1<<($i-1) : 0);                               # Point in each position with zero representing no position
      my $s = $c->simulate(\%i, $i == 5 ? (svg=>"svg/point$B") : ());
      is_deeply($s->steps, 2);
      my %o = $s->values->%*;                                                     # Output bits
      my $n = eval join '', '0b', map {$o{n(o,$_)}} reverse 1..$B;                # Output bits as number
      is_deeply($n, $i);
     }
   }
  

=head3 integerToPointMask  ($chip, $output, $input, $bits, %options)

Convert an integer B<i> of specified width to a point mask B<m>. If the input integer is B<0> then the mask is all zeroes as well.

     Parameter  Description
  1  $chip      Chip
  2  $output    Output name
  3  $input     Input mask
  4  $bits      Number of bits in mask
  5  %options   Options

B<Example:>


  if (1)                                                                          
   {my $B = 3;
    my $N = 2**$B-1;
  
    my $c = Silicon::Chip::newChip
             (title=>"$B bit integer to $N bits monotone mask");
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
  

=head3 monotoneMaskToInteger   ($chip, $output, $input, $bits, %options)

Convert a monotone mask B<i> to an output number B<r> representing the location in the mask of the bit set to B<1>. If no such bit exists in the point then output in B<r> is B<0>.

     Parameter  Description
  1  $chip      Chip
  2  $output    Output name
  3  $input     Input mask
  4  $bits      Number of bits in mask
  5  %options   Options

B<Example:>


  if (1)                                                                          
   {my $B = 4;
    my $N = 2**$B-1;
  
    my $c = Silicon::Chip::newChip
             (title=>"$N bits monotone mask to $B bit integer");
       $c->inputBits            ('i',     $N);
  
       $c->monotoneMaskToInteger(qw(m i), $B);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       $c->outputBits           (qw(o m), $B);
  
    for my $i(0..$N-1)                                                            # Each monotone mask
     {my %i = setBits('i', $N, $i > 0 ? 1<<$i-1 : 0);
      my $s = $c->simulate(\%i,
  
        $i == 5 ? (svg=>"svg/monotoneMaskToInteger$B") : ());  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
      is_deeply($s->steps, 4);
      is_deeply($s->bitsToInteger('m', $B), $i);
     }
   }
  

=head3 monotoneMaskToPointMask ($chip, $output, $input, $bits, %options)

Convert a monotone mask B<i> to a point mask B<o> representing the location in the mask of the first bit set to B<1>. If the monotone mask is all B<0>s then point mask is too.

     Parameter  Description
  1  $chip      Chip
  2  $output    Output name
  3  $input     Input mask
  4  $bits      Number of bits in mask
  5  %options   Options

B<Example:>


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
  

=head3 integerToMonotoneMask   ($chip, $output, $input, $bits, %options)

Convert an integer B<i> of specified width to a monotone mask B<m>. If the input integer is B<0> then the mask is all zeroes.  Otherwise the mask has B<i-1> leading zeroes followed by all ones thereafter.

     Parameter  Description
  1  $chip      Chip
  2  $output    Output name
  3  $input     Input mask
  4  $bits      Number of bits in mask
  5  %options   Options

B<Example:>


  if (1)                                                                          
   {my $B = 4;
    my $N = 2**$B-1;
  
    my $c = Silicon::Chip::newChip
             (title=>"$B bit integer to $N bit monotone mask");
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
  

=head3 chooseWordUnderMask ($chip, $output, $input, $mask, $words, $bits, %options)

Choose one of a specified number of words B<w>, each of a specified width, using a point mask B<m> placing the selected word in B<o>.  If no word is selected then B<o> will be zero.

     Parameter  Description
  1  $chip      Chip
  2  $output    Output
  3  $input     Inputs
  4  $mask      Mask
  5  $words     Number of words
  6  $bits      Number of bits per word
  7  %options   Options

B<Example:>


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
  

=head3 findWord($chip, $output, $key, $words, $bits, %options)

Choose one of a specified number of words B<w>, each of a specified width, using a key B<k>.  Return a point mask B<o> indicating the locations of the key if found or or a mask equal to all zeroes if the key is not present.

     Parameter  Description
  1  $chip      Chip
  2  $output    Found point mask
  3  $key       Key
  4  $words     Words to search
  5  $bits      Number of bits per key
  6  %options   Options

B<Example:>


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
  
      my $s = $c->simulate({%k, %w}, $k == 3 ? (svg=>q(svg/findWord)) : ());  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply($s->steps, 3);
      is_deeply($s->bitsToInteger('M', $W),$k ? 2**($W-$k) : 0);
     }
   }
  

=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/findWord.svg">
  

=head1 Simulate

Simulate the behavior of the L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> given a set of values on its input gates.

=head2 setBits ($name, $bits, $value)

Set an array of input gates to a number prior to running a simulation.

     Parameter  Description
  1  $name      Name of input gates
  2  $bits      Number of bits in each array element
  3  $value     Number to set to

B<Example:>


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
  
    my $t = $c->simulate({%a, %b, n(a,2)=>1}, svg=>q(svg/Compare));               # Svg drawing of layout
    is_deeply($t->values->{out}, 1);
   }
  

=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/Compare.svg">
  
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
  

=head2 setWords($name, $words, $bits, @values)

Set an array of arrays of gates to an array of numbers prior to running a simulation.

     Parameter  Description
  1  $name      Name of input gates
  2  $words     Number of arrays
  3  $bits      Number of bits in each array element
  4  @values    Numbers to set to

B<Example:>


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
  

=head2 connectBits ($oc, $o, $ic, $i, $bits, %options)

Create a connection list connecting a set of output bits on the one chip to a set of input bits on another chip.

     Parameter  Description
  1  $oc        First chip
  2  $o         Name of gates on first chip
  3  $ic        Second chip
  4  $i         Names of gates on second chip
  5  $bits      Number of bits to connect
  6  %options   Options

B<Example:>


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
  

=head2 connectWords($oc, $o, $ic, $i, $words, $bits, %options)

Create a connection list connecting a set of words on the outer chip to a set of words on the inner chip.

     Parameter  Description
  1  $oc        First chip
  2  $o         Name of gates on first chip
  3  $ic        Second chip
  4  $i         Names of gates on second chip
  5  $words     Number of words to connect
  6  $bits      Options
  7  %options

B<Example:>


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
  

=head2 Silicon::Chip::Simulation::bitsToInteger($simulation, $output, $bits, %options)

Represent the state of bits in the simulation results as an unsigned binary integer.

     Parameter    Description
  1  $simulation  Chip
  2  $output      Name of gates on bus
  3  $bits        Width in bits of bus
  4  %options     Options

B<Example:>


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
    my $s = $o->simulate({%d}, svg=>q(svg/not));
    is_deeply($s->bitsToInteger('B', $W), 0b11101001);
   }
  

=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/svg/not.svg">
  

=head2 Silicon::Chip::Simulation::wordsToInteger   ($simulation, $output, $words, $bits, %options)

Represent the state of words in the simulation results as an array of unsigned binary integer.

     Parameter    Description
  1  $simulation  Chip
  2  $output      Name of gates on bus
  3  $words       Number of words
  4  $bits        Width in bits of bus
  5  %options     Options

B<Example:>


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
  

=head2 Silicon::Chip::Simulation::wordXToInteger   ($simulation, $output, $words, $bits, %options)

Represent the state of words in the simulation results as an array of unsigned binary integer.

     Parameter    Description
  1  $simulation  Chip
  2  $output      Name of gates on bus
  3  $words       Number of words
  4  $bits        Width in bits of bus
  5  %options     Options

B<Example:>


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
  

=head2 simulate($chip, $inputs, %options)

Simulate the action of the L<logic gates|https://en.wikipedia.org/wiki/Logic_gate> on a L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> for a given set of inputs until the output value of each L<logic gate|https://en.wikipedia.org/wiki/Logic_gate> stabilizes.

     Parameter  Description
  1  $chip      Chip
  2  $inputs    Hash of input names to values
  3  %options   Options

B<Example:>


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
  


=head1 Hash Definitions




=head2 Silicon::Chip Definition


Chip description




=head3 Output fields


=head4 gateSeq

Gate sequence number - this allows us to display the gates in the order they were defined ti simplify the understanding of drawn layouts

=head4 gates

Gates in chip

=head4 installs

Chips installed within the chip

=head4 name

Name of chip

=head4 title

Title if known



=head1 Private Methods

=head2 AUTOLOAD($chip, @options)

Autoload by L<logic gate|https://en.wikipedia.org/wiki/Logic_gate> name to provide a more readable way to specify the L<logic gates|https://en.wikipedia.org/wiki/Logic_gate> on a L<chip|https://en.wikipedia.org/wiki/Integrated_circuit>.

     Parameter  Description
  1  $chip      Chip
  2  @options   Options


=head1 Index


1 L<andBits|/andBits> - B<and> a bus made of bits.

2 L<andWords|/andWords> - B<and> a bus made of words to produce a single word.

3 L<andWordsX|/andWordsX> - B<and> a bus made of words by and-ing the corresponding bits in each word to make a single word.

4 L<AUTOLOAD|/AUTOLOAD> - Autoload by L<logic gate|https://en.wikipedia.org/wiki/Logic_gate> name to provide a more readable way to specify the L<logic gates|https://en.wikipedia.org/wiki/Logic_gate> on a L<chip|https://en.wikipedia.org/wiki/Integrated_circuit>.

5 L<bits|/bits> - Create a bus set to a specified number.

6 L<chooseFromTwoWords|/chooseFromTwoWords> - Choose one of two words based on a bit.

7 L<chooseWordUnderMask|/chooseWordUnderMask> - Choose one of a specified number of words B<w>, each of a specified width, using a point mask B<m> placing the selected word in B<o>.

8 L<compareEq|/compareEq> - Compare two unsigned binary integers of a specified width returning B<1> if they are equal else B<0>.

9 L<compareGt|/compareGt> - Compare two unsigned binary integers of specified width and return B<1> if the first integer is more than B<b> else B<0>.

10 L<compareLt|/compareLt> - Compare two unsigned binary integers B<a>, B<b> of a specified width.

11 L<connectBits|/connectBits> - Create a connection list connecting a set of output bits on the one chip to a set of input bits on another chip.

12 L<connectWords|/connectWords> - Create a connection list connecting a set of words on the outer chip to a set of words on the inner chip.

13 L<dumpGates|/dumpGates> - Dump the L<logic gates|https://en.wikipedia.org/wiki/Logic_gate> present on a L<chip|https://en.wikipedia.org/wiki/Integrated_circuit>.

14 L<enableWord|/enableWord> - Output a word or zeros depending on a choice bit.

15 L<findWord|/findWord> - Choose one of a specified number of words B<w>, each of a specified width, using a key B<k>.

16 L<gate|/gate> - A L<logic gate|https://en.wikipedia.org/wiki/Logic_gate> chosen from B<and|continue|gt|input|lt|nand|nor|not|nxor|one|or|output|xor|zero>.

17 L<inputBits|/inputBits> - Create an B<input> bus made of bits.

18 L<inputWords|/inputWords> - Create an B<input> bus made of words.

19 L<install|/install> - Install a L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> within another L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> specifying the connections between the inner and outer L<chip|https://en.wikipedia.org/wiki/Integrated_circuit>.

20 L<integerToMonotoneMask|/integerToMonotoneMask> - Convert an integer B<i> of specified width to a monotone mask B<m>.

21 L<integerToPointMask|/integerToPointMask> - Convert an integer B<i> of specified width to a point mask B<m>.

22 L<monotoneMaskToInteger|/monotoneMaskToInteger> - Convert a monotone mask B<i> to an output number B<r> representing the location in the mask of the bit set to B<1>.

23 L<monotoneMaskToPointMask|/monotoneMaskToPointMask> - Convert a monotone mask B<i> to a point mask B<o> representing the location in the mask of the first bit set to B<1>.

24 L<n|/n> - Gate name from single index.

25 L<nandBits|/nandBits> - B<nand> a bus made of bits.

26 L<newChip|/newChip> - Create a new L<chip|https://en.wikipedia.org/wiki/Integrated_circuit>.

27 L<nn|/nn> - Gate name from double index.

28 L<norBits|/norBits> - B<nor> a bus made of bits.

29 L<notBits|/notBits> - Create a B<not> bus made of bits.

30 L<notWords|/notWords> - Create a B<not> bus made of words.

31 L<orBits|/orBits> - B<or> a bus made of bits.

32 L<orWords|/orWords> - B<or> a bus made of words to produce a single word.

33 L<orWordsX|/orWordsX> - B<or> a bus made of words by or-ing the corresponding bits in each word to make a single word.

34 L<outputBits|/outputBits> - Create an B<output> bus made of bits.

35 L<outputWords|/outputWords> - Create an B<output> bus made of words.

36 L<pointMaskToInteger|/pointMaskToInteger> - Convert a mask B<i> known to have at most a single bit on - also known as a B<point mask> - to an output number B<a> representing the location in the mask of the bit set to B<1>.

37 L<setBits|/setBits> - Set an array of input gates to a number prior to running a simulation.

38 L<setWords|/setWords> - Set an array of arrays of gates to an array of numbers prior to running a simulation.

39 L<Silicon::Chip::Simulation::bitsToInteger|/Silicon::Chip::Simulation::bitsToInteger> - Represent the state of bits in the simulation results as an unsigned binary integer.

40 L<Silicon::Chip::Simulation::print|/Silicon::Chip::Simulation::print> - Print simulation results as text.

41 L<Silicon::Chip::Simulation::printSvg|/Silicon::Chip::Simulation::printSvg> - Print simulation results as svg.

42 L<Silicon::Chip::Simulation::wordsToInteger|/Silicon::Chip::Simulation::wordsToInteger> - Represent the state of words in the simulation results as an array of unsigned binary integer.

43 L<Silicon::Chip::Simulation::wordXToInteger|/Silicon::Chip::Simulation::wordXToInteger> - Represent the state of words in the simulation results as an array of unsigned binary integer.

44 L<simulate|/simulate> - Simulate the action of the L<logic gates|https://en.wikipedia.org/wiki/Logic_gate> on a L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> for a given set of inputs until the output value of each L<logic gate|https://en.wikipedia.org/wiki/Logic_gate> stabilizes.

45 L<svgGates|/svgGates> - Dump the L<logic gates|https://en.wikipedia.org/wiki/Logic_gate> on a L<chip|https://en.wikipedia.org/wiki/Integrated_circuit> as an L<Scalar Vector Graphics|https://en.wikipedia.org/wiki/Scalable_Vector_Graphics> drawing to help visualize the structure of the L<chip|https://en.wikipedia.org/wiki/Integrated_circuit>.

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Silicon::Chip

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2023 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut



#D0 Tests                                                                       # Tests and examples
goto finish if caller;                                                          # Skip testing if we are being called as a module
clearFolder(q(svg), 99);                                                        # Clear the output svg folder
eval "use Test::More tests=>521;";
eval "Test::More->builder->output('/dev/null');" if -e q(/home/phil/);
eval {goto latest};

#svg https://raw.githubusercontent.com/philiprbrenan/SiliconChip/main/lib/Silicon/

if (1)                                                                          #Tn #Tnn
 {is_deeply( n(a,1),   "a_1");
  is_deeply(nn(a,1,2), "a_1_2");
 }

if (1)                                                                          # Unused output
 {my $c = Silicon::Chip::newChip;
  $c->input( "i1");
  eval {$c->simulate({i1=>1})};
  ok($@ =~ m(Output from gate 'i1' is never used)i);
 }

if (1)                                                                          # Gate already specified
 {my $c = Silicon::Chip::newChip;
        $c->input("i1");
  eval {$c->input("i1")};
  ok($@ =~ m(Gate: 'i1' has already been specified));
 }

#latest:;
if (1)                                                                          # Check all inputs have values
 {my $c = Silicon::Chip::newChip;
  $c->input ("i1");
  $c->input ("i2");
  $c->and   ("and", [qw(i1 i2)]);
  $c->output("o",   q(and));
  eval {$c->simulate({i1=>1, i22=>1})};
  ok($@ =~ m(No input value for input gate: i2)i);
 }

#latest:;
if (1)                                                                          # Check each input to each gate receives output from another gate
 {my $c = Silicon::Chip::newChip;
  $c->input("i1");
  $c->input("i2");
  $c->and  ("and1", [qw(i1 i2)]);
  $c->output( "o", q(an1));
  eval {$c->simulate({i1=>1, i2=>1})};
  ok($@ =~ m(No output driving input 'an1' on 'output' gate 'o')i);
 }

#latest:;
if (1)                                                                          #Tzero
 {my $c = Silicon::Chip::newChip;
  $c->zero  ("z");
  $c->output("o", "z");
  my $s = $c->simulate({}, svg=>q(svg/zero));
  is_deeply($s->steps      , 2);
  is_deeply($s->values->{o}, 0);
 }

#latest:;
if (1)                                                                          #Tone
 {my $c = Silicon::Chip::newChip;
  $c->one ("o");
  $c->output("O", "o");
  my $s = $c->simulate({}, svg=>q(svg/one));
  is_deeply($s->steps      , 2);
  is_deeply($s->values->{O}, 1);
 }

#latest:;
if (1)                                                                          #TnewChip
 {my $c = Silicon::Chip::newChip;
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

#latest:;
if (1)                                                                          #Tbits
 {my $N = 4;
  for my $i(0..2**$N-1)
   {my $c = Silicon::Chip::newChip;
    $c->bits      ("c",      $N, $i);
    $c->outputBits("o", "c", $N);
    my $s = $c->simulate({}, $i == 3 ? (svg=>q(svg/bits)) : ());
    is_deeply($s->steps       , 2);
    is_deeply($s->bitsToInteger("o", $N), $i);
   }
 }

#latest:;
if (1)                                                                          #TnewChip # Single AND gate
 {my $c = Silicon::Chip::newChip;
  $c->input ("i1");
  $c->input ("i2");
  $c->and   ("and1", [qw(i1 i2)]);
  $c->output("o", "and1");
  my $s = $c->simulate({i1=>1, i2=>1});
  ok($s->steps          == 2);
  ok($s->values->{and1} == 1);
 }

#latest:;
if (1)                                                                          #TSilicon::Chip::Simulation::print
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
 }

#latest:;
if (1)                                                                          #TSilicon::Chip::Simulation::printSvg
 {my $c = Silicon::Chip::newChip(title=>"And gate");
  $c->input ("i1");
  $c->input ("i2");
  $c->and   ("and1", [qw(i1 i2)]);
  $c->output("o", "and1");
  my $s = $c->simulate({i1=>1, i2=>1});

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

#latest:;
if (1)                                                                          # Three AND gates in a tree
 {my $c = Silicon::Chip::newChip;
  $c->input( "i11");
  $c->input( "i12");
  $c->and(    "and1", [qw(i11 i12)]);
  $c->input( "i21");
  $c->input( "i22");
  $c->and(    "and2", [qw(i21   i22)]);
  $c->and(    "and",  [qw(and1 and2)]);
  $c->output( "o", "and");
  my $s = $c->simulate({i11=>1, i12=>1, i21=>1, i22=>1});
  ok($s->steps         == 3);
  ok($s->values->{and} == 1);
     $s = $c->simulate({i11=>1, i12=>0, i21=>1, i22=>1});
  ok($s->steps         == 3);
  ok($s->values->{and} == 0);
 }

#latest:;
if (1)                                                                          #Tgate # Two AND gates driving an OR gate
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

#latest:;
if (1)                                                                          # 4 bit equal #TnewChip
 {my $B = 4;                                                                    # Number of bits

  my $c = Silicon::Chip::newChip(title=>"$B Bit Equals");                       # Create chip

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

#latest:;
if (1)                                                                          #TsetBits # Compare two 4 bit unsigned integers 'a' > 'b' - the pins used to input 'a' must be alphabetically less than those used for 'b'
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

  my %a = setBits('a', $B, 0);                                                  # Number a
  my %b = setBits('b', $B, 0);                                                  # Number b

  my $s = $c->simulate({%a, %b, n(a,2)=>1, n(b,2)=>1});                         # Two equal numbers
  is_deeply($s->values->{out}, 0);

  my $t = $c->simulate({%a, %b, n(a,2)=>1}, svg=>q(svg/Compare));               # Svg drawing of layout
  is_deeply($t->values->{out}, 1);
 }

#latest:;
if (1)                                                                          #TcompareEq #bitsToInteger # Compare unsigned integers
 {my $B = 2;

  my $c = Silicon::Chip::newChip(name=>"eq", title=>"$B Bit Compare Equal");

  $c->inputBits($_, $B) for qw(a b);                                            # First and second numbers
  $c->compareEq(qw(o a b), $B);                                                 # Compare equals
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

#latest:;
if (1)                                                                          #TcompareGt # Compare 8 bit unsigned integers 'a' > 'b' - the pins used to input 'a' must be alphabetically less than those used for 'b'
 {my $B = 3;
  my $c = Silicon::Chip::newChip(name=>"gt", title=>"$B Bit Compare more than");

  $c->inputBits($_, $B) for qw(a b);                                            # First and second numbers
  $c->compareGt(qw(o a b), $B);                                                 # Compare more than
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

#latest:;
if (1)                                                                          #TcompareLt # Compare 8 bit unsigned integers 'a' < 'b' - the pins used to input 'a' must be alphabetically less than those used for 'b'
 {my $B = 3;
  my $c = Silicon::Chip::newChip(name=>"lt", title=>"$B Bit Compare Less Than");

  $c->inputBits($_, $B) for qw(a b);                                            # First and second numbers
  $c->compareLt(qw(o a b), $B);                                                 # Compare less than
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

#latest:;
if (1)                                                                          # Masked multiplexer: copy B bit word selected by mask from W possible locations
 {my $B = 4; my $W = 4;
  my $c = newChip;
  for my $w(1..$W)                                                              # Input words
   {$c->input("s$w");                                                           # Selection mask
    for my $b(1..$B)                                                            # Bits of input word
     {$c->input("i$w$b");
      $c->and(   "s$w$b", ["i$w$b", "s$w"]);
     }
   }
  for my $b(1..$B)                                                              # Or selected bits together to make output
   {$c->or    ("c$b", [map {"s$b$_"} 1..$W]);                                   # Combine the selected bits to make a word
    $c->output("o$b", "c$b");                                                   # Output the word selected
   }
  my $s = $c->simulate(
   {s1 =>0, s2 =>0, s3 =>1, s4 =>0,
    i11=>0, i12=>0, i13=>0, i14=>1,
    i21=>0, i22=>0, i23=>1, i24=>0,
    i31=>0, i32=>1, i33=>0, i34=>0,
    i41=>1, i42=>0, i43=>0, i44=>0});

  is_deeply([@{$s->values}{qw(o1 o2 o3 o4)}], [qw(0 0 1 0)]);                   # Number selected by mask
  is_deeply($s->steps, 3);
 }

#latest:;
if (1)                                                                          # Rename a gate
 {my $i = newChip(name=>"inner");
          $i->input ("i");
  my $n = $i->not   ("n",  "i");
          $i->output("io", "n");

  my $ci = cloneGate $i, $n;
  renameGate $i, $ci, "aaa";
  is_deeply($ci->inputs,   { n => "i" });
  is_deeply($ci->output,  "(aaa n)");
  is_deeply($ci->io, 0);
 }

#latest:;
if (1)                                                                          #Tinstall #TconnectBits # Install one chip inside another chip, specifically one chip that performs NOT is installed once to flip a value
 {my $i = newChip(name=>"not");
     $i->input (n('i', 1));
     $i->not   (n('n', 1), n('i', 1));
     $i->output(n('o', 1), n('n', 1));

  my $o = newChip(name=>"outer");
     $o->input (n('i', 1)); $o->output(n('n', 1), n('i', 1));
     $o->input (n('I', 1)); $o->output(n('N', 1), n('I', 1));

  my %i = connectBits($i, 'i', $o, 'n', 1);
  my %o = connectBits($i, 'o', $o, 'I', 1);
  $o->install($i, {%i}, {%o});
  my %d = setBits('i', 1, 1);
  my $s = $o->simulate({%d}, dumpGatesOff=>"dump/not1", svg=>"svg/not1");

  is_deeply($s->steps,  2);
  is_deeply($s->values, {"(not 1 n_1)"=>0, "i_1"=>1, "N_1"=>0 });
 }

#latest:;
if (1)                                                                          #TconnectWords # Install one chip inside another chip, specifically one chip that performs NOT is installed three times sequentially to flip a value
 {my $i = newChip(name=>"not");
     $i->input (nn('i', 1, 1));
     $i->not   (nn('n', 1, 1), nn('i', 1, 1));
     $i->output(nn('o', 1, 1), nn('n', 1, 1));

  my $o = newChip(name=>"outer");
     $o->input (nn('i', 1, 1)); $o->output(nn('n', 1, 1), nn('i', 1, 1));
     $o->input (nn('I', 1, 1)); $o->output(nn('N', 1, 1), nn('I', 1, 1));

  my %i = connectWords($i, 'i', $o, 'n', 1, 1);
  my %o = connectWords($i, 'o', $o, 'I', 1, 1);
  $o->install($i, {%i}, {%o});
  my %d = setWords('i', 1, 1, 1);
  my $s = $o->simulate({%d}, dumpGatesOff=>"dump/not1", svg=>"svg/not1");

  is_deeply($s->steps,  2);
  is_deeply($s->values, { "(not 1 n_1_1)" => 0, "i_1_1" => 1, "N_1_1" => 0 });
 }

#latest:;
if (1)                                                                          #Tsimulate
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

  my $s = $o->simulate({Oi1=>1}, dumpGatesOff=>"dump/not3", svg=>"svg/not3");
  is_deeply($s->values->{Oo}, 0);
  is_deeply($s->steps,        4);
 }

#latest:;
if (1)                                                                          #TpointMaskToInteger
 {my $B = 4;
  my $N = 2**$B-1;

  my $c = Silicon::Chip::newChip(title=>"$B bits point mask to integer");

  $c->inputBits         (qw(    i), $N);                                        # Mask with no more than one bit on
  $c->pointMaskToInteger(qw(o   i), $B);                                        # Convert
  $c->outputBits        (qw(out o), $B);                                        # Mask with no more than one bit on

  for my $i(0..$N)                                                              # Each position of mask
   {my %i = setBits('i', $N, $i ? 1<<($i-1) : 0);                               # Point in each position with zero representing no position
    my $s = $c->simulate(\%i, $i == 5 ? (svg=>"svg/point$B") : ());
    is_deeply($s->steps, 2);
    my %o = $s->values->%*;                                                     # Output bits
    my $n = eval join '', '0b', map {$o{n(o,$_)}} reverse 1..$B;                # Output bits as number
    is_deeply($n, $i);
   }
 }

#latest:;
if (1)                                                                          #TintegerToPointMask
 {my $B = 3;
  my $N = 2**$B-1;

  my $c = Silicon::Chip::newChip
           (title=>"$B bit integer to $N bits monotone mask");
     $c->inputBits         (qw(  i), $B);                                       # Input bus
     $c->integerToPointMask(qw(m i), $B);
     $c->outputBits        (qw(o m), $N);

  for my $i(0..$N)                                                              # Each position of mask
   {my %i = setBits('i', $B, $i);
    my $s = $c->simulate(\%i, $i == 5 ? (svg=>"svg/integerToMontoneMask$B"):());
    is_deeply($s->steps, 3);

    my $r = $s->bitsToInteger('o', $N);                                         # Mask values
    is_deeply($r, $i ? 1<<($i-1) : 0);                                          # Expected mask
   }
 }

#latest:;
if (1)                                                                          #TmonotoneMaskToInteger
 {my $B = 4;
  my $N = 2**$B-1;

  my $c = Silicon::Chip::newChip
           (title=>"$N bits monotone mask to $B bit integer");
     $c->inputBits            ('i',     $N);
     $c->monotoneMaskToInteger(qw(m i), $B);
     $c->outputBits           (qw(o m), $B);

  for my $i(0..$N-1)                                                            # Each monotone mask
   {my %i = setBits('i', $N, $i > 0 ? 1<<$i-1 : 0);
    my $s = $c->simulate(\%i,
      $i == 5 ? (svg=>"svg/monotoneMaskToInteger$B") : ());

    is_deeply($s->steps, 4);
    is_deeply($s->bitsToInteger('m', $B), $i);
   }
 }

#latest:;
if (1)                                                                          #TintegerToMonotoneMask
 {my $B = 4;
  my $N = 2**$B-1;

  my $c = Silicon::Chip::newChip
           (title=>"$B bit integer to $N bit monotone mask");
     $c->inputBits            ('i', $B);                                        # Input gates
     $c->integerToMonotoneMask(qw(m i), $B);
     $c->outputBits           (qw(o m), $N);                                    # Output gates

  for my $i(0..$N)                                                              # Each position of mask
   {my %i = setBits('i', $B, $i);                                               # The number to convert
    my $s = $c->simulate(\%i, $i == 2 ? (svg=>"svg/integerToMontoneMask$B"):());
    is_deeply($s->steps, 4);
    is_deeply($s->bitsToInteger('o', $N),                                       # Expected mask
      $i > 0 ? ((1<<$N)-1)>>($i-1)<<($i-1) : 0);
   }
 }

#latest:;
if (1)                                                                          #TchooseWordUnderMask #TsetBits #TsetWords
 {my $B = 3; my $W = 4;

  my $c = Silicon::Chip::newChip(title=>"Choose one of $W words of $B bits");
     $c->inputWords         ('w',       $W, $B);
     $c->inputBits          ('m',       $W);
     $c->chooseWordUnderMask(qw(W w m), $W, $B);
     $c->outputBits         (qw(o W),       $B);

  my %i = setWords('w', $W, $B, 0b000, 0b001, 0b010, 0b0100);
  my %m = setBits ('m', $W, 1<<2);                                              # Choose the third word

  my $s = $c->simulate({%i, %m}, svg=>"svg/choose_${W}_$B");

  is_deeply($s->steps, 3);
  is_deeply($s->bitsToInteger('o', $B), 0b010);
 }

#latest:;
if (1)                                                                          #TfindWord
 {my $B = 3; my $W = 2**$B-1;

  my $c = Silicon::Chip::newChip(title=>"Search $W words of $B bits");
     $c->inputBits ('k',       $B);                                             # Search key
     $c->inputWords('w',       2**$B-1, $B);                                    # Words to search
     $c->findWord  (qw(m k w), $B);                                             # Find the word
     $c->outputBits(qw(M m),   $W);                                             # Output mask

  my %w = setWords('w', $W, $B, reverse 1..$W);

  for my $k(0..$W)                                                              # Each possible key
   {my %k = setBits('k', $B, $k);
    my $s = $c->simulate({%k, %w}, $k == 3 ? (svg=>q(svg/findWord)) : ());
    is_deeply($s->steps, 3);
    is_deeply($s->bitsToInteger('M', $W),$k ? 2**($W-$k) : 0);
   }
 }

#latest:;
if (1)                                                                          #TinputBits #ToutputBits #TnotBits #TSilicon::Chip::Simulation::bitsToInteger
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
  my $s = $o->simulate({%d}, svg=>q(svg/not));
  is_deeply($s->bitsToInteger('B', $W), 0b11101001);
 }

#latest:;
if (1)                                                                          #TandBits #TorBits #TnandBits #TnorBits
 {my $W = 8;

  my $c = newChip();
     $c-> inputBits('i',         $W);
     $c->   andBits(qw(and  i),  $W);
     $c->    orBits(qw(or   i),  $W);
     $c->  nandBits(qw(nand i),  $W);
     $c->   norBits(qw(nor  i),  $W);
     $c->output    (qw(And  and));
     $c->output    (qw(Or   or));
     $c->output    (qw(nAnd nand));
     $c->output    (qw(nOr  nor));

  my %d = setBits('i', $W, 0b10110);
  my $s = $c->simulate({%d}, svg=>q(svg/andOrBits));

  is_deeply($s->values->{And},  0);
  is_deeply($s->values->{Or},   1);
  is_deeply($s->values->{nAnd}, 1);
  is_deeply($s->values->{nOr},  0);
 }

#latest:;
if (1)                                                                          #TandWords #TandWordsX #TorWords #TorWordsX #ToutputBits #TbitsToInteger #TnotWords
 {my @B = ((my $W = 4), (my $B = 2));

  my $c = newChip();
     $c->inputWords ('i',           @B);
     $c->andWords   (qw(and  i),    @B);
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

  is_deeply($s->bitsToInteger ('Or',  $W),  0b1110);
  is_deeply($s->bitsToInteger ('OrX', $B),  0b11);
  is_deeply([$s->wordsToInteger('N',  @B)], [3, 2, 1, 0]);
 }

#latest:;
if (1)                                                                          #TandWords #TorWords #TSilicon::Chip::Simulation::wordXToInteger #TSilicon::Chip::Simulation::wordsToInteger  #TinputWords #ToutputWords
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

#latest:;
if (1)                                                                          #TchooseFromTwoWords
 {my $B = 4;

  my $c = newChip();
     $c->inputBits('a', $B);                                                    # First word
     $c->inputBits('b', $B);                                                    # Second word
     $c->input    ('c');                                                        # Chooser
     $c->chooseFromTwoWords(qw(o a b c), $B);                                   # Generate gates
     $c->outputBits('out', 'o',          $B);                                   # Result

  my %a = setBits('a', $B, 0b0011);
  my %b = setBits('b', $B, 0b1100);

  my $s = $c->simulate({%a, %b, c=>1}, svg=>q(svg/chooseFromTwoWords));
  is_deeply($s->steps,               4);
  is_deeply($s->bitsToInteger('out', $B), 0b1100);

  my $t = $c->simulate({%a, %b, c=>0});
  is_deeply($t->steps,               4);
  is_deeply($t->bitsToInteger('out', $B), 0b0011);
 }

#latest:;
if (1)                                                                          #TenableWord
 {my $B = 4;

  my $c = newChip();
     $c->inputBits ('a',       $B);                                             # Word
     $c->input     ('c');                                                       # Choice bit
     $c->enableWord(qw(o a c), $B);                                             # Generate gates
     $c->outputBits(qw(out o), $B);                                             # Result

  my %a = setBits('a', $B, 3);

  my $s = $c->simulate({%a, c=>1}, svg=>q(svg/enableWord));
  is_deeply($s->steps,               4);
  is_deeply($s->bitsToInteger('out', $B), 3);

  my $t = $c->simulate({%a, c=>0});
  is_deeply($t->steps,               4);
  is_deeply($t->bitsToInteger('out', $B), 0);
 }

#latest:;
if (1)                                                                          #TmonotoneMaskToPointMask
 {my $B = 4;

  my $c = newChip();
     $c->inputBits('m', $B);                                                    # Monotone mask
     $c->monotoneMaskToPointMask(qw(o m), $B);                                  # Generate gates
     $c->outputBits('out', 'o',           $B);                                  # Point mask

  for my $i(0..$B)
   {my %m = setBits('m', $B, eval '0b'.(1 x $i).('0' x ($B-$i)));
    my $s = $c->simulate({%m});
    is_deeply($s->steps,                    2);
    is_deeply($s->bitsToInteger('out', $B), $i ? (1<<($B-1)) / (1<<($i-1)) : 0);
   }
 }

#done_testing();
finish: 1;

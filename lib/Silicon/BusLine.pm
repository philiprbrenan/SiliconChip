#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/
#-------------------------------------------------------------------------------
# Place items on a bus.
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2023
#-------------------------------------------------------------------------------
use v5.34;
package Silicon::Chip::BusLine;
our $VERSION = 20231126;
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
eval "use Test::More qw(no_plan);" unless caller;

makeDieConfess;

sub newPlace($$$$%)                                                             # New placement object
 {my ($index, $low, $high, $out, %options) = @_;                                # Index of placement on bus line, low line, high line, output line, options
  @_ >= 4 or confess "Four or more parameters";
  my $g = genHash(__PACKAGE__,                                                  # Bus Line object
    %options,                                                                   # Items the caller seeks to include in the bus line object
    index => $index,                                                            # Column along the bus of the item,
    low   => $low,                                                              # First line in the placement of this item
    high  => $high,                                                             # Last line in the placement of this item.  Item contoinues to the end fo the bus if it does not terminate any bus line otherwise it terminates at the lowest bus line used.
    out   => $out,                                                              # Index of the line containing the output of this placement
   );
 }

sub new($%)                                                                     # New bus object
 {my ($inputs, %options) = @_;                                                  # Inputs, options
  my $p = [map {newPlace(0, $_, $_, $_)} @$inputs];                             # Array of bus lines
  my $h = {map {$$inputs[$_]=>$_}  keys  @$inputs};                             # Index of bus lines
  my $g = genHash(__PACKAGE__,                                                  # Bus Line object: an array of columns, each column containing one or more items dependent on the bus lines reaching this item.
    %options,                                                                   # Items the caller seeks to include in the bus line object
    array => $inputs,                                                           # Lines reaching the current column of the bus in bus line order
    hash  => $h,                                                                # Lines on the current bus indexed by bus line name
    used  => $h,                                                                # Lines no longer accessible in the current column because they have been used by items previously placed in this column
    trace => [],                                                                # Each column of the bus
    place => {map {($_->out=>$_)} @$p},                                         # Position of each item placed on the bus
   );
  $g->newColumn;                                                                # Start a new column now that we have placed the initial inputs
 }

sub newColumn($%)                                                               # New column on the bus
 {my ($bus, %options) = @_;                                                     # Bus, options
  keys($bus->used->%*) > 0 or confess <<"END" =~ s/\n(.)/ $1/gsr;               # Prevent endless recursion on erroneous new column calls
New column pointless as the latest column is currently empty.
END

  my @i = $bus->array->@*;                                                      # Current bus lines
  $bus->array = [@i];                                                           # New set of bus lines
  my %h;                                                                        # Index bus lines
  for my $i(keys @i)
   {next unless defined(my $l = $i[$i]);
    $h{$l} = $i;
   }
  $bus->hash  = {%h};                                                           # Index of bus lines
  $bus->used  = {};                                                             # New column so nothing has been used yet
  push $bus->trace->@*, [@i];                                                   # Trace the bus lines used
  $bus
 }

sub add($$$;$%)                                                                 # Place an item across the bus. If the item does not terminate any bus lines i completes the currwent column of the vus
 {my ($bus, $out, $lines, $end, %options) = @_;                                 # Bus line, item name, array of bus lines required for item, any lines that terminate here, options
  @_ >= 3 or confess "Three or more parameters";
  $bus->hash->{$out} and confess <<"END" =~ s/\n(.)/ $1/gsr;                    # This item is not already on the bus
Item $out is already on this bus
END
  my $m; my $M;                                                                 # Minimum and maximum indices of lines straddled
  my $inUse = 0;                                                                # Checks that all the requested bus lines are free
  for my $l(@$lines)
   {(my $i = $bus->hash->{$l}) or confess <<"END" =~ s/\n(.)/ $1/gsr;           # Check each requested line is present
No such item as $l on bus.
END
    $m = $i if !defined($m) or $i < $m;                                         # Minimum index of add
    $M = $i if !defined($M) or $i > $M;                                         # Maximum index of add
   }
lll "SSSS\n", dump($m, $M, $lines, $bus->array, $bus->hash) if $options{debug};

  my @lines = $bus->array->@*;
  for my $l(@lines[$m..$M])                                                     # Each line within the range occupied by the add
   {next unless defined($l);
    $inUse++ if $bus->used->{$l};                                               # Count the lines that are being straddled by something else
   }

  $bus->newColumn if $inUse;                                                    # Create a new column if any needed line is in use

  for my $i($m..$M)                                                             # Each line within the range occupied by the add
   {my $l = $lines[$i];                                                         # Each line within the range occupied by the add
    $bus->used->{$l}++;                                                         # Mark lines as currently in use
   }
  $bus->used->{$out} = 1;                                                       # Marks the output as being used in this column of the bus line so we will ahve to go to at least the next column to use it
  my $mm = $bus->array->[$m];
  my $MM = $bus->array->[$M];
  my $c  = $bus->trace->@*;                                                     # Column on bus
  my $p = $bus->place->{$out} = newPlace($c, $mm, $MM, $out);                   # Placement on bus

  if ($end and @$end)                                                           # Lines that end here
   {my @e;                                                                      # Lines to be ended
    for my $e(@$end)                                                            # Each line to be ended
     {defined(my $i = $bus->hash->{$e}) or confess <<"END" =~ s/\n(.)/ $1/gsr;
Cannot end line: '$e' as it is not currently in use.
END
      push @e, $i;                                                              # Save location of ending index
      $bus->array->[$i] = undef;                                                # End line
      delete $bus->hash->{$e};
     }
    my $e = shift @e;                                                           # Index of first end line - use it for the output of this item
    $bus->array->[$e]   = $p->out = $out;                                       # Output from this item replaces an existing bus line
    $bus->hash ->{$out} = $e;
   }
  else                                                                          # No line ended here so we will have to widen the bus
   {my $i = $bus->array->@*;                                                    # Index of location of this item
    $bus->hash ->{$out} = $i;                                                   # Location for this item
    push $bus->array->@*, $out;                                                 # Add this item at the expected location om the expanded bus
    $bus->newColumn;                                                            # Start a new column now including the new bus line
   }

  $p                                                                            # Return placement
 }

if (1)                                                                          #Tadd #Tnew #Tadd
 {my $b = new([map{"a$_"} 1..8]);
  is_deeply($b,
{ array => ["a1" .. "a8"],
  hash  => {a1=>0, a2=>1, a3=>2, a4=>3, a5=>4, a6=>5, a7=>6, a8=>7},
  place => {a1 => {high=>"a1", index=>0, low=>"a1", out=>"a1"},
            a2 => {high=>"a2", index=>0, low=>"a2", out=>"a2"},
            a3 => {high=>"a3", index=>0, low=>"a3", out=>"a3"},
            a4 => {high=>"a4", index=>0, low=>"a4", out=>"a4"},
            a5 => {high=>"a5", index=>0, low=>"a5", out=>"a5"},
            a6 => {high=>"a6", index=>0, low=>"a6", out=>"a6"},
            a7 => {high=>"a7", index=>0, low=>"a7", out=>"a7"},
            a8 => {high=>"a8", index=>0, low=>"a8", out=>"a8"},
           },
  trace=>[["a1" .. "a8"]],
  used =>{},
});

  my $p = $b->add("b1", [qw(a2 a4 a6)], [qw(a4)]);
  is_deeply($b,
{ array=>[qw(a1 a2 a3 b1 a5 a6 a7 a8)],
  hash  => {a1=>0, a2=>1, a3=>2, a5=>4, a6=>5, a7=>6, a8=>7, b1=>3},
  place => {a1 => {high=>"a1", index=>0, low=>"a1", out=>"a1"},
            a2 => {high=>"a2", index=>0, low=>"a2", out=>"a2"},
            a3 => {high=>"a3", index=>0, low=>"a3", out=>"a3"},
            a4 => {high=>"a4", index=>0, low=>"a4", out=>"a4"},
            a5 => {high=>"a5", index=>0, low=>"a5", out=>"a5"},
            a6 => {high=>"a6", index=>0, low=>"a6", out=>"a6"},
            a7 => {high=>"a7", index=>0, low=>"a7", out=>"a7"},
            a8 => {high=>"a8", index=>0, low=>"a8", out=>"a8"},
            b1 => {high=>"a6", index=>1, low=>"a2", out=>"b1"},
           },
  trace=>[["a1" .. "a8"]],
  used  => {a2=>1, a3=>1, a4=>1, a5=>1, a6=>1, b1=>1},
});

  is_deeply($p, {high=>'a6', index=>1, low=>'a2', out=>"b1" });

  my $q = $b->add("b2", [qw(a7 a8)],    [qw(a7)]);
  is_deeply($b,
{ array=>[qw(a1 a2 a3 b1 a5 a6 b2 a8)],
  hash  => {a1=>0, a2=>1, a3=>2, a5=>4, a6=>5, a8=>7, b1=>3, b2=>6},
  place => {a1 => {high=>"a1", index=>0, low=>"a1", out=>"a1"},
            a2 => {high=>"a2", index=>0, low=>"a2", out=>"a2"},
            a3 => {high=>"a3", index=>0, low=>"a3", out=>"a3"},
            a4 => {high=>"a4", index=>0, low=>"a4", out=>"a4"},
            a5 => {high=>"a5", index=>0, low=>"a5", out=>"a5"},
            a6 => {high=>"a6", index=>0, low=>"a6", out=>"a6"},
            a7 => {high=>"a7", index=>0, low=>"a7", out=>"a7"},
            a8 => {high=>"a8", index=>0, low=>"a8", out=>"a8"},
            b1 => {high=>"a6", index=>1, low=>"a2", out=>"b1"},
            b2 => {high=>"a8", index=>1, low=>"a7", out=>"b2"},
           },
  trace=>[["a1" .. "a8"]],
  used  => {a2=>1, a3=>1, a4=>1, a5=>1, a6=>1, a7=>1, a8=>1, b1=>1, b2=>1},
});

  is_deeply($q, {high=>'a8', index=>1, low=>'a7', out=>"b2"});

  my $r = $b->add("c1", [qw(b1 b2 a8)]);
  is_deeply($b,
{ array=>[qw(a1 a2 a3 b1 a5 a6 b2 a8 c1)],
  hash  => {a1=>0, a2=>1, a3=>2, a5=>4, a6=>5, a8=>7, b1=>3, b2=>6, c1=>8},
  place => {a1 => {high=>"a1", index=>0, low=>"a1", out=>"a1"},
            a2 => {high=>"a2", index=>0, low=>"a2", out=>"a2"},
            a3 => {high=>"a3", index=>0, low=>"a3", out=>"a3"},
            a4 => {high=>"a4", index=>0, low=>"a4", out=>"a4"},
            a5 => {high=>"a5", index=>0, low=>"a5", out=>"a5"},
            a6 => {high=>"a6", index=>0, low=>"a6", out=>"a6"},
            a7 => {high=>"a7", index=>0, low=>"a7", out=>"a7"},
            a8 => {high=>"a8", index=>0, low=>"a8", out=>"a8"},
            b1 => {high=>"a6", index=>1, low=>"a2", out=>"b1"},
            b2 => {high=>"a8", index=>1, low=>"a7", out=>"b2"},
            c1 => {high=>"a8", index=>2, low=>"b1", out => "c1" },
           },
  trace=>[
             ["a1" .. "a8"],
             [qw(a1 a2 a3 b1 a5 a6 b2 a8)],
             [qw(a1 a2 a3 b1 a5 a6 b2 a8 c1)],
           ],
  used =>{},
});

  is_deeply($r, {high=>'a8', index=>2, low=>'b1', out=>"c1"});
 }

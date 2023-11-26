#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/
#-------------------------------------------------------------------------------
# Place items on a bus
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

sub new(%)                                                                      # New bus object
 {my (%options) = @_;                                                           # Options
  my $a = [];                                                                   # Array of items at rightmost end of bus imaging the bus extending from left to  right
  my $g = genHash(__PACKAGE__,                                                  # Bus Line object
    %options,                                                                   # Items the caller seeks to include in the bus line object
    array => $a,                                                                # Items on the bus at the moment indexed in addition order
    hash  => {},                                                                # Items on the bus at the moment by key
    used  => {},                                                                # Items currently in use at the end of the bus
    trace => [$a],                                                              # Trace of each bus line used
    place => {},                                                                # Position of each item placed in a straddle
   );
 }

sub newPlace($$$%)                                                              # New placement object
 {my ($index, $low, $high, %options) = @_;                                      # Index of placemtn on bus line, low line, high line, options
  @_ >= 3 or confess "Three or more parameters";
  my $g = genHash(__PACKAGE__,                                                  # Bus Line object
    %options,                                                                   # Items the caller seeks to include in the bus line object
    index => $index,                                                            # Position along the bus of the item,
    low   => $low,                                                              # First line the placement straddles
    high  => $high,                                                             # Last line  the placement straddles
   );
 }

sub add($$%)                                                                    # Widen the bus with the name of an item.
 {my ($bus, $item, %options) = @_;                                              # Bus line, item name, options
  @_ >= 2 or confess "Two or more parameters";
  $bus->hash->{$item} and confess <<"END" =~ s/\n(.)/ $1/gsr;
Item $item already on the bus.
END
  $bus->hash->{$item} = $bus->array->@*;                                        # Location for this item
  $bus->place->{$item} = newPlace(scalar($bus->array->@*), $item, $item);       # Describe this as a simplified straddle that is bound to succeed
  push $bus->array->@*, $item;                                                  # Add this item at the expected location
 }

sub straddle($$$$%)                                                             # Place an item across the bus either widening the bus or reusing the first bus line freed by this object
 {my ($bus, $out, $lines, $free, %options) = @_;                                # Bus line, item name, array of bus lines required for item, any lines that terminate here, options
  @_ >= 4 or confess "Four or more parameters";
  my $m; my $M;                                                                 # Minimum and maximum indices of lines straddled
  my $inUse = 0;                                                                # Checks that all the requested bus lines are free
  for my $l(@$lines)
   {(my $i = $bus->hash->{$l}) or confess <<"END" =~ s/\n(.)/ $1/gsr;           # Check each requested line is present
No such item as $l on bus.
END
    $m = $i if !defined($m) or $i < $m;                                         # Minimum index of straddle
    $M = $i if !defined($M) or $i > $M;                                         # Maximum index of straddle
   }
  my @lines = $bus->array->@*;
  for my $l(@lines[$m..$M])                                                     # Each line within the range occupied by the straddle
   {$inUse++ if $bus->used->{$l};                                               # Count the lines that are being straddled by something else
   }

  my $p = sub
   {if ($inUse)                                                                 # Need a new extension of the bus line because we cannot fit the latest item on the existing bus
     {push $bus->trace->@*, [$bus->trace->[-1]->@*];                            # Record currently active lines
      $bus->used = {map {$_=>1} @$lines};                                       # New usage
      $bus->place->{$out} = newPlace($bus->trace->$#*, $m, $M);                 # Position in new usage
     }
    else                                                                        # Place in existing bus
     {for my $l(@lines[$m..$M])                                                 # Each line within the range occupied by the straddle
       {$bus->used->{$l}++;                                                     # Mark lines as currently in use
       }
      $bus->place->{$out} = newPlace($bus->trace->$#*, $m, $M);                 # Position in new usage
     }
   } ->();
  $p
 }

if (1)
 {my $b = new();
  $b->add("a$_") for 1..8;
  my $p = $b->straddle("b1", ["a2", "a4", "a6"], []);
  is_deeply($p, {high => 5, index => 0, low => 1 });

  my $q = $b->straddle("b2", ["a7", "a8"],       []);
  is_deeply($q, { high => 7, index => 0, low => 6 });

  my $r = $b->straddle("b2", ["a6", "a7"],       []);
  lll "AAAA\n", dump($r);
  is_deeply($r, { high => 6, index => 1, low => 5 });
 }

#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/
#-------------------------------------------------------------------------------
# Push Silicon::Chip code to GitHub
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc., 2023
#-------------------------------------------------------------------------------
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use GitHub::Crud qw(:all);
use Pod::Markdown;
use feature qw(say current_sub);

makeDieConfess;

my $home      = q(/home/phil/perl/cpan/SiliconChip/);                           # Local files
my $user      = q(philiprbrenan);                                               # User
my $repo      = q(SiliconChip);                                                 # Repo
my $wf        = q(.github/workflows/main.yml);                                  # Work flow on Ubuntu

sub pod($$)                                                                     # Write pod file
 {my ($in, $out) = @_;                                                          # Input, output file
  my $d = updateDocumentation readFile $in;
  my $p = Pod::Markdown->new;
  my $m;
     $p->output_string(\$m);
     $p->parse_file($in);                                                       # Create Pod and convert to markdown
     $m =~ s(POD ERRORS.*\Z) ();
     owf($out, $m);                                                             # Write markdown
 }

if (1)                                                                          # Documentation from pod to markdown into read me with well known words expanded
 {pod fpf($home, q(lib/Silicon/Chip.pm)), fpf($home, q(README.md2));

  expandWellKnownWordsInMarkDownFile
    fpe($home, qw(README md2)), my $r = fpe $home, qw(README md);
 }

push my @files, searchDirectoryTreesForMatchingFiles($home, qw(.md .pl .pm .svg)); # Files

for my $s(@files)                                                               # Upload each selected file
 {next if $s =~ m(blib)i;
  next if $s =~ m(build)i;
  say STDERR $s;
  my $c = readFile($s);                                                         # Load file
  my $t = swapFilePrefix $s, $home;
  my $w = writeFileUsingSavedToken($user, $repo, $t, $c);
  lll "$w $s $t";
 }

if (1)
 {my $d = dateTimeStamp;
  my $y = <<"END";
# Test $d

name: Test

on:
  push

jobs:

  test:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout\@v3
      with:
        ref: 'main'

    - uses: actions/checkout\@v3
      with:
        repository: philiprbrenan/DataTableText
        path: dtt

    - uses: actions/checkout\@v3
      with:
        repository: philiprbrenan/SvgSimple
        path: svg

    - name: Install Tree
      run:
        sudo apt install tree

    - name: Tree
      run:
        tree

    - name: Cpan
      run:  sudo cpan install -T Data::Dump
    - name: Ubuntu update
      run:  sudo apt update


    - name: Verilog installation
      run:  sudo apt -y install iverilog

    - name: Test Perl implementation of B Tree
      run:
        perl -Idtt/lib Zesal.pm

    - name: Test Perl implemented integrated circuits
      run:
        perl -Idtt/lib -Isvg/lib  Chip.pm

    - name: Test Verilog
      run:
        rm -f Zesal; iverilog -Iincludes/ -g2012 -o Zesal Zesal.sv Zesal.tb && timeout 1m ./Zesal
END

  my $f = writeFileUsingSavedToken $user, $repo, $wf, $y;                       # Upload workflow
  lll "Ubuntu work flow for $repo written to: $f";
 }

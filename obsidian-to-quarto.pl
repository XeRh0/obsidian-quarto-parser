#!/usr/bin/env perl

# ------------------------------------------------------------------------------
# Script for parsing obsidian markdown to be used for quarto.
# ------------------------------------------------------------------------------

use warnings;
use strict;
use utf8;

# ------------------------------------------------------------------------------
# Regular expressions for matching markdown syntax
# ------------------------------------------------------------------------------

my $CALLOUT_REGEX = qr/> \[\!([^]]+)\]([+-]?) (.*)/;
my $CODEBLOCK_REGEX = qr/^```/;
my $VERBATIM_REGEX = qr/([^`]*)\`\{([^}]+)\}\ ([^`]*)\`(.*)/;

# ------------------------------------------------------------------------------
# Subroutines
# ------------------------------------------------------------------------------

my sub verbatim_parsing_mode {
  my ($line) = @_;
  my $has_newline = ($line =~ "\n");
  while($line =~ $VERBATIM_REGEX) {
    print("$1\`$3\`\{\.$2\}"); # reorder matched parts
    $line = $4; # Assign remaining contents to $line, so they can be reused.
  }
  print($line);
  if($has_newline == 1) {
    print("\n");
  }
  return;
}

# ------------------------------------------------------------------------------

my sub callout_parsing_mode {
  my ($line) = @_;
  my $count = 0;
  my $nesting_level = 0;
  my $codeblock = 0;
  while(defined $line) {
    for(my $counter = 0; $counter < $nesting_level; ++$counter) {
      if($line =~ s/>//) {
        $line =~ s/ //;
        ++$count;
      }
    }
    if($line =~ $CALLOUT_REGEX && $codeblock == 0) {
      ++$nesting_level;
      print("\n::: {.$1 title=\"");
      $line = $3;
      my $collapse = $2;
      if($line =~ $VERBATIM_REGEX) {
        verbatim_parsing_mode($line);
        print("\"");
      } else {
        print ("$line\"");
      }
      if(!($collapse eq "")) {
        print(" collapse=", ($2 eq "-")? "true" : "false");
      }
      print("}\n");
      $count = 0;
      $line = <STDIN>;
      next;
    } 
    if($count == 0) {
      print(":::\n");
      print($line);
      return;
    }
    if($line =~ $CODEBLOCK_REGEX) {
      $codeblock = ($codeblock + 1) % 2;
      $count = 0;
      print($line);
      $line = <STDIN>;
      next;
    } 
    if($line =~ $VERBATIM_REGEX) {
      verbatim_parsing_mode($line);
      if(!($line =~ s/\n//)) {
        print("\n");
      }
      $line = <STDIN>;
      next;
    } 
    if($count < $nesting_level) {
      --$nesting_level;
      print(":::\n");
    }
    $count = 0;
    print($line);
    if(!($line =~ s/\n//)) {
      print("\n");
    }
    $line = <STDIN>;
  }
  while($nesting_level > 0) {
    --$nesting_level;
    print(":::\n");
  }
  return;
}

# ------------------------------------------------------------------------------

# Currently only here for preventing parsing callouts or verbatim within 
# codeblocks, but could be more useful in the future.

my sub codeblock_parsing_mode {
  my ($line) = @_;
  while($line = <STDIN>) {
    print("$line");
    if($line =~ $CODEBLOCK_REGEX) {
      return;
    }
  }
  die("$0: Missing closing codeblock symbol!");
}


# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------

while(my $line = <STDIN>) {
  if($line =~ $CALLOUT_REGEX) {
    callout_parsing_mode($line);
  } elsif ($line =~ $CODEBLOCK_REGEX) {
    print($line);
    codeblock_parsing_mode($line);
  } elsif ($line =~ $VERBATIM_REGEX) {
    verbatim_parsing_mode($line);
  } else {
    print($line);
  }
}

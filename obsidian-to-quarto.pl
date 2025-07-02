#!/usr/bin/env perl

#
# Script for parsing markdown
#

use warnings;
use strict;
use utf8;

#
# Regular expressions for matching markdown syntax
#

my $CALLOUT_REGEX = qr/> \[\!([^]]+)\]([+-]?) (.*)/;
my $CODEBLOCK_REGEX = qr/^```/;
my $VERBATIM_REGEX = qr/([^`]*)\`\{([^}]+)\}\ ([^`]*)\`(.*)/;

#
# Variables
#

my $count = 0;

#
# Subroutines
#

my sub verbatim_parsing_mode() {
  while($_ =~ $VERBATIM_REGEX) {
    print("$1\`$3\`\{\.$2\}");
    $_ = $4;
  }
  print("$4\n");
  return;
}

my sub callout_parsing_mode() {
  my $nesting_level = 1;
  while(<>) {
   for(my $iterator = 0; $iterator < $nesting_level; ++$iterator) {
      if(s/>//) {
        s/ //;
        ++$count;
      }
    }
    if($count == 0) {
      print(":::\n");
      print($_);
      return;
    }
   if($_ =~ $CALLOUT_REGEX) {
      ++$nesting_level;
      print("\n::: {.$1 title=\"$3\"");
      if(!($2 eq "")) {
        print(" collapse=", ($2 eq "-")? "true" : "false");
      }
      print("}\n");
      next;
    }
    if($_ =~ $VERBATIM_REGEX) {
      verbatim_parsing_mode();
    }
       if($count < $nesting_level) {
      --$nesting_level;
      print ":::\n";
    }
    $count = 0;
    print($_);
  }
  while($nesting_level > 0) {
    --$nesting_level;
    print ":::\n";
  }
}

# Currently only here for preventing parsing callouts or verbatim within 
# codeblocks, but could be more useful in the future.
my sub codeblock_parsing_mode() {
  while(<>) {
    print("$_");
    if($_ =~ $CODEBLOCK_REGEX) {
      return;
    }
  }
  die("$0: Missing closing codeblock symbol!");
}


#
# Main
#

while(<>) {
  # If we detect callout
  if($_ =~ $CALLOUT_REGEX) {
    # Parse current line
    print("\n::: {.$1 title=\"$3\"");
    if(!($2 eq "")) {
      # Parse optional parameter +-
      print(" collapse=", ($2 eq "-")? "true" : "false");
    }
    print("}\n");
    callout_parsing_mode();
  } elsif ($_ =~ $CODEBLOCK_REGEX) {
    print($_);
    codeblock_parsing_mode();
  } elsif ($_ =~ $VERBATIM_REGEX) {
    verbatim_parsing_mode();
  } else {
    print($_);
  }
}

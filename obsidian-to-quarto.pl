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

use constant CALLOUT_REGEX => qr/> \[\!([^]]+)\]([+-]?) (.*)/;
use constant CODEBLOCK_REGEX => qr/^```/;
use constant VERBATIM_REGEX => qr/([^`]*)\`\{([^}]+)\}\ ([^`]*)\`(.*)/;

# ------------------------------------------------------------------------------
# Subroutines
# ------------------------------------------------------------------------------

my sub verbatim_parsing_mode {
  my ($line, $output_file) = @_;
  my $has_newline = ($line =~ "\n");
  while($line =~ VERBATIM_REGEX) {
    print($output_file "$1\`$3\`\{\.$2\}"); # reorder matched parts
    $line = $4; # Assign remaining contents to $line, so they can be reused.
  }
  print($output_file $line);
  if($has_newline == 1) {
    print($output_file "\n");
  }
  return;
}

# ------------------------------------------------------------------------------

my sub callout_parsing_mode {
  my ($line, $input_file, $output_file) = @_;
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
    if($line =~ CALLOUT_REGEX && $codeblock == 0) {
      ++$nesting_level;
      print($output_file "\n::: {.$1 title=\"");
      $line = $3;
      my $collapse = $2;
      if($line =~ VERBATIM_REGEX) {
        verbatim_parsing_mode($line, $output_file);
        print($output_file "\"");
      } else {
        print ($output_file "$line\"");
      }
      if(!($collapse eq "")) {
        print($output_file " collapse=", ($2 eq "-")? "true" : "false");
      }
      print($output_file "}\n");
      $count = 0;
      $line = <$input_file>;
      next;
    } 
    if($count == 0) {
      print($output_file ":::\n");
      print($line);
      return;
    }
    if($line =~ CODEBLOCK_REGEX) {
      $codeblock = ($codeblock + 1) % 2;
      $count = 0;
      print($output_file $line);
      $line = <$input_file>;
      next;
    } 
    if($line =~ VERBATIM_REGEX) {
      verbatim_parsing_mode($line, $output_file);
      if(!($line =~ s/\n//)) {
        print($output_file "\n");
      }
      $line = <$input_file>;
      next;
    } 
    if($count < $nesting_level) {
      --$nesting_level;
      print($output_file ":::\n");
    }
    $count = 0;
    print($output_file $line);
    if(!($line =~ s/\n//)) {
      print($output_file "\n");
    }
    $line = <$input_file>;
  }
  while($nesting_level > 0) {
    --$nesting_level;
    print($output_file ":::\n");
  }
  return;
}

# ------------------------------------------------------------------------------

# Currently only here for preventing parsing callouts or verbatim within 
# codeblocks, but could be more useful in the future.

my sub codeblock_parsing_mode {
  my ($line, $input_file, $output_file) = @_;
  print($output_file $line);
  while($line = <$input_file>) {
    print($output_file $line);
    if($line =~ CODEBLOCK_REGEX) {
      return;
    }
  }
  die("$0: Missing closing codeblock symbol!");
}

# ------------------------------------------------------------------------------

my sub resolve_flags {
  my $input_file_name;
  my $output_file_name;

  for(my $parameter_count = $#ARGV; $parameter_count >= 0;) {
    my $input = $ARGV[0];
    if($input eq "-h") {
      print_help();
      exit(0);
    }
    if($input eq "-i") {
      if(!(defined $ARGV[1])) {
        die("$0: Missing input file name!");  
      }
      $input_file_name = $ARGV[1];
      shift @ARGV for 1..2;
      $parameter_count -= 2;
      next;
    }
    if($input eq "-o") {
      if(!(defined $ARGV[1])) {
        die("$0: Missing output file name!");  
      }
      $output_file_name = $ARGV[1];
      shift @ARGV for 1..2;
      $parameter_count -= 2;
      next;
    }
    if(!defined($input_file_name)) {
      $input_file_name = $input;
      shift @ARGV;
      $parameter_count -= 1;
      next;
    }
    if(!defined($output_file_name)) {
      $output_file_name = $input;
      shift @ARGV;
      $parameter_count -= 1;
      next;
    }
    die("$0: Unknown parameters!");
  }

  my $input_file;
  my $output_file;

  if(!defined($input_file_name)) {
     $input_file = *STDIN; 
  } else {
    open($input_file, '<', $input_file_name)
      or die ("$0: Could not open $input_file_name");
  }

  if(!defined($output_file_name)) {
    $output_file = *STDOUT;
  } else {
    open($output_file, '>', $output_file_name) 
      or die ("$0: Could not open $output_file_name");
  }

  return ($input_file, $output_file);
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------

my ($input_file, $output_file) = resolve_flags();

while(my $line = <$input_file>) {
  if($line =~ CALLOUT_REGEX) {
    callout_parsing_mode($line, $input_file, $output_file);
  } elsif ($line =~ CODEBLOCK_REGEX) {
    codeblock_parsing_mode($line, $input_file, $output_file);
  } elsif ($line =~ VERBATIM_REGEX) {
    verbatim_parsing_mode($line, $output_file);
  } else {
    print($output_file $line);
  }
}

if($input_file ne *STDIN) {
  close($input_file);
}

if($output_file ne *STDOUT) {
  close($output_file);
}

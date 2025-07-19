#!/usr/bin/env perl

# ------------------------------------------------------------------------------
# Script for parsing obsidian markdown to be used for quarto.
# ------------------------------------------------------------------------------

use Getopt::Long;
use strict;
use utf8;
use warnings;

# ------------------------------------------------------------------------------
# Getopt configuration
# ------------------------------------------------------------------------------

# force case-sensitive options
Getopt::Long::Configure("no_ignore_case");

# to prevent -long getting recognized as --long
Getopt::Long::Configure("gnu_compat");

# ------------------------------------------------------------------------------
# Regular expressions for matching markdown syntax
# ------------------------------------------------------------------------------

use constant CALLOUT_REGEX => qr/> \[\!([^]]+)\]([+-]?) (.*)/;
use constant CODEBLOCK_REGEX => qr/^```/;
use constant VERBATIM_REGEX => qr/(.*)([^`]*)\`\{([^}]+)\}\ ([^`]*)\`(.*)/;

# ------------------------------------------------------------------------------
# Subroutines
# ------------------------------------------------------------------------------

my sub verbatim_parsing_mode {
  my ($line, $output_file) = @_;
  my $has_newline = ($line =~ "\n");
  my $result = "";
  while($line =~ VERBATIM_REGEX) {
    $result = "$2\`$4\`\{\.$3\}$5" . $result; # reorder matched parts
    $line = $1; # Assign remaining contents to $line, so they can be reused.
  }
  print($output_file "$line$result");
  if($has_newline == 1) {
    print($output_file "\n");
  }
  return;
}

# ------------------------------------------------------------------------------

my sub callout_parsing_mode {
  my ($line, $input_file, $output_file, $verbatim_flag) = @_;
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
    if($verbatim_flag == 1 && $line =~ VERBATIM_REGEX) {
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

my sub print_help {
  print("Usage: ./obsidian-to-quarto.pl [OPTION] ... [FILE]
Parse obsidian markdown syntax to quarto pandoc syntax.
Flags:
  -i, --input <input_file>      sets input file (implicit STDIN) 
  -I, --Inplace                 outputs the result of parsing into the input file
  -h, --help                    prints this text
  -o, --output <output_file>    sets output file (implicit STDOUT)
  -v, --verbatim                turns on parsing custom verbatim syntax
");
}

# ------------------------------------------------------------------------------

my sub resolve_flags {
  my $input_file_name = '';
  my $output_file_name = '';
  
  my $help_flag = 0; 
  my $verbatim_flag = 0;
  my $inplace_flag = 0;

  my $input_file = *STDIN;
  my $output_file = *STDOUT;

  GetOptions(
    "input|i=s" => \$input_file_name,
    "inplace|I" => \$inplace_flag,
    "help|h" => \$help_flag,
    "output|o=s" => \$output_file_name,
    "verbatim|v" => \$verbatim_flag
  ) or do {
    print_help();
    exit(1);
  };

  if($input_file_name eq $output_file_name && 
     $input_file_name ne '') {
    die("$0: Input and output file names must not match! " .
        "For inplace parsing please use the --inplace flag.");
  }

  if($input_file_name ne '') {
    open($input_file, '<', $input_file_name)
      or die("$0: Could not open $input_file_name");
  }

  if($output_file_name ne '') {
    open($output_file, '>', $output_file_name)
      or die("$0: Could not open $output_file_name");
  }

  return($input_file, $output_file, $verbatim_flag, $inplace_flag);
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------

my ($input_file, $output_file, $verbatim_flag, $inplace_flag) = resolve_flags();

while(my $line = <$input_file>) {
  if($line =~ CALLOUT_REGEX) {
    callout_parsing_mode($line, $input_file, $output_file, $verbatim_flag);
  } elsif ($line =~ CODEBLOCK_REGEX) {
    codeblock_parsing_mode($line, $input_file, $output_file);
  } elsif ($verbatim_flag == 1 && $line =~ VERBATIM_REGEX) {
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

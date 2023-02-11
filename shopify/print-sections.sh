#!/bin/bash

# define a function to parse a section file
parse_section() {
  section_file=$1
  
  # extract the section name
  section_name=$(grep -oP '^\s*{%\s*section\s*(\w+)\s*%}' $section_file | awk '{print $2}')
  
  # extract the block names
  block_names=$(grep -oP '^\s*{%\s*block\s*(\w+)\s*%}' $section_file | awk '{print $2}')
  
  # print the section name and its blocks
  echo "$section_name"
  for block_name in $block_names; do
    echo "  $block_name"
  done
}

# find all section files in the theme
section_files=$(find . -name '*.liquid' -print0 | xargs -0 grep -l '^\s*{%\s*section\s*(\w+)\s*%}')

# parse each section file
for section_file in $section_files; do
  parse_section $section_file
done
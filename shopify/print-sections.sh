#!/bin/bash

# define a function to parse a section file
parse_section() {
  section_file=$1
  
  # extract the section name
  section_name=$(grep -oP '"name":\s*"\w+"' $section_file | awk -F'"' '{print $4}')
  
  # print the section name
  echo "$section_name"
}

# iterate over all the files in the sections subfolder
for section_file in ./sections/*; do
  parse_section $section_file
done
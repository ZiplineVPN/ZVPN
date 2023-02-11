#!/bin/bash

# Create an array to store all the used files
used_files=()

# Parse all files in the current subdirectory
for file in *.*; do
  # Skip this iteration if the file is not a Liquid, CSS, or JS file
  if [[ ! "$file" =~ \.liquid$ ]] && [[ ! "$file" =~ \.css$ ]] && [[ ! "$file" =~ \.js$ ]]; then
    continue
  fi

  # Search for file references in the current file
  references=$(grep -oE '\S+\.(liquid|css|js)' "$file")

  # Add each referenced file to the list of used files
  for reference in $references; do
    used_files+=("$reference")
  done
done

# Make the list of used files unique
used_files=($(echo "${used_files[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

# Create the dead-code directory
mkdir -p dead-code

# Copy all unused files into the dead-code directory
for file in *.*; do
  # Skip this iteration if the file is not a Liquid, CSS, or JS file
  if [[ ! "$file" =~ \.liquid$ ]] && [[ ! "$file" =~ \.css$ ]] && [[ ! "$file" =~ \.js$ ]]; then
    continue
  fi

  # Check if the file is used
  if [[ ! " ${used_files[@]} " =~ " $file " ]]; then
    cp "$file" dead-code/
  fi
done

# Confirm that the operation was successful
echo "Success: All unused files have been copied to the dead-code directory."

# Generate the restore script
restore_script="restore_dead_code.sh"
echo "#!/bin/bash" > "$restore_script"
echo "" >> "$restore_script"
for file in dead-code/*.*; do
  # Extract the file name from the path
  filename=$(basename "$file")

  # Add a line to the restore script to copy the file back to its original location
  echo "cp \"dead-code/$filename\" . " >> "$restore_script"
  echo "echo \"Success: $filename was restored to its original location.\"" >> "$restore_script"
done
echo "echo \"Success: All files have been restored from the dead-code directory.\"" >> "$restore_script"

# Make the restore script executable
chmod +x "$restore_script"

# Confirm that the restore script was generated
echo "Success: The restore script has been generated."
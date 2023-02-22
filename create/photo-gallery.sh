#!/bin/bash

echo "<html>
<head>
<title>Photo Gallery</title>
<style>
img {
    width: 200px;
    height: 200px;
    object-fit: cover;
    margin: 5px;
    border: 1px solid black;
}
</style>
</head>
<body>
<h1>Photo Gallery</h1>
<div>" > index.html

# Find all image files in subdirectories and store them in an array
image_files=( $(find . -type f \( -name "*.png" -o -name "*.svg" -o -name "*.gif" -o -name "*.bmp" -o -name "*.jpg" -o -name "*.jpeg" \)) )

# Loop through the array and display each image in the gallery
for file in "${image_files[@]}"
do
    echo "<a href=\"$file\"><img src=\"$file\"></a>" >> index.html
done

echo "</div>
</body>
</html>" >> index.html
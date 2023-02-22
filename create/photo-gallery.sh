#!/bin/bash

echo "<html>
<head>
<title>Photo Gallery</title>
<style>
body {
    background-color: #f2f2f2;
}

img {
    width: 200px;
    height: 200px;
    object-fit: cover;
    margin: 5px;
    border: 1px solid black;
}

.toggle {
    display: inline-block;
    background-color: #fff;
    color: #333;
    font-size: 16px;
    padding: 10px;
    border: 1px solid #ccc;
    border-radius: 5px;
    cursor: pointer;
    transition: all 0.2s ease;
}

.toggle:hover {
    background-color: #333;
    color: #fff;
}

.dark-mode {
    background-color: #333;
}

.dark-mode img {
    border: 1px solid white;
}

.dark-mode .toggle {
    background-color: #333;
    color: #fff;
    border: 1px solid #fff;
}

.pagination {
    margin-top: 10px;
}

.page-link {
    display: inline-block;
    padding: 5px 10px;
    background-color: #fff;
    color: #333;
    border: 1px solid #ccc;
    border-radius: 5px;
    cursor: pointer;
    transition: all 0.2s ease;
}

.page-link:hover {
    background-color: #333;
    color: #fff;
    border: 1px solid #333;
}
</style>
</head>
<body>
<h1>Photo Gallery</h1>
<div id=\"gallery\">" >index.html

# Find all image files in subdirectories and store them in an array
image_files=($(find . -type f \( -name "*.png" -o -name "*.svg" -o -name "*.gif" -o -name "*.bmp" -o -name "*.jpg" -o -name "*.jpeg" \)))

# Split the array of image files into chunks of 500
chunk_size=500
chunks=($(echo "${image_files[@]}" | tr ' ' '\n' | split -l $chunk_size -da 4 - gallery_chunk_))

# Get the total number of chunks
num_chunks=${#chunks[@]}

# Loop through the array of chunks and create a gallery page for each chunk
for ((i = 0; i < $num_chunks; i++)); do
    # Open a new page div and set its display to none
    echo "<div class=\"page\" id=\"page_$i\" style=\"display: none;\">" >>index.html

    # Loop through the images in the current chunk and display them in the gallery
    for file in ${chunks[$i]}; do
        echo "<a href=\"$file\"><img src=\"$file\"></a>" >>index.html
    done

    # Close the page div
    echo "</div>" >>index.html
done

# Create pagination links for each page
echo "<div class=\"pagination\">" >>index.html
for ((i = 0; i < $num_chunks; i++)); do
    echo "<a class=\"page-link\" href=\"#\" onclick=\"showPage($i)\">Page $((i + 1))</a>" >>index.html
done
echo "</div>" >>index.html

# Add a button to toggle dark mode
echo "<button class=\"toggle\" onclick=\"toggleDarkMode()\">Toggle Dark Mode</button>" >>index.html

# Add JavaScript functions for pagination and dark mode toggle
echo "<script>
function showPage(page) {
    var pages = document.getElementsByClassName('page');
    for (var i = 0; i < pages.length; i++) {
        pages[i].style.display = 'none';
    }
    pages[page].style.display = 'block';
}

function toggleDarkMode() {
    var body = document.querySelector('body');
    var button = document.querySelector('.toggle');
    body.classList.toggle('dark-mode');
    if (body.classList.contains('dark-mode')) {
        button.innerHTML = 'Toggle Light Mode';
    } else {
        button.innerHTML = 'Toggle Dark Mode';
    }
}    

var button = document.querySelector('.toggle');
// Check if system color scheme is dark
if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
    body.classList.add('dark-mode');
    button.innerHTML = 'Toggle Light Mode';
}

// Show the first page by default
showPage(0);
</script>

</body>
</html>" >>index.html

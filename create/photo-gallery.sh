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

echo "<br>
<button class=\"toggle\" onclick=\"toggleDarkMode()\">Toggle Dark Mode</button>

<script>
function toggleDarkMode() {
    var body = document.querySelector('body');
    var button = document.querySelector('.toggle');
    body.classList.toggle('dark-mode');
    if (body.classList.contains('dark-mode')) {
        button.innerHTML = 'Toggle Light Mode';
    } else {
        button.innerHTML = 'Toggle Dark Mode';
    }

    // Check if system color scheme is dark
    if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
        body.classList.add('dark-mode');
        button.innerHTML = 'Toggle Light Mode';
    }
}
</script>

</div>
</body>
</html>" >> index.html
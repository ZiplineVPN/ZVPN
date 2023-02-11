#!/bin/bash

# Create the theme directory
mkdir my_theme
cd my_theme

# Create the necessary directories
mkdir assets
mkdir config
mkdir layout
mkdir snippets
mkdir sections
mkdir templates

# Create the config files
touch config/settings_data.json
echo '{
  "name": "My Theme",
  "settings": [
    {
      "type": "header",
      "content": "My Theme Settings"
    },
    {
      "type": "color",
      "id": "body_background_color",
      "label": "Body Background Color",
      "default": "#ffffff"
    },
    {
      "type": "text",
      "id": "my_setting_1",
      "label": "My Setting 1",
      "default": "default value"
    },
    {
      "type": "text",
      "id": "my_setting_2",
      "label": "My Setting 2",
      "default": "default value"
    }
  ]
}' > config/settings_data.json

touch config/settings_schema.json
echo '{
  "name": "My Theme",
  "settings": [
    {
      "type": "header",
      "content": "My Theme Settings"
    },
    {
      "type": "color",
      "id": "body_background_color",
      "label": "Body Background Color",
      "default": "#ffffff"
    },
    {
      "type": "text",
      "id": "my_setting_1",
      "label": "My Setting 1",
      "default": "default value"
    },
    {
      "type": "text",
      "id": "my_setting_2",
      "label": "My Setting 2",
      "default": "default value"
    }
  ]
}' > config/settings_schema.json

# Create the layout file
touch layout/theme.liquid
echo '<!DOCTYPE html>
<html>
  <head>
    <title>{{ page_title }}</title>
    <link rel="stylesheet" href="{{ 'assets/style.css.liquid' | asset_url }}" />
  </head>
  <body style="background-color: {{ settings.body_background_color }};">
    {{ content_for_layout }}
  </body>
</html>' > layout/theme.liquid

# Create the header section
touch sections/header.liquid
echo '<header>
  <nav>
    <a href="/">Home</a>
    <a href="/collections">Collections</a>
  </nav>
</header>' > sections/header.liquid

# Create the footer section
touch sections/footer.liquid
echo '<footer>
  <p>Copyright {{ "now" | date: "%Y" }} My Theme</p>
</footer>' > sections/footer.liquid

# Create the index template
touch templates/index.liquid
echo '{% section 'header' %}

<h1>Welcome to My Theme</h1>

{% section 'footer' %}
' > templates/index.liquid

# Create the product template
touch templates/product.liquid
echo '{% section 'header' %}

<h1>{{ product.title }}</h1>
<p>{{ product.description }}</p>

{% section 'footer' %}
' > templates/product.liquid

# Create the style file
touch assets/style.css.liquid
echo 'body {
  font-family: Arial, sans-serif;
  padding: 20px;
}

header nav a {
  display: inline-block;
  margin-right: 10px;
  text-decoration: none;
  color: #333;
}

footer {
  text-align: center;
}' > assets/style.css.liquid
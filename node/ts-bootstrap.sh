#!/bin/bash

# Check if package.json already exists
if [ -f "package.json" ]; then
    echo "package.json already exists. Aborting..."
    exit 1
fi

# Initialize a new TypeScript project with Yarn
yarn init -y
yarn add typescript

# Initialize a new TypeScript configuration file
npx tsc --init

# Create a source directory for your TypeScript files
mkdir src

# Create an index file for your project
touch src/index.ts

# Add a basic TypeScript console.log statement to index.ts
echo "console.log('Hello, world!');" >> src/index.ts

# Install nodemon and concurrently for development
yarn add --dev nodemon concurrently

# Update package.json with proper scripts
jq '.scripts = {
  "start": "tsc && node dist/index.js",
  "build": "tsc",
  "test": "echo \"Error: no test specified\" && exit 1",
  "dev": "concurrently \\\"tsc -w\\\" \\\"nodemon dist/index.js\\\""
}' package.json > tmp.$$.json && mv tmp.$$.json package.json

# Output success message
echo "Successfully bootstrapped a new TypeScript project with Yarn!"
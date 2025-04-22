# EncodedId Documentation Website

This directory contains the Jekyll-based documentation website for the EncodedId gem. The site is built with Jekyll using the Just-the-Docs theme.

## Local Development

You can work with the documentation in two ways:

### Using Rake Tasks (Recommended)

From the root directory of the repository:

```bash
# Build the documentation website
bundle exec rake website:build

# Serve the documentation locally
bundle exec rake website:serve

# Clean the documentation build
bundle exec rake website:clean
```

### Manual Setup

If you prefer to run Jekyll commands directly:

```bash
# Navigate to the website directory
cd website

# Install dependencies
bundle install

# Serve the site locally (with live reloading)
bundle exec jekyll serve

# Build the site without serving
bundle exec jekyll build
```

Visit http://localhost:4000/ in your browser when running the server.

## Deployment

The site is automatically deployed to Render when changes are pushed to the main branch.
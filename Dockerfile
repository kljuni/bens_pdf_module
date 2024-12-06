# syntax=docker/dockerfile:1
# Dockerfile for development environment

# Use the Ruby version specified in .ruby-version
ARG RUBY_VERSION=3.2.0
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Set the working directory
WORKDIR /rails

# Install essential packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl \
    libjemalloc2 \
    libvips \
    postgresql-client \
    build-essential \
    git \
    libpq-dev \
    nodejs \
    npm && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install Yarn (if needed for Webpacker or JS bundling)
RUN npm install -g yarn

# Set development environment
ENV RAILS_ENV="development" \
    BUNDLE_PATH="/usr/local/bundle" \
    GEM_HOME="/usr/local/bundle"

# Copy Gemfile and Gemfile.lock for gem installation
COPY Gemfile Gemfile.lock ./

# Install gems (including development dependencies)
RUN bundle install

# Copy application code
COPY . .

# Ensure required directories exist
RUN mkdir -p tmp/pids tmp/cache tmp/sockets log storage && \
    chmod -R 755 tmp log storage

# Expose the Rails server port
EXPOSE 3000

# Entrypoint for Docker
CMD ["bin/rails", "server", "-b", "0.0.0.0"]

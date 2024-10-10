#! /bin/bash

echo "running rubocop on step files"
rubocop_file="testsuite/.rubocop.yml"
if [[ -f "$rubocop_file" ]]; then
  # Extract the Ruby version from the file
  ruby_version=$(grep "TargetRubyVersion:" "$rubocop_file" | awk '{print $2}')
  # Temporary skip the check for Ruby 3.3
  if [[ "$ruby_version" == "3.3" ]]; then
    echo "Skipping Rubocop for Ruby 3.3, until sumadockers support it."
    exit 0
  fi
  if [[ -n "$ruby_version" ]]; then
    rubocop.ruby"$ruby_version" -v
    cd testsuite
    rubocop.ruby"$ruby_version" features/*
  else
    echo "No TargetRubyVersion found in $rubocop_file."
  fi
else
  echo "File $rubocop_file does not exist."
fi

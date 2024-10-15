#! /bin/bash

echo "running rubocop on step files"
rubocop_file="testsuite/.rubocop.yml"
if [[ -f "$rubocop_file" ]]; then
  # Extract the Ruby version from the file
  ruby_version=$(grep "TargetRubyVersion:" "$rubocop_file" | awk '{print $2}')
  if [[ -n "$ruby_version" ]]; then
    cd testsuite
    docker run --rm --volume "$PWD:/app" docker.io/srbarrios/rubocop:ruby-$ruby_version
  else
    echo "No TargetRubyVersion found in $rubocop_file."
  fi
else
  echo "File $rubocop_file does not exist."
fi

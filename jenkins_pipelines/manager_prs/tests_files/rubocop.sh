#! /bin/bash

echo "running rubocop on step files"
rubocop_file="testsuite/.rubocop.yml"
gemfile="testsuite/Gemfile"
if [[ ! -f "$rubocop_file" ]]; then
  echo "File $rubocop_file does not exist."
  exit 1
fi
if [[ ! -f "$gemfile" ]]; then
  echo "File $gemfile does not exist."
  exit 1
fi

# Both files come from the pull request under test, so every value read out of them
# is checked against an exact version number before it reaches a command line
version_pattern='^[0-9]+(\.[0-9]+)*$'

# Extract the Ruby version from the RuboCop configuration, skipping comments and
# stopping at the first match
ruby_version=$(awk '/^[[:space:]]*TargetRubyVersion:/ {print $2; exit}' "$rubocop_file")
if [[ ! $ruby_version =~ $version_pattern ]]; then
  echo "No usable TargetRubyVersion found in $rubocop_file: '${ruby_version}'."
  exit 1
fi

# Extract the RuboCop versions pinned by the testsuite, so that the cops known here
# are exactly the ones the .rubocop_todo.yml was generated with
rubocop_version=$(awk -F"'" "/^gem 'rubocop'/ {print \$4}" "$gemfile")
rubocop_ast_version=$(awk -F"'" "/^gem 'rubocop-ast'/ {print \$4}" "$gemfile")
if [[ ! $rubocop_version =~ $version_pattern ]]; then
  echo "$gemfile must pin rubocop to an exact version, found '${rubocop_version}'."
  exit 1
fi

# rubocop-ast goes first, together with --conservative, so that it is not pulled in
# as a newer transitive dependency of rubocop
gems=""
if [[ -n "$rubocop_ast_version" ]]; then
  if [[ ! $rubocop_ast_version =~ $version_pattern ]]; then
    echo "$gemfile must pin rubocop-ast to an exact version, found '${rubocop_ast_version}'."
    exit 1
  fi
  gems="rubocop-ast:${rubocop_ast_version} "
fi
gems="${gems}rubocop:${rubocop_version}"

echo "Using Ruby ${ruby_version} with ${gems}"
cd testsuite
docker run --rm --volume "$PWD:/app" --workdir /app --env "GEMS=${gems}" \
  "docker.io/library/ruby:${ruby_version}" \
  bash -c 'gem install --no-document --conservative $GEMS && rubocop --version && rubocop features/*'

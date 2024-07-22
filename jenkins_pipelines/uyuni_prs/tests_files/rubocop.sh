#! /bin/bash

echo "running rubocop on step files"
rubocop.ruby2.5 -v
cd testsuite
rubocop.ruby2.5 features/*

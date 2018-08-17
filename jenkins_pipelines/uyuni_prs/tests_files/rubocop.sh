#! /bin/bash

echo "running rubocop on step files"
cd testsuite
rubocop.ruby2.1 features/*

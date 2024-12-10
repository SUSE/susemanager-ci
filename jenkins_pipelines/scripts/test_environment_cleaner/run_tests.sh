#!/bin/bash

# Set the PYTHONPATH to include the necessary directories
export PYTHONPATH=$(pwd)/test_environment_cleaner_program

# Run the tests
python3.11 -m unittest discover -s tests

#!/bin/bash

# Set the PYTHONPATH to include the necessary directories
export PYTHONPATH=$(pwd)/suse_manager_cleaner_program

# Run the tests
python3.11 -m unittest discover -s tests

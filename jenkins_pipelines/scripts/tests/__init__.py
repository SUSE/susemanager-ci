import os
import sys


PROJECT_PATH = os.getcwd()

JSON_GENERATOR_SOURCE_PATH = os.path.join(PROJECT_PATH,"json_generator")
sys.path.append(JSON_GENERATOR_SOURCE_PATH)

BSC_FINDER_SOURCE_PATH = os.path.join(PROJECT_PATH,"bsc_list_generator")
sys.path.append(BSC_FINDER_SOURCE_PATH)

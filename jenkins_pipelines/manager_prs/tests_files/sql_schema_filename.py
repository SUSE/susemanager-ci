#! /usr/bin/python

import os
import sys

endings = ['.sql', '.sql.postgresql', '.sql.oracle', '.deps']
spacedirs = ['schema/spacewalk/common/', 'schema/spacewalk/postgres/', 'schema/spacewalk/oracle/', 'schema/spacewalk/upgrade/']
# allow gitigiore
gitigiore = ['.gitignore']


for spacedir in spacedirs:
  print("checking sql for directory {0}".format(spacedir))
  print("")
  for root, dirs, files in os.walk(spacedir):
      for file in files:
          if file.endswith(gitignore):
            continue 
          for postfix in endings:
              if not file.endswith(postfix):
                      print("file dont have postfix: {0}".format(postfix))
                      print(os.path.join(root, file))
                      sys.exit(1)

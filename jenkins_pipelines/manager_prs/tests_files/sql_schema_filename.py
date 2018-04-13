#! /usr/bin/python

import os
import sys

spacedirs = ['schema/spacewalk/common/', 'schema/spacewalk/postgres/', 'schema/spacewalk/oracle/', 'schema/spacewalk/upgrade/']

for spacedir in spacedirs:
  print("checking sql for directory {0}".format(spacedir))
  for root, dirs, files in os.walk(spacedir):
      for file in files:
          if file.endswith('Makefile') or file.endswith('.gitignore'):
                    continue
          if not (file.endswith('.sql') or file.endswith('.sql.postgresql') or file.endswith('.sql.oracle') or file.endswith('.deps')) :
                      print("following file doesn't have a valid postfix")
                      print(os.path.join(root, file))
                      sys.exit(1)

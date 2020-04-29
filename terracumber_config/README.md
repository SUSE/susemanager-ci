# Contents

This directory contains the  files used by terracumber to create an environment and run cucumber (except for reference environments).

- [tf_files](tf_files/): contains the terraform files describing the bascis environment, and variables
- [mail_templates](mail_templates/): contains the mail templates that are used for sending email. Each terraform file from the previous folder makes reference to two templates: one for cucumber results, the other when the environment fails to be created.

For more information refer to the terracumber documentation.

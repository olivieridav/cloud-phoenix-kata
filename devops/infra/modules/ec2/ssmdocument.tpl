schemaVersion: '1.2'
description: Dump mongo ${db_name} db
parameters: {}
runtimeConfig:
  'aws:runShellScript':
    properties:
      - id: '0.aws:runShellScript'
        runCommand:
          - #!/bin/bash
          - cd $(mktemp -d)
          - mongodump --db ${db_name}
          - DUMPFILE=dump_${db_name}_$(date +%Y%m%d-%H%M).zip
          - zip -r $DUMPFILE dump
          - aws s3 cp $DUMPFILE s3://${backup_bucket}
          - rm -rf dump*
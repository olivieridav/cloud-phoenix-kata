#!/bin/bash

MONGOREPO='''
[mongodb-org-5.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/5.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-5.0.asc
'''

echo -n "$MONGOREPO" > /etc/yum.repos.d/mongodb-org-5.0.repo
sudo yum install -y mongodb-org

sudo sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/g' /etc/mongod.conf

sudo systemctl start mongod
sudo systemctl enable mongod

mongosh ${db_name} --eval "db.createUser({user: '${db_user}',pwd: '${db_password}',roles:[{role: 'userAdmin' , db:'${db_name}'}]})"

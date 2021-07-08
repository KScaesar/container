#!/bin/bash

sleep 5

mongo --username root --password 1234 --host mongo0.dev-rs --port 27017 --eval '
rs.initiate(
  {
    _id : "dev-rs",
    "writeConcernMajorityJournalDefault": true,
    members: [
      { _id : 0, host : "mongo0.dev-rs:27017", priority : 10 },
      { _id : 1, host : "mongo1.dev-rs:27018", priority : 1 },
      { _id : 2, host : "mongo2.dev-rs:27019", priority : 1 }
    ]
  }
)
'

# https://gist.github.com/harveyconnor/518e088bad23a273cae6ba7fc4643549
# https://docs.mongodb.com/manual/reference/replica-configuration/#mongodb-rsconf-rsconf.members-n-.priority
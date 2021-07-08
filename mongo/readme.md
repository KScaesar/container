# tutorial

## preparation

- keyfile

  ```bash
  openssl rand -base64 756 > dev-rs.key
  chmod 400 dev-rs.key
  ```

  <https://docs.mongodb.com/manual/tutorial/deploy-replica-set-with-keyfile-access-control/#create-a-keyfile>

- update /etc/hosts

  ```bash
  cat << EOF | sudo tee -a /etc/hosts

  # add for container mongo
  127.0.0.1 mongo0.dev-rs
  127.0.0.1 mongo1.dev-rs
  127.0.0.1 mongo2.dev-rs
  # end
  EOF
  ```

  reason:  
  <https://stackoverflow.com/a/57814946>

- setup shell

  ```bash
  chmod 700 setup.sh
  ```

## query mongo-server status

```bash
docker exec -it mongo2 \
mongo --username root --password 1234 --host mongo1.dev-rs --port 27018 \
--eval 'rs.status()'

docker exec -it mongo0 \
mongo --username root --password 1234 --host mongo0.dev-rs --port 27017 \
--eval 'db.runCommand( { hello: 1 } )'

docker exec -it mongo0 \
mongo --username root --password 1234 --host mongo0.dev-rs --port 27017 \
--eval 'rs.conf()'
```

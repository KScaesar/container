# tutorial

## Subject-Based Messaging

Matching Subject
![Matching Subject](Subject1.png)

Matching A Single Token - `*`
![Matching A Single Token](Subject2.png)

Matching Multiple Tokens - `>`
![Matching Multiple Tokens](Subject3.png)

https://docs.nats.io/nats-concepts/subjects

## Core NATS

- Publish-Subscribe
```python
# https://docs.nats.io/using-nats/developer/receiving/async
nc = NATS()

await nc.connect(servers=["nats://demo.nats.io:4222"])

future = asyncio.Future()

async def cb(msg):
  nonlocal future
  future.set_result(msg)

await nc.subscribe("updates", cb=cb)
await nc.publish("updates", b'All is Well')
await nc.flush()

# Wait for message to come in
msg = await asyncio.wait_for(future, 1)
```

- Queue Groups  
    當多個訂閱者（subscribers）訂閱相同的主題（subject）時，使用 Queue Groups 來確保消息僅由其中一個訂閱者處理。

    基於 subject, 向所有訂閱者傳遞訊息
    基於 queue group, 隨機選擇 group 中的一個訂閱者消費訊息

    ![Queue Groups](Queue-Groups1.png)

```go
// https://docs.nats.io/using-nats/developer/receiving/queues
nc, err := nats.Connect("demo.nats.io")
if err != nil {
    log.Fatal(err)
}
defer nc.Close()

// Use a WaitGroup to wait for 10 messages to arrive
wg := sync.WaitGroup{}
wg.Add(10)

// Create a queue subscription on "updates" with queue name "workers"
if _, err := nc.QueueSubscribe("updates", "workers", func(m *nats.Msg) {
    wg.Done()
}); err != nil {
    log.Fatal(err)
}

// Wait for messages to come in
wg.Wait()
```

- Request-Reply
    reply 不僅訂閱 subject ，也會自動加入 queue group（預設為 "NATS-RPLY-22" ）

    ![Request-Reply](Request-Reply1.png)

```python
# https://docs.nats.io/using-nats/developer/receiving/reply
nc = NATS()

await nc.connect(servers=["nats://demo.nats.io:4222"])

future = asyncio.Future()

async def cb(msg):
  nonlocal future
  future.set_result(msg)

await nc.subscribe("time", cb=cb)

await nc.publish_request("time", new_inbox(), b'What is the time?')
await nc.flush()

# Read the message
msg = await asyncio.wait_for(future, 1)

# Send the time
time_as_bytes = "{}".format(datetime.now()).encode()
await nc.publish(msg.reply, time_as_bytes)
```

https://docs.nats.io/nats-concepts/core-nats

## JetStream

As of NATS Server 2.2, NATS JetStream is the recommended option.

NATS Streaming a.k.a. 'STAN' is now considered legacy.

https://docs.nats.io/reference/faq#jetstream-and-nats-streaming

---

- Stream: 儲存發佈的消息、重播訊息, 新增串流時，將詢問副本數
    `nats str add ORDERS --replicas 3`
- Consumer: 消費者可以被視為 stream 中的"視圖"，具有自己的"遊標"
    - Durable consumer
    - Ephemeral Consumer
    - Consumer Message Rates
    - FilterSubject: subject `factory-events.*.*` as `factory-events.<factory-id>.<event-type>`, filter `factory-events.A.*`
- Headers: 用於重複資料刪除、訊息自動清除、重新發布訊息等
- Key/Value Store
- Object Store

https://docs.nats.io/nats-concepts/jetstream

https://docs.nats.io/nats-concepts/jetstream/consumers#deliverpolicy

https://docs.nats.io/using-nats/developer/develop_jetstream/model_deep_dive#consumer-starting-position

https://docs.nats.io/using-nats/developer/develop_jetstream/consumers

## push vs pull

在 NATS 中，"pull" 與 "push" 是兩種不同的消息傳遞模型，它們分別具有不同的功能和特性：

https://docs.nats.io/using-nats/developer/develop_jetstream/consumers#push-and-pull-consumers

### Push 模型：
- 功能：在 "push" 模型中，消息的發送者將消息主動推送到特定的接收者，接收者被動地接收消息並進行處理。
- 特性：這種模型常用於即時通訊、事件通知等場景。在 NATS 中，nats pub 和 nats sub 命令用於實現 "push" 模型。

push consumers 擴展方式是 explicit, 需要建立不同的 queue group

queue group 有一個缺點是訊息的發布順序會遺失，因為訊息是並發處理的, 藉由設置 `MaxAckPending(1)` 只有一條訊息正在傳輸

[Grokking NATS Consumers: Push-based queue groups](https://www.byronruth.com/grokking-nats-consumers-part-2/)


### Pull 模型：
- 功能：在 "pull" 模型中，消息的接收者主動從消息源中拉取消息，通常是根據需要進行拉取，並對消息進行處理。
- 特性：這種模型常用於消息隊列、工作隊列等場景，其中接收者**主動控制消息的拉取速率**，可以根據處理能力來調整拉取速率。在 NATS 中，nats request 和 nats reply 命令可以用於實現 "pull" 模型。

pull consumers 擴展方式是 implicit, 只需建立相同名稱的 pull consumers 即可

訊息分發的控制權在訂閱者身上，可以將多個訂閱綁定到同一個 pull consumer 以同時獲取訊息。

[Grokking NATS Consumers: Pull-based](https://www.byronruth.com/grokking-nats-consumers-part-3/)


## Quality of service (QoS)

- At most once QoS:  
Core NATS

- At-least / exactly once QoS:  
NATS JetStream

https://docs.nats.io/nats-concepts/what-is-nats#nats-quality-of-service-qos

https://docs.nats.io/using-nats/developer/develop_jetstream/model_deep_dive#exactly-once-semantics

## Subject Mapping and Partitioning

NATS Server 2.8 (Apr 19, 2022)

Subject mapping 可以用於 分區獨立處理消息、金絲雀部署、A/B 測試、混沌測試、定義消息路由規則

在 Core NATS level，每個帳戶都有自己的一組 Subject Mapping

在 JetStream level，您可以將 Subject Mapping 定義為 stream config 的一部分


### Simple Mapping
```
nats server mapping foo bar
```

### Subject Token Reordering
```
nats server mapping "bar.*.*"  "baz.{{wildcard(2)}}.{{wildcard(1)}}"

bar.game.user -> bar.user.game
```

### Deterministic Subject token Partitioning

映射基於 hash，它的分佈是隨機的  
映射的鍵越多，每個分區的鍵的數量就越趨於收斂到相同的數量  
可以一次對多個 Subject token 進行分區  

```
nats server mapping "order.*.*" "order.{{wildcard(1)}}.{{partition(10,2)}}"

order.product1.user3 -> order.product1.5
order.product2.user2 -> order.product2.6
order.product3.user4 -> order.product3.0
order.product4.user2 -> order.product4.6
```

### Weighted Mappings

```
```

a "consumer" in JetStream is like a "partition" in Kafka.  
a "subscriber" in JetStream is like a "consumer" in Kafka.  

https://github.com/nats-io/nats-server/issues/2043#issuecomment-1150583322

https://natsbyexample.com/examples/jetstream/partitions/cli

https://docs.nats.io/nats-concepts/subject_mapping#deterministic-subject-token-partitioning

## nats client CLI

```
# 定義 context, admin 用戶
nats context save local-admin \
--server nats://127.0.0.1:4222,nats://127.0.0.1:4223,nats://127.0.0.1:4224 \
--user admin --password dot987#Root \
--description ''

# 定義 context, developer 用戶
nats context save local-dev \
--server nats://127.0.0.1:4222,nats://127.0.0.1:4223,nats://127.0.0.1:4224 \
--user devUser --password 123456 \
--description '' \
--select

# 查詢 context
nats ctx ls
nats ctx info

# 設定 default context
nats ctx select local-dev

# 查詢 account, 檢查是否有開啟 Jetstream
nats account info --context=local-dev

# 查詢 server, 需要 admin 權限
nats server ls --context=local-admin
nats server info --context=local-admin
nats server report jetstream --context=local-admin
```

https://github.com/nats-io/natscli?tab=readme-ov-file#configuration-contexts

https://docs.nats.io/using-nats/nats-tools/nats_cli#nats-contexts

https://docs.nats.io/using-nats/nats-tools


https://docs.nats.io/running-a-nats-service/configuration/clustering/jetstream_clustering/troubleshooting

## nats server config

查詢 nats cluster 資訊
```
localhost:8222
```

帳戶是相互隔離的  
DEV 中的使用者發佈的訊息  
對於 OPS 中的使用者不可見  

```
SysUser={user: "admin", password: "dot987#Root"}
accounts: {
    DEV: {
        jetstream: enabled,
        users: [ {user: "devUser", password: "123456"} ]
    },
    OPS: {
        jetstream: enabled,
        users: [ {user: "opsUser", password: "123456"} ]
    },

    SYS: {
        # Not allowed to enable JetStream on the system account
        users: [ $SysUser ]
    },
}
system_account: SYS
```

https://docs.nats.io/running-a-nats-service/configuration/securing_nats/accounts

https://docs.nats.io/running-a-nats-service/configuration/securing_nats/auth_intro

https://docs.nats.io/running-a-nats-service/configuration/securing_nats/authorization#variables

https://docs.nats.io/running-a-nats-service/nats_admin/security/jwt#system-account

https://docs.nats.io/running-a-nats-service/configuration/sys_accounts#local-configuration

https://docs.nats.io/running-a-nats-service/configuration/resource_management#setting-account-resource-limits

https://docs.nats.io/using-nats/nats-tools/nsc/basics#account-server-configuration

```
nats-server --signal reload
```
https://docs.nats.io/running-a-nats-service/nats_admin/signals

## cluster

```
cluster {
  name: demo-cluster

  authorization {
    user: "route_user"
    password: "T0pS3cr3t"
    timeout: 2
  }

  cluster_advertise: $CLUSTER_ADVERTISE

  port: 6222
  connect_retries: 20
  routes = [
    nats://route_user:T0pS3cr3t@nats0:6222,
    nats://route_user:T0pS3cr3t@nats1:6222,
    nats://route_user:T0pS3cr3t@nats2:6222,
  ]
}
```

https://docs.nats.io/running-a-nats-service/configuration/clustering

https://docs.nats.io/running-a-nats-service/configuration/clustering/cluster_config
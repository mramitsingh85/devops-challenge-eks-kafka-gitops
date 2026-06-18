# import os
# from kafka import KafkaConsumer
# import json


# kafka_broker = os.environ.get("KAFKA_BROKER_URL", "localhost:9093")
# kafka_topic = os.environ.get("KAFKA_TOPIC", "posts")

# consumer = KafkaConsumer(
#     kafka_topic,
#     bootstrap_servers=[kafka_broker],
#     auto_offset_reset="earliest",
#     value_deserializer=lambda m: json.loads(m.decode("utf-8")),
# )
# print(f"Listening for messages on topic '{kafka_topic}'...")

# for message in consumer:
#     print(f"Received message: {message.value}")

import os
import json
from kafka import KafkaConsumer

kafka_broker = os.environ.get(
    "KAFKA_BROKER_URL",
    "kafka:9092"
)

kafka_topic = os.environ.get(
    "KAFKA_TOPIC",
    "posts"
)

consumer = KafkaConsumer(
    kafka_topic,
    bootstrap_servers=[kafka_broker],
    auto_offset_reset="earliest",
    group_id="posts-consumer-group",
    value_deserializer=lambda m: json.loads(m.decode("utf-8")),
)

print(
    f"Listening for messages on topic '{kafka_topic}'...",
    flush=True
)

for message in consumer:
    print(
        f"Received message: {message.value}",
        flush=True
    )


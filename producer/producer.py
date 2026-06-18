import os
import json
import time
from datetime import datetime
from kafka import KafkaProducer
from kafka.errors import NoBrokersAvailable

kafka_broker = os.getenv("KAFKA_BROKER_URL", "kafka:9092")
kafka_topic = os.getenv("KAFKA_TOPIC", "posts")

producer = None

for attempt in range(10):
    try:
        producer = KafkaProducer(
            bootstrap_servers=[kafka_broker],
            value_serializer=lambda v: json.dumps(v).encode("utf-8"),
        )
        print("Connected to Kafka")
        break
    except NoBrokersAvailable as e:
        print(f"Attempt {attempt+1}: Kafka not ready: {e}")
        time.sleep(10)

if not producer:
    raise Exception("Failed to connect to Kafka")

for i in range(5):
    message = {
        "sender": "buildingminds",
        "content": f"message {i}",
        "created_at": datetime.now().isoformat(),
    }

    producer.send(kafka_topic, message)
    print(f"Sent: {message}")

producer.flush()
producer.close()

print("All messages delivered successfully")
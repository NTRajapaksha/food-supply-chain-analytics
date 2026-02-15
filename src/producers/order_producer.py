import pandas as pd
import json
import time
import random
from kafka import KafkaProducer
from datetime import datetime

# Configuration
KAFKA_TOPIC = "restaurant-orders"
KAFKA_SERVER = "kafka:29092"
DATA_FILE = "../../data/datasets/instacart/orders.csv" # Adjust path based on where you mount/store data

def json_serializer(data):
    return json.dumps(data).encode("utf-8")

def get_producer():
    return KafkaProducer(
        bootstrap_servers=[KAFKA_SERVER],
        value_serializer=json_serializer
    )

def simulate_stream():
    producer = get_producer()
    print(f"🚀 Starting Producer for topic: {KAFKA_TOPIC}")
    
    # For simulation, we generate dummy data since we can't easily read the CSV 
    # if it's not yet in the VM. In Phase 3 we will mount the CSV.
    # Here is a simulation loop:
    
    order_id_counter = 1000000
    
    try:
        while True:
            order = {
                "order_id": order_id_counter,
                "user_id": random.randint(1, 50000),
                "order_number": random.randint(1, 100),
                "order_dow": random.randint(0, 6),
                "order_hour_of_day": datetime.now().hour,
                "timestamp": datetime.now().isoformat(),
                "status": "PLACED"
            }
            
            producer.send(KAFKA_TOPIC, order)
            print(f"Sent Order: {order['order_id']}")
            
            order_id_counter += 1
            time.sleep(1) # Simulate 1 order per second
            
    except KeyboardInterrupt:
        print("Stopping producer...")
        producer.close()

if __name__ == "__main__":
    simulate_stream()

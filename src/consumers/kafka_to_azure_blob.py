import json
import time
import pandas as pd
from kafka import KafkaConsumer
from azure.storage.blob import BlobServiceClient
from io import BytesIO
from datetime import datetime

# --- Configuration ---
KAFKA_TOPIC = "restaurant-orders"
KAFKA_SERVER = "kafka:29092"  # Internal Docker address
AZURE_CONN_STR = "YOUR_CONNECTION_STRING_HERE"
CONTAINER_NAME = "bronze"
BATCH_SIZE = 10  # Number of records to buffer before writing to Blob

def get_blob_service_client():
    return BlobServiceClient.from_connection_string(AZURE_CONN_STR)

def upload_to_blob(df, filename):
    try:
        blob_service_client = get_blob_service_client()
        blob_client = blob_service_client.get_blob_client(container=CONTAINER_NAME, blob=filename)

        # Convert DataFrame to Parquet in memory
        parquet_buffer = BytesIO()
        df.to_parquet(parquet_buffer, index=False)
        parquet_buffer.seek(0)

        # Upload
        blob_client.upload_blob(parquet_buffer, overwrite=True)
        print(f"✅ Uploaded {filename} to Azure Blob ({len(df)} records)")
    except Exception as e:
        print(f"❌ Failed to upload to blob: {e}")

def consume_and_archive():
    print(f"🎧 Connecting to Kafka topic: {KAFKA_TOPIC}...")
    consumer = KafkaConsumer(
        KAFKA_TOPIC,
        bootstrap_servers=KAFKA_SERVER,
        auto_offset_reset='earliest',
        value_deserializer=lambda x: json.loads(x.decode('utf-8')),
        group_id='azure_archiver_group'
    )

    batch = []

    for message in consumer:
        batch.append(message.value)

        # If batch is full, write to Blob
        if len(batch) >= BATCH_SIZE:
            df = pd.DataFrame(batch)

            # Create a filename based on time: orders/YYYY/MM/DD/orders_TIMESTAMP.parquet
            now = datetime.now()
            folder_path = f"orders/{now.year}/{now.month:02d}/{now.day:02d}"
            filename = f"{folder_path}/orders_{int(now.timestamp())}.parquet"

            upload_to_blob(df, filename)

            # Clear batch
            batch = []

if __name__ == "__main__":
    consume_and_archive()

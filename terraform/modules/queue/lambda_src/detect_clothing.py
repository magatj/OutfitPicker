import json
import os
import uuid
import boto3
import logging
from datetime import datetime, timezone
from PIL import Image
import io

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

s3 = boto3.client("s3")
rekognition = boto3.client("rekognition")
dynamodb = boto3.resource("dynamodb")

TABLE_NAME = os.environ["DYNAMODB_TABLE"]
UPLOADS_BUCKET = os.environ["UPLOADS_BUCKET"]

CLOTHING_LABEL_MAP = {
    "Shirt": ("tops", "shirt"),
    "T-Shirt": ("tops", "t-shirt"),
    "Blouse": ("tops", "blouse"),
    "Sweater": ("tops", "sweater"),
    "Dress": ("dresses", "dress"),
    "Pants": ("bottoms", "pants"),
    "Jeans": ("bottoms", "jeans"),
    "Skirt": ("bottoms", "skirt"),
    "Shorts": ("bottoms", "shorts"),
    "Jacket": ("outerwear", "jacket"),
    "Coat": ("outerwear", "coat"),
    "Blazer": ("outerwear", "blazer"),
    "Shoe": ("footwear", "shoe"),
    "Sneaker": ("footwear", "sneaker"),
    "Boot": ("footwear", "boot"),
    "Sandal": ("footwear", "sandal"),
    "Handbag": ("accessories", "bag"),
    "Belt": ("accessories", "belt"),
    "Hat": ("accessories", "hat"),
    "Scarf": ("accessories", "scarf"),
    "Sunglasses": ("accessories", "sunglasses"),
}


def handler(event, context):
    for record in event["Records"]:
        body = json.loads(record["body"])
        process_job(body)


def process_job(body: dict):
    job_id = body["job_id"]
    user_id = body["user_id"]
    upload_id = body["upload_id"]
    s3_key = body["s3_key"]

    table = dynamodb.Table(TABLE_NAME)

    table.update_item(
        Key={"PK": f"JOB#{job_id}", "SK": "META"},
        UpdateExpression="SET #s = :s, processing_started_at = :t",
        ExpressionAttributeNames={"#s": "status"},
        ExpressionAttributeValues={
            ":s": "processing",
            ":t": datetime.now(timezone.utc).isoformat(),
        },
    )

    try:
        response = rekognition.detect_labels(
            Image={"S3Object": {"Bucket": UPLOADS_BUCKET, "Name": s3_key}},
            MaxLabels=50,
            MinConfidence=70,
        )

        raw_key = f"raw-outputs/jobs/{job_id}/rekognition_response.json"
        s3.put_object(
            Bucket=UPLOADS_BUCKET,
            Key=raw_key,
            Body=json.dumps(response),
            ContentType="application/json",
        )

        img_obj = s3.get_object(Bucket=UPLOADS_BUCKET, Key=s3_key)
        img_bytes = img_obj["Body"].read()
        image = Image.open(io.BytesIO(img_bytes)).convert("RGB")
        width, height = image.size

        items_created = 0

        for label in response["Labels"]:
            label_name = label["Name"]
            confidence = label["Confidence"] / 100.0

            if label_name not in CLOTHING_LABEL_MAP or confidence < 0.70:
                continue

            category, subcategory = CLOTHING_LABEL_MAP[label_name]
            item_id = f"item_{uuid.uuid4().hex[:20]}"

            cropped_key = None
            thumb_key = None
            instances = label.get("Instances", [])

            if instances:
                bb = instances[0]["BoundingBox"]
                left = int(bb["Left"] * width)
                top = int(bb["Top"] * height)
                right = int((bb["Left"] + bb["Width"]) * width)
                bottom = int((bb["Top"] + bb["Height"]) * height)

                pad_x = int((right - left) * 0.1)
                pad_y = int((bottom - top) * 0.1)
                left = max(0, left - pad_x)
                top = max(0, top - pad_y)
                right = min(width, right + pad_x)
                bottom = min(height, bottom + pad_y)

                cropped = image.crop((left, top, right, bottom))
                thumb = cropped.copy()
                thumb.thumbnail((200, 200))

                cropped_buf = io.BytesIO()
                cropped.save(cropped_buf, format="JPEG", quality=85)
                cropped_key = f"processed/items/{item_id}/cropped.jpg"
                s3.put_object(
                    Bucket=UPLOADS_BUCKET,
                    Key=cropped_key,
                    Body=cropped_buf.getvalue(),
                    ContentType="image/jpeg",
                )

                thumb_buf = io.BytesIO()
                thumb.save(thumb_buf, format="JPEG", quality=80)
                thumb_key = f"processed/items/{item_id}/thumb.jpg"
                s3.put_object(
                    Bucket=UPLOADS_BUCKET,
                    Key=thumb_key,
                    Body=thumb_buf.getvalue(),
                    ContentType="image/jpeg",
                )

            now = datetime.now(timezone.utc).isoformat()
            table.put_item(Item={
                "PK": f"USER#{user_id}",
                "SK": f"ITEM#{item_id}",
                "GSI1PK": f"UPLOAD#{upload_id}",
                "GSI1SK": f"ITEM#{item_id}",
                "entity_type": "wardrobe_item",
                "item_id": item_id,
                "user_id": user_id,
                "source_upload_id": upload_id,
                "s3_key_original": s3_key,
                "s3_key_cropped": cropped_key,
                "s3_key_thumbnail": thumb_key,
                "category": category,
                "subcategory": subcategory,
                "colors": [],
                "tags": [],
                "processing_status": "completed",
                "detection_confidence": round(confidence, 4),
                "ai_source": "aws_rekognition",
                "raw_ai_output_reference": raw_key,
                "user_corrected_values": {},
                "is_active": True,
                "created_at": now,
                "updated_at": now,
            })
            items_created += 1

        now = datetime.now(timezone.utc).isoformat()
        table.update_item(
            Key={"PK": f"JOB#{job_id}", "SK": "META"},
            UpdateExpression="SET #s = :s, processing_completed_at = :t",
            ExpressionAttributeNames={"#s": "status"},
            ExpressionAttributeValues={":s": "completed", ":t": now},
        )

        table.update_item(
            Key={"PK": f"USER#{user_id}", "SK": f"UPLOAD#{upload_id}"},
            UpdateExpression="SET processing_status = :s, items_detected_count = :c",
            ExpressionAttributeValues={":s": "completed", ":c": items_created},
        )

        logger.info(f"Job {job_id} complete. Items created: {items_created}")

    except Exception as e:
        logger.error(f"Job {job_id} failed: {e}", exc_info=True)
        table.update_item(
            Key={"PK": f"JOB#{job_id}", "SK": "META"},
            UpdateExpression="SET #s = :s, error_message = :e",
            ExpressionAttributeNames={"#s": "status"},
            ExpressionAttributeValues={":s": "failed", ":e": str(e)},
        )
        raise

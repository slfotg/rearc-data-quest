import json
import logging
import os

import boto3

logger = logging.getLogger()


def get_metadata(client):
    try:
        response = client.get_object(
            Bucket=os.environ["BUCKET_NAME"],
            Key=os.environ["METADATA_KEY"],
        )
        return json.loads(response["Body"].read())
    except client.exceptions.NoSuchKey:
        logger.info("No object found - returning empty")
        return dict()


def update_bls_data(event, context):

    s3_client = boto3.client("s3")

    logger.info(get_metadata(s3_client))

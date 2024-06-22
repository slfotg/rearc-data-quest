import json
import logging
import os
from urllib.parse import urljoin

import boto3
import requests
from bs4 import BeautifulSoup

logger = logging.getLogger()

BUCKET_NAME = os.environ["BUCKET_NAME"]
BASE_URL = os.environ["BASE_URL"]
USER_AGENT = os.environ["USER_AGENT"]
HEADERS = {"User-Agent": USER_AGENT}


def get_public_data() -> dict[str, object]:
    with requests.get(BASE_URL, headers=HEADERS) as response:
        response.raise_for_status()
        metadata = dict()
        soup = BeautifulSoup(response.content, features="html.parser")
        for element in soup.find_all("a")[1:]:
            url = urljoin(BASE_URL, element["href"])
            with requests.head(url, headers=HEADERS) as header_request:
                header_request.raise_for_status
                metadata[element.text] = {
                    "url": url,
                    "Last-Modified": header_request.headers["Last-Modified"],
                }
        return metadata


def download_to_s3(file_name: str, url: str, last_modified: str, s3_client):
    with requests.get(url, headers=HEADERS) as response:
        response.raise_for_status()
        content = response.content
        s3_client.put_object(
            Body=content,
            Bucket=BUCKET_NAME,
            Key=file_name,
            Metadata={"Last-Modified": last_modified},
        )


def get_metadata(client):
    try:
        response = client.get_object(
            Bucket=os.environ["BUCKET_NAME"],
        )
        return json.loads(response["Body"].read())
    except client.exceptions.NoSuchKey:
        logger.info("No object found - returning empty")
        return dict()


def update_bls_data(event, context):

    s3_client = boto3.client("s3")
    for file_name, meta in get_public_data().items():
        download_to_s3(file_name, meta["url"], meta["Last-Modified"], s3_client)


# s3_client = boto3.client("s3")
# bucket = "github-slfotg-rearc-data"
# response = s3_client.list_objects_v2(Bucket=os.environ["BUCKET_NAME"])
# # Bucket=bucket, Key="requirements.txt", Body=b"test", ContentType="text/plain", Metadata={"created": "Jun 22 2024"})

# for object in response["Contents"]:

#     attrs = s3_client.head_object(
#         Bucket=os.environ["BUCKET_NAME"], Key=object["Key"])
#     print(object["Key"], attrs["Metadata"])

# print(response["ResponseMetadata"])

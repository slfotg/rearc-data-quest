import json
import logging
import os
from urllib.parse import urljoin

import boto3
import requests
import yaml
from bs4 import BeautifulSoup

logger = logging.getLogger()
logger.setLevel("INFO")

BUCKET_NAME = os.environ["BUCKET_NAME"]
BASE_URL = os.environ["BASE_URL"]
USER_AGENT = os.environ["USER_AGENT"]
HEADERS = {"User-Agent": USER_AGENT}
KEY_PREFIX = "pr"
CONTENTS = "/".join([KEY_PREFIX, "contents.yaml"])


def get_public_data() -> dict[str, dict[str, str]]:
    with requests.get(BASE_URL, headers=HEADERS) as response:
        response.raise_for_status()
        metadata = dict()
        soup = BeautifulSoup(response.content, features="html.parser")
        for element in soup.find_all("a")[1:]:
            url = urljoin(BASE_URL, element["href"])
            metadata[element.text] = {
                "url": url,
                "info": element.previous_sibling.text,
            }
        return metadata


def download_to_s3(file_name: str, url: str, s3_client):
    logger.info("Downloading", url)
    with requests.get(url, headers=HEADERS) as response:
        response.raise_for_status()
        content = response.content
        s3_client.put_object(
            Body=content,
            Bucket=BUCKET_NAME,
            Key="/".join([KEY_PREFIX, file_name]),
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


def get_contents(s3_client) -> dict[str, dict[str, str]]:
    try:
        response = s3_client.get_object(Bucket=BUCKET_NAME, Key=CONTENTS)
        return yaml.safe_load(response["Body"])
    except s3_client.exceptions.NoSuchKey:
        logger.info("Contents Not Found - returning empty dict")
        return {}


def update_bls_data(event, context):

    s3_client = boto3.client("s3")
    current_files = get_contents(s3_client)
    logger.info(current_files)
    public_files = get_public_data()
    files_updated = False

    # figure out what to delete and delete those objects
    files_to_delete = set(current_files) - set(public_files)
    delete_objects = [
        {"Key": "/".join([KEY_PREFIX, file_name])} for file_name in files_to_delete
    ]
    if delete_objects:
        files_updated = True
        s3_client.delete_objects(Bucket=BUCKET_NAME, Delete={"Objects": delete_objects})

    # figure out what to download and download those files
    public_set = set(
        (file_name, meta["info"]) for file_name, meta in public_files.items()
    )
    current_set = set(
        (file_name, meta["info"]) for file_name, meta in current_files.items()
    )
    files_to_download = public_set - current_set
    for file_name, _ in files_to_download:
        files_updated = True
        download_to_s3(file_name, public_files[file_name]["url"], s3_client)

    if files_updated:
        s3_client.put_object(
            Body=yaml.dump(public_files),
            Bucket=BUCKET_NAME,
            Key=CONTENTS,
        )

import logging
import os
from urllib.parse import urljoin

import boto3
import requests
import yaml
from bs4 import BeautifulSoup

logger = logging.getLogger()
logger.setLevel("INFO")


def get_public_data(base_url: str, headers: dict) -> dict[str, dict[str, str]]:
    with requests.get(base_url, headers=headers) as response:
        response.raise_for_status()
        metadata = dict()
        soup = BeautifulSoup(response.content, features="html.parser")
        for element in soup.find_all("a")[1:]:
            url = urljoin(base_url, element["href"])
            metadata[element.text] = {
                "url": url,
                "info": element.previous_sibling.text,
            }
        return metadata


def download_to_s3(
    bucket_name: str,
    key_prefix: str,
    file_name: str,
    url: str,
    headers: dict,
    s3_client,
):
    logger.info("Downloading", url)
    with requests.get(url, headers=headers) as response:
        response.raise_for_status()
        content = response.content
        s3_client.put_object(
            Body=content,
            Bucket=bucket_name,
            Key="/".join([key_prefix, file_name]),
        )


def download_api_data(url: str, bucket_name: str, key_prefix: str, s3_client):
    api_params = {"drilldowns": "Nation", "measures": "Population"}
    with requests.get(url, api_params) as response:
        response.raise_for_status()
        content = response.content
        s3_client.put_object(
            Body=content,
            Bucket=bucket_name,
            Key="/".join([key_prefix, "data.json"]),
        )


def get_contents(bucket_name: str, key: str, s3_client) -> dict[str, dict[str, str]]:
    try:
        response = s3_client.get_object(Bucket=bucket_name, Key=key)
        return yaml.safe_load(response["Body"])
    except s3_client.exceptions.NoSuchKey:
        logger.info("Contents Not Found - returning empty dict")
        return {}


def update_data(event, context):

    bucket_name = os.environ["BUCKET_NAME"]
    base_url = os.environ["BASE_URL"]
    user_agent = os.environ["USER_AGENT"]
    headers = {"User-Agent": user_agent}
    key_prefix = "pr"
    contents = "/".join([key_prefix, "contents.yaml"])
    api_base_url = os.environ["API_BASE_URL"]

    s3_client = boto3.client("s3")
    current_files = get_contents(bucket_name, contents, s3_client)
    logger.info(current_files)
    public_files = get_public_data(base_url, headers)
    files_updated = False

    # figure out what to delete and delete those objects
    files_to_delete = set(current_files) - set(public_files)
    delete_objects = [
        {"Key": "/".join([key_prefix, file_name])} for file_name in files_to_delete
    ]
    if delete_objects:
        files_updated = True
        s3_client.delete_objects(Bucket=bucket_name, Delete={"Objects": delete_objects})

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
        download_to_s3(
            bucket_name,
            key_prefix,
            file_name,
            public_files[file_name]["url"],
            headers,
            s3_client,
        )

    download_api_data(api_base_url, bucket_name, key_prefix, s3_client)

    if files_updated:
        s3_client.put_object(
            Body=yaml.dump(public_files),
            Bucket=bucket_name,
            Key=contents,
        )

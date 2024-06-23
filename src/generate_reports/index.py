import json
import logging
import os
from urllib.parse import urljoin

import boto3
import polars as pl
import requests
from itables import to_html_datatable

logger = logging.getLogger()
logger.setLevel("INFO")

BUCKET_NAME = os.environ["BUCKET_NAME"]
BASE_URL = os.environ["BASE_URL"]
CURRENT_FILE = os.environ["CURRENT_FILE"]
JSON_FILE = os.environ["JSON_FILE"]


def get_current_df() -> pl.DataFrame:
    current_df = (
        pl.read_csv(urljoin(BASE_URL, CURRENT_FILE), separator="\t")
        .rename(lambda col: col.strip())
        .with_columns(
            pl.col("series_id").str.strip_chars(),
            pl.col("year"),
            pl.col("period").str.strip_chars(),
            pl.col("value").str.strip_chars().cast(pl.Float64()),
        )
    )
    return current_df


def get_json_df() -> pl.DataFrame:
    with requests.get(urljoin(BASE_URL, JSON_FILE)) as request:
        request.raise_for_status()
        return pl.DataFrame(json.loads(request.text)["data"])


def generate_report_1(json_df: pl.DataFrame) -> pl.DataFrame:
    return json_df.filter(
        (pl.col("ID Year") >= 2013) & (pl.col("ID Year") <= 2018)
    ).select(
        pl.first("Nation"),
        pl.mean("Population").alias("Average Population"),
        pl.std("Population").alias("Standard Deviation"),
    )


def generate_report_2(current_df: pl.DataFrame) -> pl.DataFrame:
    df = current_df.group_by("series_id", "year", maintain_order=True).agg(
        pl.col("value").sum()
    )

    return df.select(
        "series_id", "year", pl.col("value").max().over(["series_id"])
    ).join(df, on=["series_id", "year", "value"], how="inner")


def generate_report_3(current_df: pl.DataFrame, json_df: pl.DataFrame) -> pl.DataFrame:
    return (
        current_df.filter(
            (pl.col("series_id") == "PRS30006032") & (pl.col("period") == "Q01")
        )
        .join(
            json_df.with_columns(pl.col("ID Year").alias("year")),
            on=["year"],
            how="left",
            coalesce=True,
        )
        .select(["series_id", "year", "period", "value", "Population"])
    )


def write_dataframe_to_s3(bucket: str, key: str, df: pl.DataFrame, s3_client):
    logger.info(f"Writing dataframe to {bucket}/{key}")
    with pl.Config(tbl_rows=1000):
        logger.info(df)
    html = to_html_datatable(df, display_logo_when_loading=False)
    s3_client.put_object(Body=html, Bucket=bucket, Key=key, ContentType="text/html")


def generate_all_reports(event, context):
    current_df = get_current_df()
    json_df = get_json_df()

    report_1 = generate_report_1(json_df)
    report_2 = generate_report_2(current_df)
    report_3 = generate_report_3(current_df, json_df)

    s3_client = boto3.client("s3")
    write_dataframe_to_s3(BUCKET_NAME, "report_1.html", report_1, s3_client)
    write_dataframe_to_s3(BUCKET_NAME, "report_2.html", report_2, s3_client)
    write_dataframe_to_s3(BUCKET_NAME, "report_3.html", report_3, s3_client)

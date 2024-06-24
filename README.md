# Data Quest

This consists of 4 parts

## Part 1

There is a [lambda function](src/update_data/) that republishes
[this open dataset](https://download.bls.gov/pub/time.series/pr/) in Amazon S3.
This function runs daily to keep the data in sync.

The function keeps the data in sync with the public API by storing metadata about the files [here](https://github-slfotg-rearc-data.s3.us-east-2.amazonaws.com/pr/contents.yaml).

Currently the files that have been downloaded are listed below and are publicly available:
- [pr.class](https://github-slfotg-rearc-data.s3.us-east-2.amazonaws.com/pr/pr.class)
- [pr.contacts](https://github-slfotg-rearc-data.s3.us-east-2.amazonaws.com/pr/pr.contacts)
- [pr.data.0.Current](https://github-slfotg-rearc-data.s3.us-east-2.amazonaws.com/pr/pr.data.0.Current)
- [pr.data.1.AllData](https://github-slfotg-rearc-data.s3.us-east-2.amazonaws.com/pr/pr.data.1.AllData)
- [pr.duration](https://github-slfotg-rearc-data.s3.us-east-2.amazonaws.com/pr/pr.duration)
- [pr.footnote](https://github-slfotg-rearc-data.s3.us-east-2.amazonaws.com/pr/pr.footnote)
- [pr.measure](https://github-slfotg-rearc-data.s3.us-east-2.amazonaws.com/pr/pr.measure)
- [pr.period](https://github-slfotg-rearc-data.s3.us-east-2.amazonaws.com/pr/pr.period)
- [pr.seasonal](https://github-slfotg-rearc-data.s3.us-east-2.amazonaws.com/pr/pr.seasonal)
- [pr.sector](https://github-slfotg-rearc-data.s3.us-east-2.amazonaws.com/pr/pr.sector)
- [pr.series](https://github-slfotg-rearc-data.s3.us-east-2.amazonaws.com/pr/pr.series)
- [pr.txt](https://github-slfotg-rearc-data.s3.us-east-2.amazonaws.com/pr/pr.txt)

## Part 2

The same function from Part 1 also downloads data from [this API](https://datausa.io/api/data?drilldowns=Nation&measures=Population).
This is stored as a file called data.json in the same location as all files from Part 1.

This is replaced daily
- [data.json](https://github-slfotg-rearc-data.s3.us-east-2.amazonaws.com/pr/data.json)

## Part 3

This generates 3 reports and store the results and code are in [Analytics.ipynb](notebooks/Analytics.ipynb).

1. Using the dataframe from the population data API (Part 2),
   generate the mean and the standard deviation of the annual US population across the years [2013, 2018] inclusive.
2. Using the dataframe from the time-series (Part 1),
   For every series_id, find the *best year*: the year with the max/largest sum of "value" for all quarters in that year. Generate a report with each series id, the best year for that series, and the summed value for that year.
3. Using both dataframes from Part 1 and Part 2, generate a report that will provide the `value`
   for `series_id = PRS30006032` and `period = Q01` and the `population` for that given year (if available in the population dataset)

There is also a [lambda function](src/generate_reports/) that updates these reports when `data.json` is updated.

This function also publishes these reports in HTML format here:
- [report_1.html](https://github-slfotg-rearc-data.s3.us-east-2.amazonaws.com/report_1.html)
- [report_2.html](https://github-slfotg-rearc-data.s3.us-east-2.amazonaws.com/report_2.html)
- [report_3.html](https://github-slfotg-rearc-data.s3.us-east-2.amazonaws.com/report_3.html)

## Part 4

The final part deploying the lambdas discussed in the previous parts.

The infrastructure is setup with Terraform and the code is in the [terraform](terraform/) directory.

The deployment is done using Github Actions and the code is located [here](.github/workflows/main.yml)

## Contributing

This project is setup with devcontainers with all dependencies needed for development pre-installed.

Also pre-commit is installed and configured with various plugins to check python and terraform code.

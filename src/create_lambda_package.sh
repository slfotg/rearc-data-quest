#!/usr/bin/env sh

mkdir lambda_package
pip install --target ./lambda_package -r lambda-requirements.txt
cp -R lambda/* lambda_package

cd lambda_package
zip -r ../update_bls_data.zip .

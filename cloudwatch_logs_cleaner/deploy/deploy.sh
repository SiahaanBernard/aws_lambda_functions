#!/bin/bash

if [ ! -d "/tmp/function" ]; then
    echo "Creating /tmp/function directory"
    mkdir /tmp/function
else
    echo "Cleaning up /tmp/function directory"
    rm -rf /tmp/function/*
fi

cp ../lambda_function.yml /tmp/function

pip install -r ../requirements.txt -t /tmp/function
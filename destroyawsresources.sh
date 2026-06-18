#!/bin/bash

set -e

cd /Users/amit.singh/DevOps-Challenge-main

echo "Running destroy-all.sh..."
./destroy-all.sh

echo "Running destroy-all2.sh..."
./destroy-all2.sh

echo "All destroy operations completed."
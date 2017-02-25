#!/bin/bash

if [ ! -e Chart.yaml ]; then
  echo "No chart.yaml found. Quitting"
  exit 1
fi

cp -a ../common charts/
helm template .

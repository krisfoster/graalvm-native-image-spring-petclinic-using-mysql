#!/usr/bin/env bash

echo "Generating plot of memory & CPU profile data for openjdk"
python psrecord-plotutil.py ../target/logs/openjdk-prof.txt -o ../target/logs/openjdk-profplot.png
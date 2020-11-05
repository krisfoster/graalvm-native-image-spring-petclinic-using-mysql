#!/usr/bin/env bash

mvn install:install-file \
  -Dfile=./lib/ojdbc11.jar \
  -DgroupId=com.oracle.ojdbc \
  -DartifactId=ojdbc11 \
  -Dversion=beta \
  -Dpackaging=jar \
  -DgeneratePom=true
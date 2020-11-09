# Performance Report

## Overview

The Spring Boot Petclimnic sample has been used for performance testing.

## OpenJDK, JDK 11, Docker Alpine Image, Baseline

### Latency

![OpenJDK11, alpine running on Docker, Petclinic Latency Graph](./docker/openjdk11/load-latency.png)

### CPU & Memory Profiles

![OpenJDK11, alping running on Docker, Petclinic CPU & Memory Graph](./docker/openjdk11/profile.png)

## GraalVM 20.2.0, JDK 11, Native Image Running on Local Mac

### Latency

![Petclinic Latency Graph](./mac/ni/jdk11-no-pgo/load-latency.png)

### CPU & Memory Profiles

![Petclinic CPU & Memory Graph](./mac/ni/jdk11-no-pgo/profile.png)

## GraalVM 20.2.0, JDK 11, Native Image Running on Docker, OL

### Latency

![Petclinic Latency Graph](./docker/ni/jdk11-no-pgo/load-latency.png)

### CPU & Memory Profiles

![Petclinic CPU & Memory Graph](./docker/ni/jdk11-no-pgo/profile.png)



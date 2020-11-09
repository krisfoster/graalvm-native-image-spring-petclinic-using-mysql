# Performance Report

## Overview

The Spring Boot Petclimnic sample has been used for performance testing.

### Load Testing Params

* Load testng carried out with wrk2
* Plots generated with wrk2img
* THREADS=2
* CONNS=2
* DURRATION=120s
* Two runs, no warm-up of : 5, 10

## Baseline: OpenJDK 11 (Docker Alpine Image)

Constraints:

* Docker :
 * CPUS = 2
 * MEMORY = 500MB
* Application (JDK / Natve Image) :
 * -Xmx = 150MB 

### Latency

![OpenJDK11, alpine running on Docker, Petclinic Latency Graph](./docker/openjdk11/load-latency.png)

### CPU & Memory Profiles

Max Memory (RSS) : ~ 260 MB

![OpenJDK11, alping running on Docker, Petclinic CPU & Memory Graph](./docker/openjdk11/profile.png)



## Native Image (GraalVM 20.2.0, JDK 11, Docker Alpine)

Second run was with docker container constrained to 200MB

### Latency

![Petclinic Latency Graph](./docker/ni/alpine/v0/load-latency.png)

![Petclinic Latency Graph](./docker/ni/alpine/v1/load-latency.png)

### CPU & Memory Profiles

Max Memory (RSS) : ~ 160 MB

![Petclinic CPU & Memory Graph](./docker/ni/alpine/v0/profile.png)

![Petclinic CPU & Memory Graph](./docker/ni/alpine/v1/profile.png)





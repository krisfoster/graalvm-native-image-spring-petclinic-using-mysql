.PHONY: build

CURRENT_DIR=$$PWD

# Image versioning & labels
VER=1.0
DB_LABEL=oracle-db
IMAGE_NAME=krisfoster/petclinic-native-image

# DB conf
ORADB_IMAGE=store/oracle/database-enterprise:12.2.0.1-slim
ORADB_NAME=oradb01
ORACLE_SERVICE_NAME=orclpdb1.localdomain
ORACLE_PORT=1521

# Openjdk
OPENJDK_CONTAINER=docker-openjdk
DOCKER_CONTAINER=docker-ni
NATIVE_IMAGE_MAX_MEM=200m

# Constraints
MAX_MEM=500m
CPU=2


install-ojdbc:
	@echo "Installing fixed Oracle JDBC driver into local maven..."
	mvn install:install-file \
		-Dfile=./lib/ojdbc11.jar \
		-DgroupId=com.oracle.ojdbc \
		-DartifactId=ojdbc11 \
		-Dversion=beta \
		-Dpackaging=jar \
		-DgeneratePom=true

###############################################################
#
# Oracle Database Setup
#
# https://hub.docker.com/u/krisfoster/content/sub-298ecd52-962b-44a9-950a-d3d595a737e3
#
###############################################################

start-db: deploy-db config-db

deploy-db:
	@echo "Starting DB..."
	docker run --rm -d -it --name $(ORADB_NAME) -p 1521:1521 $(ORADB_IMAGE)
	until [ "$$( docker container inspect -f '{{.State.Status}}' $(ORADB_NAME) )" == "running" ]; do echo "." && sleep 2; done;
	sleep 101

config-db:
	@echo "Configuring DB..."
	# Note : the -i is very important!
	cat ./config.sql | docker exec -i $(ORADB_NAME) bash -c "source /home/oracle/.bashrc; sqlplus /nolog"

stop-db:
	@echo "Stopping DB..."
	docker kill $(ORADB_NAME)

###############################################################
#
# Build generic
#
###############################################################

# Build java code
package:
	./mvnw -ntp package -DskipTests

clean:
	./mvnw clean

###############################################################
#
# OpenJDK Baseline
#
###############################################################

# Build openjdk docker image
build-docker-openjdk: clean package
	@echo "Building openjdk container..."
	docker build -f ./Dockerfile-openjdk \
		--build-arg  ORACLE_USER="data_owner1" \
		--build-arg ORACLE_HOST=host.docker.internal \
		--build-arg ORACLE_SERVICE_NAME=orclpdb1.localdomain \
		-t $(IMAGE_NAME):$(VER).$(DB_LABEL).openjdk .

run-docker-openjdk:
	mkdir -p $(CURRENT_DIR)/reports/docker/openjdk11
	docker run --rm -d \
		--name $(OPENJDK_CONTAINER) \
		-e ORACLE_USER="data_owner1" \
		-e ORACLE_HOST="host.docker.internal" \
		-e ORACLE_SERVICE_NAME="orclpdb1.localdomain" \
		-e DEBUG=false \
		-p 8080:8080 \
		--memory=$(MAX_MEM) \
		--cpus=$(CPU) \
		-v $(CURRENT_DIR)/reports/docker/openjdk11:/reports \
		$(IMAGE_NAME):$(VER).$(DB_LABEL).openjdk

stop-docker-openjdk:
	docker kill $(OPENJDK_CONTAINER)

profile-docker-openjdk:
	mkdir -p ./reports/docker/openjdk11
#	rm ./reports/docker/openjdk11/*.dat
#	rm ./reports/docker/openjdk11/profile.prof
	docker run --rm -d \
		--name $(OPENJDK_CONTAINER) \
		-e ORACLE_USER="data_owner1" \
		-e ORACLE_HOST="host.docker.internal" \
		-e ORACLE_SERVICE_NAME="orclpdb1.localdomain" \
		-e DEBUG=false \
		-p 8080:8080 \
		--memory=$(MAX_MEM) \
		--cpus=$(CPU) \
		-v /Users/kfoster/repos/krf/graalvm-native-image-spring-petclinic-using-mysql/reports/docker/openjdk11:/reports \
		$(IMAGE_NAME):$(VER).$(DB_LABEL).openjdk
	sleep 20
	./scripts/load.sh ./reports/docker/openjdk11
	#docker kill $(OPENJDK_CONTAINER)

###############################################################
#
# Native Image Running on Host Machine
#
###############################################################

build-mac-native-image:
	./compile.sh

run-mac-native-image:
	REPORT_DIR=./reports/mac/ni/jdk11-no-pgo/
	mkdir -p $(REPORT_DIR)
	psrecord "./target/petclinic-jpa" --log $(REPORT_DIR)/profile.prof
	sleep 20s

profile-mac-ni:
	#REPORT_DIR:=./reports/mac/ni/jdk11-no-pgo/
	#echo $(REPORT_DIR)
	#
	mkdir -p ./reports/mac/ni/jdk11-no-pgo
	ORACLE_USER=data_owner1
	ORACLE_HOST=localhost
	ORACLE_SERVICE_NAME=orclpdb1.localdomain
	psrecord "./target/petclinic-jpa -Xmx$(NATIVE_IMAGE_MAX_MEM)" --log ./reports/mac/ni/jdk11-no-pgo/profile.prof &
	PET_ID=$$!
	sleep 20
	./scripts/load.sh ./reports/mac/ni/jdk11-no-pgo
	kill $$PET_ID

###############################################################
#
# Native Image Running on Docker
#
###############################################################

# Build Native image
build-docker-native-image: clean package
	@echo "Building native image container..."
	docker build -f Dockerfile-native-image \
		--build-arg ORACLE_USER="data_owner1" \
		--build-arg ORACLE_HOST=host.docker.internal \
		--build-arg ORACLE_SERVICE_NAME=orclpdb1.localdomain \
		-t $(IMAGE_NAME):$(VER).$(DB_LABEL).native-image .

# Build alpine container with exes in it
build-docker-alpine-native-image:
	@echo "Building ALPINE native image container..."
	docker build -f Dockerfile-alp \
		--build-arg ORACLE_USER="data_owner1" \
		--build-arg ORACLE_HOST=host.docker.internal \
		--build-arg ORACLE_SERVICE_NAME=orclpdb1.localdomain \
		-t alp:0.1 .

run-alp:
	mkdir -p $(CURRENT_DIR)/reports/docker/alp
	docker run --rm -it \
		--name $(DOCKER_CONTAINER) \
		-e ORACLE_USER="data_owner1" \
		-e ORACLE_HOST="host.docker.internal" \
		-e ORACLE_SERVICE_NAME="orclpdb1.localdomain" \
		-e DEBUG=false \
		-p 8080:8080 \
		--memory=$(MAX_MEM) \
		--cpus=$(CPU) \
		-v $(CURRENT_DIR)/reports/docker:/reports \
		alp:0.1 /bin/sh

run-docker-native-image:
	mkdir -p $(CURRENT_DIR)/reports/docker/ni/jdk11-no-pgo
	docker run --rm -d \
		--name $(DOCKER_CONTAINER) \
		-e ORACLE_USER="data_owner1" \
		-e ORACLE_HOST="host.docker.internal" \
		-e ORACLE_SERVICE_NAME="orclpdb1.localdomain" \
		-e DEBUG=false \
		-p 8080:8080 \
		--memory=$(MAX_MEM) \
		--cpus=$(CPU) \
		-v $(CURRENT_DIR)/reports/docker/ni/jdk11-no-pgo:/reports \
		$(IMAGE_NAME):$(VER).$(DB_LABEL).native-image

profile-docker-native-image:
	mkdir -p $(CURRENT_DIR)/reports/docker/ni/jdk11-no-pgo
	docker run --rm -d \
		--name $(DOCKER_CONTAINER) \
		-e ORACLE_USER="data_owner1" \
		-e ORACLE_HOST="host.docker.internal" \
		-e ORACLE_SERVICE_NAME="orclpdb1.localdomain" \
		-e DEBUG=false \
		-p 8080:8080 \
		--memory=$(MAX_MEM) \
		--cpus=$(CPU) \
		-v $(CURRENT_DIR)/reports/docker/ni/jdk11-no-pgo:/reports \
		$(IMAGE_NAME):$(VER).$(DB_LABEL).native-image
	sleep 20
	./scripts/load.sh  ./reports/docker/ni/jdk11-no-pgo
	docker kill $(DOCKER_CONTAINER)

stop-docker-native-image:
	docker kill $(DOCKER_CONTAINER)


klf:
	docker run --rm -it \
		--name $(DOCKER_CONTAINER) \
		-e ORACLE_USER="data_owner1" \
		-e ORACLE_HOST="host.docker.internal" \
		-e ORACLE_SERVICE_NAME="orclpdb1.localdomain" \
		-e DEBUG=false \
		-p 8080:8080 \
		--entrypoint "/bin/sh" \
		-v $(CURRENT_DIR)/reports/docker/ni/jdk11-no-pgo:/reports \
		krisfoster/fast:1.0

#################################################################
#
# Admin
#
#################################################################

push:
	docker login
	docker push $(image_name):$(VER).$(DB_LABEL)


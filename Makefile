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
		--build-arg ORACLE_HOST=host.docker.internal \
		--build-arg ORACLE_SERVICE_NAME=orclpdb1.localdomain \
		-t $(IMAGE_NAME):$(VER).$(DB_LABEL).openjdk .

run-docker-openjdk:
	mkdir -p $(CURRENT_DIR)/reports/docker/openjdk
	docker run --rm -d \
		--name $(OPENJDK_CONTAINER) \
		-m 1.25g \
		-e ORACLE_USER="data_owner1" \
		-e DEBUG=false \
		-p 8080:8080 \
		-v $(CURRENT_DIR)/reports/docker/openjdk11:/reports \
		$(IMAGE_NAME):$(VER).$(DB_LABEL).openjdk

stop-docker-openjdk:
	docker kill $(OPENJDK_CONTAINER)

profile-docker-openjdk:
	REPORT_DIR=./reports/mac/ni-ee/jdk11/
	echo "TODO"

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
	psrecord "./petclinic-jpa" --log $(REPORT_DIR)/profile.prof
	sleep 20s


profile-mac-graal-jit:
	REPORT_DIR=./reports/mac/jit/jdk11/
	echo "Report dir:: $(REPORT_DIR)"
	mkdir -p $(REPORT_DIR)
	#psrecord "java -jar target/petclinic-jpa-0.0.1-SNAPSHOT.jar" --log ./reports/mac/ni-ee/jdk11/profile.prof &
	#PET_ID=$!
	#sleep 20
	#./scripts/load.sh $REPORT_DIR
	#kill $PET_ID

###############################################################
#
# Native Image Running on Docker
#
###############################################################

# Build Native image
build-docker-native-image: clean package
	@echo "Building native image container..."
	docker build -f Dockerfile-native-image -t $(IMAGE_NAME):$(VER).$(DB_LABEL).native-image .

run-docker-native-image:
	mkdir -p $(CURRENT_DIR)/reports/docker/ni
	docker run --rm -it \
		--name $(DOCKER_CONTAINER) \
		-e ORACLE_USER="data_owner1" \
		-e DEBUG=false \
		-p 8080:8080 \
		-v $(CURRENT_DIR)/reports/docker/ni:/reports \
		$(IMAGE_NAME):$(VER).$(DB_LABEL).native-image /bin/sh

stop-docker-native-image:
	docker kill $(DOCKER_CONTAINER)

#################################################################
#
# Profiles
#
#################################################################


deploy:
	@echo "Deploying"
	@echo "Starting APP..."
	docker run --rm -it -p 8080:8080 \
        -e ORACLE_HOST=host.docker.internal \
        -e ORACLE_SERVICE_NAME=${ORACLE_SERVICE_NAME} \
        $(IMAGE_NAME):$(VER).$(DB_LABEL)

run:
	docker run --rm -it -P $(image_name):$(VER).$(DB_LABEL) /bin/sh

push:
	docker login
	docker push $(image_name):$(VER).$(DB_LABEL)


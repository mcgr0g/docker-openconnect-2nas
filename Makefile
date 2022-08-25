# VERSIONS ---------------------------------------------------------------------
IMG_VER=0.1.0
IMG_NAME=mcgr0g/openconnect-2nas
BUILD_DATE:=$(shell date '+%Y-%m-%d')

# BUILD FLAGS -----------------------------------------------------------------

BFLAGS=docker build \
		--build-arg img_ver=$(IMG_VER) \
		--build-arg build_date=$(BUILD_DATE) \
		-t $(IMG_NAME):$(IMG_VER)

BUILD_FAST=$(BFLAGS) .
BUILD_FULL=$(BFLAGS) --no-cache .

# IMAGE -----------------------------------------------------------------------

build:
	$(BUILD_FAST)
	
build-full:
	$(BUILD_FULL)

login:
	docker login

prepush:
	docker tag $(IMG_NAME):$(IMG_VER) $(IMG_NAME):latest

# First need to login.
push:
	docker push $(IMG_NAME):$(IMG_VER)
	docker push $(IMG_NAME)

pull:
	docker pull $(IMG_NAME)

# CONTAINER -------------------------------------------------------------------
CONTAINER_NAME=openconnect

simple:
	docker run --rm \
		--privileged \
		--sysctl net.ipv4.ip_forward=1 \
		-p 443:443 \
		-p 443:443/udp \
		--name $(CONTAINER_NAME) \
		$(IMG_NAME):$(IMG_VER)

container-flop:
	docker container run -it $(IMG_NAME):$(IMG_VER) /bin/bash

runner-flop:
	docker exec -it $(CONTAINER_NAME) /bin/bash
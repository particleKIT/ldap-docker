# makefile for testing stuff
#
# its optimized for use in a NFS
# environment that uses root_squash
#

NAME=local/ldap
DIR=ldap

.PHONY: all build build-nocache run 

all: build

build:
	mkdir -p /tmp/$(DIR)
	rsync -av $(PWD)/* /tmp/$(DIR) && \
	sudo chown -R root:root /tmp/$(DIR) &&\
	sudo docker build -t $(NAME) -f /tmp/$(DIR)/Dockerfile /tmp/$(DIR)
	sudo rm -rf /tmp/$(DIR)	

run:
	sudo docker run --name=test -ti --rm $(NAME) bash


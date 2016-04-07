#!/usr/bin/env make

GIT_ROOT:=$(shell git rev-parse --show-toplevel)

# Default target specification
run:

.PHONY: docker-images mpc mpc-dist aws aws-dist

########## UTILITY TARGETS ##########

clean:
	${GIT_ROOT}/make/clean

reap:
	${GIT_ROOT}/make/reap

clean-harder: clean reap

all: images tag terraform

print-version:
	@ ${GIT_ROOT}/make/print-version

########## VAGRANT VM TARGETS ##########

run:
	${GIT_ROOT}/make/run

stop:
	${GIT_ROOT}/make/stop

vagrant-box:
	${GIT_ROOT}/make/vagrant-box

vagrant-prep: \
	compile-base \
	releases \
	compile \
	image-base \
	images \
	${NULL}

registry:
	${GIT_ROOT}/make/registry

########## BOSH RELEASE TARGETS ##########

cf-release:
	${GIT_ROOT}/make/bosh-release src/cf-release

usb-release:
	${GIT_ROOT}/make/bosh-release src/cf-usb-release

diego-release:
	${GIT_ROOT}/make/bosh-release src/diego-release

etcd-release:
	${GIT_ROOT}/make/bosh-release src/etcd-release

garden-release:
	${GIT_ROOT}/make/bosh-release src/garden-linux-release

mysql-release:
	${GIT_ROOT}/make/bosh-release src/cf-mysql-release

hcf-deployment-hooks:
	${GIT_ROOT}/make/bosh-release src/hcf-deployment-hooks

windows-runtime-release:
	${GIT_ROOT}/make/bosh-release src/windows-runtime-release

releases: cf-release usb-release diego-release etcd-release garden-release mysql-release hcf-deployment-hooks windows-runtime-release

########## FISSILE BUILD TARGETS ##########

compile-base:
	${GIT_ROOT}/make/compile-base

# This is run from the Vagrantfile to copy in the existing compilation cache
copy-compile-cache:
	${GIT_ROOT}/make/compile restore

compile:
	${GIT_ROOT}/make/compile

images: bosh-images docker-images

image-base:
	${GIT_ROOT}/make/image-base

bosh-images:
	${GIT_ROOT}/make/bosh-images

docker-images:
	${GIT_ROOT}/make/images docker build

build: images

tag: bosh-tag docker-tag

bosh-tag:
	${GIT_ROOT}/make/images bosh tag

docker-tag:
	${GIT_ROOT}/make/images docker tag

publish: bosh-publish docker-publish

bosh-publish:
	${GIT_ROOT}/make/images bosh publish

docker-publish:
	${GIT_ROOT}/make/images docker publish

show-docker-setup:
	${GIT_ROOT}/make/show-docker-setup

########## CONFIGURATION TARGETS ##########

generate: ucp mpc aws

ucp:
	${GIT_ROOT}/make/generate ucp

mpc:
	${GIT_ROOT}/make/generate mpc

aws:
	${GIT_ROOT}/make/generate aws

aws-proxy:
	${GIT_ROOT}/make/generate aws-proxy

########## DISTRIBUTION TARGETS ##########

dist: mpc-dist aws-dist

mpc-dist: mpc
	${GIT_ROOT}/make/package-terraform mpc

aws-dist: aws
	${GIT_ROOT}/make/package-terraform aws

aws-proxy-dist: aws-proxy
	$(call print_status, Package AWS with proxy terraform configuration for distribution)
	@base=$$(mktemp -d aws_XXXXXXXXXX) && \
	mkdir -p $$base/aws-proxy/terraform && \
	cp -rf container-host-files terraform/aws.tfvars.example terraform/aws-proxy.tf terraform/README-aws.md hcf-aws-proxy.tf.json $$base/aws-proxy/ && \
	cp terraform/proxy.conf terraform/proxy-setup.sh $$base/aws-proxy/terraform/ && \
	( cd $$base && zip -r9 ${CURDIR}/aws-proxy-$(APP_VERSION).zip aws-proxy ) && \
	rm -rf $$base && \
	echo Generated aws-proxy-$(APP_VERSION).zip

mpc-terraform-tests:
	${GIT_ROOT}/make/mpc-terraform-tests

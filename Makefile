#!make
include .env
export $(shell sed 's/=.*//' .env)

.PHONY: all verify identity vm create cleanup

all: create

verify:
	scripts/verify.sh

identity:
	scripts/identity.sh

vm:
	scripts/vm.sh

create: verify identity vm

cleanup:
	scripts/cleanup.sh


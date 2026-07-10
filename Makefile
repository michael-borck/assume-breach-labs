.PHONY: help pull-base build-base m00 m01 m02 m03 m04 m05 m06 m07 m08 m09 stop down status

# Shared toolbox image. Default is the prebuilt GHCR image (just pull it).
# Override to build locally: `make build-base`.
BASE_IMAGE ?= ghcr.io/michael-borck/assume-breach-base:latest
COMPOSE    ?= docker compose

help:
	@echo "Assume Breach Labs"
	@echo ""
	@echo "  make pull-base     Pull the shared toolbox image from GHCR"
	@echo "  make build-base    Build the toolbox image locally instead"
	@echo "  make mNN           Start module NN (e.g. make m07)"
	@echo "  make stop          Stop all running lab containers"
	@echo "  make down          Stop and remove containers + networks"
	@echo "  make status        Show which modules are ready"
	@echo ""
	@echo "On an exFAT/external drive, if a local build fails on '._' files:"
	@echo "  DOCKER_BUILDKIT=0 make build-base"

pull-base:
	docker pull $(BASE_IMAGE)

build-base:
	docker build -f base.Dockerfile -t $(BASE_IMAGE) .

# --- Module runners -------------------------------------------------------
# Each starts exactly one module's profile from the single docker-compose.yml.

define RUN_MODULE
	@echo "==> Starting module $(1)"
	$(COMPOSE) --profile module-$(1) up -d --build
	@echo "==> Up. See modules/module-$(1)-*/LAB-GUIDE.md"
endef

m00:
	@echo "Module 00 is setup docs only — open modules/module-00-setup/README.md"

m01:
	@echo "Module 01 not built yet."
m02:
	@echo "Module 02 not built yet."
m03:
	@echo "Module 03 not built yet."
m04:
	@echo "Module 04 not built yet."
m05:
	@echo "Module 05 not built yet."
m06:
	@echo "Module 06 not built yet."
m07:
	$(call RUN_MODULE,07)
m08:
	@echo "Module 08 not built yet."
m09:
	@echo "Module 09 not built yet."

stop:
	$(COMPOSE) stop

down:
	$(COMPOSE) --profile module-07 down --remove-orphans

status:
	@echo "Assume Breach Labs — module availability:"
	@echo "  module-00: setup docs (modules/module-00-setup/README.md)"
	@echo "  module-07: ready       (make m07)"
	@echo "  others:    planned"

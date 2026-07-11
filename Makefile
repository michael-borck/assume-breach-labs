.PHONY: help pull-base build-base m00 m01 m02 m03 m04 m05 m06 m07 m08 m09 m10 stop down status

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

# Build first, then up (no --build): several services can share one image tag,
# and the legacy builder races if it builds them in parallel during `up --build`.
define RUN_MODULE
	@echo "==> Starting module $(1)"
	$(COMPOSE) --profile module-$(1) build
	$(COMPOSE) --profile module-$(1) up -d
	@echo "==> Up. See modules/module-$(1)-*/LAB-GUIDE.md  (or use ./start.sh)"
endef

m00:
	@echo "Module 00 is setup docs only — open modules/module-00-setup/README.md"

m01:
	$(call RUN_MODULE,01)
m02:
	$(call RUN_MODULE,02)
m03:
	$(call RUN_MODULE,03)
m04:
	$(call RUN_MODULE,04)
m05:
	$(call RUN_MODULE,05)
m06:
	$(call RUN_MODULE,06)
m07:
	$(call RUN_MODULE,07)
m08:
	$(call RUN_MODULE,08)
m09:
	$(call RUN_MODULE,09)
m10:
	$(call RUN_MODULE,10)

stop:
	$(COMPOSE) stop

down:
	$(COMPOSE) --profile module-01 --profile module-02 --profile module-03 --profile module-04 --profile module-05 --profile module-06 --profile module-08 --profile module-09 --profile module-07 down --remove-orphans

status:
	@echo "Assume Breach Labs — module availability:"
	@echo "  module-00: setup docs (modules/module-00-setup/README.md)"
	@echo "  module-01: ready       (make m01  /  ./start.sh)"
	@echo "  module-02: ready       (make m02  /  ./start.sh)"
	@echo "  module-03: ready       (make m03  /  ./start.sh)"
	@echo "  module-04: ready       (make m04  /  ./start.sh)"
	@echo "  module-05: ready       (make m05  /  ./start.sh)"
	@echo "  module-06: ready       (make m06  /  ./start.sh)"
	@echo "  module-07: ready       (make m07  /  ./start.sh)"
	@echo "  module-08: ready       (make m08  /  ./start.sh)"
	@echo "  module-09: ready       (make m09  /  ./start.sh)"
	@echo "  others:    planned"

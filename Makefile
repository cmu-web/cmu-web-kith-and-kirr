# The everyday commands; `make` lists them. Written for GNU Make 3.81, the
# version macOS ships. PORT changes the port; containers run with Docker, or
# Podman when Docker isn't installed (ENGINE=podman picks Podman).
.DEFAULT_GOAL := help
.PHONY: help setup build run restart seed down wipe check docs

PORT ?= 5300
export PORT
ENGINE ?= $(shell command -v docker >/dev/null 2>&1 && echo docker || echo podman)
export ENGINE
COMPOSE = $(ENGINE) compose -f dev/compose.yaml
IMAGE = i2incommon/grouper:7.9.1
URL = http://127.0.0.1:$(PORT)/grouper/grouperUi/app/UiV2Main.index?operation=UiV2Main.indexMain
CSRF = /opt/grouper/grouperWebapp/WEB-INF/classes/Owasp.CsrfGuard.overlay.properties
DATA = dev/data/grouper-ui.properties dev/data/grouper.text.en.us.properties \
	dev/data/grouper.properties dev/data/Owasp.CsrfGuard.overlay.properties

help: ## List the targets
	@awk 'BEGIN {FS = ":.*## "} /^[a-z]+:.*## / {printf "  make %-8s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Install the build's dependencies
	npm ci

build: ## Build grouper/ from src/
	npm run build

run: $(DATA) ## Start Grouper with the theme and load the demo structure
	python3 dev/load.py --settings-only
	$(COMPOSE) up -d
	dev/wait-for-url.sh "$(URL)"
	python3 dev/load.py
	@echo "Grouper: http://127.0.0.1:$(PORT)/grouper/"

restart: $(DATA) ## Rewrite the settings files and restart Grouper
	$(COMPOSE) restart grouper
	dev/wait-for-url.sh "$(URL)"

seed: ## Load the demo structure again, replacing what's there
	python3 dev/load.py

down: ## Stop Grouper and keep its database
	$(COMPOSE) down

wipe: ## Stop Grouper and delete its database
	$(COMPOSE) down -v
	rm -rf dev/data

check: ## The everyday check: grouper/ matches a fresh build
	npm run check

docs: ## Build the docs site into docs/_site
	dev/site.sh

# Grouper's settings files: the theme's lines plus the development ones.
# cat > keeps each file's inode, so a running container sees the change.
dev/data/grouper-ui.properties: grouper/properties/grouper-ui.properties dev/conf/grouper-ui.dev.properties
	@mkdir -p dev/data
	cat $^ > $@

dev/data/grouper.text.en.us.properties: grouper/properties/grouper.text.en.us.properties demo/grouper.text.en.us.properties
	@mkdir -p dev/data
	cat $^ > $@

# Written once; dev/load.py writes the demo's settings into it
dev/data/grouper.properties:
	@mkdir -p dev/data
	cat dev/conf/grouper.properties > $@

# The CSRFGuard file Grouper ships, with the theme's line added
dev/data/Owasp.CsrfGuard.overlay.properties: grouper/properties/Owasp.CsrfGuard.overlay.properties
	@mkdir -p dev/data
	$(ENGINE) run --rm --entrypoint cat $(IMAGE) $(CSRF) > $@.stock
	cat $@.stock $< > $@
	rm $@.stock

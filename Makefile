.PHONY: help install test start.dev start.prod typespec setup.env reset.env

help:
	@echo "Available targets:"
	@echo "  install     - install dependencies (Elixir + npm)"
	@echo "  test        - run all tests"
	@echo "  start.dev   - start dev server (Phoenix + LiveReloader)"
	@echo "  start.prod  - start production server (Docker Compose)"
	@echo "  typespec    - compile TypeSpec → OpenAPI"
	@echo "  setup.env   - create .env from .env.example and symlink to .devcontainer/"
	@echo "  reset.env   - remove .env and symlink"

setup.env:
	@if [ ! -f .env ]; then \
		echo "[setup.env] Creating .env from .env.example..."; \
		cp .env.example ${DEV_PATH}; \
		echo "[setup.env] Generating SECRET_KEY_BASE..."; \
		SECRET_KEY_BASE=$$(openssl rand -hex 32); \
		sed -i "s|^SECRET_KEY_BASE=.*|SECRET_KEY_BASE=$$SECRET_KEY_BASE|" ${DEV_PATH}; \
		echo "[setup.env] Done."; \
	else \
		echo "[setup.env] .env already exists, skipping."; \
	fi

reset.env:
	@echo "[reset.env] Removing .env..."
	@rm -f .devcontainer/.env
	@echo "[reset.env] Done."

install: setup.env
	mix deps.get
	mix compile
	cd api/typespec && npm install

test:
	mix test

start.dev:
	docker compose up -d postgres
	mix phx.server

start.prod:
	docker compose up -d --build

typespec:
	mkdir -p priv/api
	cd api/typespec && npx tsp compile . --emit @typespec/openapi3
	cp -f api/typespec/tsp-output/@typespec/openapi3/openapi.yaml priv/api/openapi.yaml
	

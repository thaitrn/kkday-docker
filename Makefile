.PHONY: help dev dev-build dev-down prod prod-build prod-down logs ps clean

APP_NAME := kkday-b2d-internagent

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

# --- Development ---

dev: ## Start app in development mode (hot reload)
	docker compose -f docker-compose.dev.yml up

dev-build: ## Build and start app in development mode
	docker compose -f docker-compose.dev.yml up --build

dev-down: ## Stop development containers
	docker compose -f docker-compose.dev.yml down

# --- Production ---

prod: ## Start app in production mode
	docker compose -f docker-compose.yml up -d

prod-build: ## Build and start app in production mode
	docker compose -f docker-compose.yml up -d --build

prod-down: ## Stop production containers
	docker compose -f docker-compose.yml down

# --- Utilities ---

logs: ## Tail logs (usage: make logs ENV=dev or make logs ENV=prod)
	@if [ "$(ENV)" = "dev" ]; then \
		docker compose -f docker-compose.dev.yml logs -f; \
	else \
		docker compose -f docker-compose.yml logs -f; \
	fi

ps: ## Show running containers
	docker compose ps

clean: ## Remove containers, images, and volumes
	docker compose -f docker-compose.dev.yml down --rmi local --volumes --remove-orphans
	docker compose -f docker-compose.yml down --rmi local --volumes --remove-orphans

# Stanford Students API Makefile

# Variables
DOCKER_NETWORK = stanford-network
DB_CONTAINER = stanford-postgres
APP_CONTAINER = stanford-app
APP_IMAGE = stanford-students-api
DB_NAME = stanford_students
DB_USER = postgres
DB_PASSWORD = postgres

# Docker Compose command detection
DOCKER_COMPOSE := $(shell command -v docker-compose 2> /dev/null || command -v docker 2> /dev/null && echo "docker compose")

# Default target
.PHONY: help
help:
	@echo "Stanford Students API - Available targets:"
	@echo "  start-db      - Start PostgreSQL database container"
	@echo "  migrate       - Run database migrations"
	@echo "  build-api     - Build REST API docker image"
	@echo "  run-api       - Run REST API docker container"
	@echo "  start-all     - Start database and API containers"
	@echo "  stop-all      - Stop and remove all containers"
	@echo "  status        - Show container status"
	@echo "  logs          - Show application logs"
	@echo "  clean         - Remove containers, network and volumes"

# Create Docker network
.PHONY: network
network:
	@docker network create $(DOCKER_NETWORK) 2>/dev/null || echo "Network already exists"

# Start PostgreSQL database container
.PHONY: start-db
start-db: network
	@echo "🐘 Starting PostgreSQL database container..."
	@docker stop $(DB_CONTAINER) 2>/dev/null || true
	@docker rm $(DB_CONTAINER) 2>/dev/null || true
	@docker run -d \
		--name $(DB_CONTAINER) \
		--network $(DOCKER_NETWORK) \
		-e POSTGRES_DB=$(DB_NAME) \
		-e POSTGRES_USER=$(DB_USER) \
		-e POSTGRES_PASSWORD=$(DB_PASSWORD) \
		-p 5432:5432 \
		-v stanford_postgres_data:/var/lib/postgresql/data \
		postgres:15-alpine
	@echo "⏳ Waiting for PostgreSQL to be ready..."
	@sleep 10
	@until docker exec $(DB_CONTAINER) pg_isready -U $(DB_USER); do \
		echo "Waiting for PostgreSQL..."; \
		sleep 2; \
	done
	@echo "✅ PostgreSQL is ready!"

# Run database migrations
.PHONY: migrate
migrate:
	@echo "🔄 Running database migrations..."
	@docker exec $(DB_CONTAINER) psql -U $(DB_USER) -d $(DB_NAME) -c "\
		CREATE TABLE IF NOT EXISTS students ( \
			id SERIAL PRIMARY KEY, \
			first_name VARCHAR(100) NOT NULL, \
			last_name VARCHAR(100) NOT NULL, \
			email VARCHAR(100) UNIQUE NOT NULL, \
			major VARCHAR(100) NOT NULL, \
			gpa DECIMAL(3,2) CHECK (gpa >= 0.0 AND gpa <= 4.0), \
			enrollment_date DATE, \
			graduation_year INT, \
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, \
			updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP \
		);"
	@echo "✅ Database migrations completed!"

# Build REST API docker image
.PHONY: build-api
build-api:
	@echo "🔨 Building REST API docker image..."
	@docker build -t $(APP_IMAGE) .
	@echo "✅ API image built successfully!"

# Check if database container is running
.PHONY: check-db
check-db:
	@if ! docker ps --filter "name=$(DB_CONTAINER)" --filter "status=running" | grep -q $(DB_CONTAINER); then \
		echo "⚠️  Database container not running. Starting database..."; \
		make start-db; \
	else \
		echo "✅ Database container is already running"; \
	fi

# Check if migrations have been applied
.PHONY: check-migrations
check-migrations:
	@if ! docker exec $(DB_CONTAINER) psql -U $(DB_USER) -d $(DB_NAME) -c "SELECT 1 FROM students LIMIT 1;" >/dev/null 2>&1; then \
		echo "⚠️  Database migrations not applied. Running migrations..."; \
		make migrate; \
	else \
		echo "✅ Database migrations already applied"; \
	fi

# Run REST API docker container with dependencies
.PHONY: run-api
run-api: check-db check-migrations
	@echo "🚀 Starting REST API container with docker-compose..."
	@$(DOCKER_COMPOSE) down app 2>/dev/null || true
	@$(DOCKER_COMPOSE) up -d app
	@echo "⏳ Waiting for API to start..."
	@sleep 5
	@echo "✅ API container started!"
	@echo "📱 Frontend: http://localhost:8080"
	@echo "🔗 API: http://localhost:8080/api/v1"
	@echo "💚 Health: http://localhost:8080/healthcheck"

# Start all services
.PHONY: start-all
start-all: run-api
	@echo "🎉 All services started successfully!"

# Show container status
.PHONY: status
status:
	@echo "📊 Container Status:"
	@$(DOCKER_COMPOSE) ps

# Show application logs
.PHONY: logs
logs:
	@echo "📝 Application Logs:"
	@$(DOCKER_COMPOSE) logs -f app

# Stop all containers
.PHONY: stop-all
stop-all:
	@echo "🛑 Stopping all containers..."
	@$(DOCKER_COMPOSE) down
	@echo "✅ All containers stopped!"

# Clean up everything
.PHONY: clean
clean:
	@echo "🧹 Cleaning up..."
	@$(DOCKER_COMPOSE) down -v --rmi all
	@echo "✅ Cleanup completed!"
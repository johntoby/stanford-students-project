# Stanford University Students API

A RESTful API for managing Stanford University Computer Science students built with Golang and Gin framework. This project is a solution to the ONE2N SRE Bootcamp, that aims to provide the entire DevOps journey from planning to buuilding to shiping an app into prod. I hope this helps someone navigating the bootcamp to get the right solution.

The roject starts by building the aplication source code from scratch, with the backend api built first, tested with a postman collection for the different routes, and a simple UI was added for visibility. The application was tested locally, then migrated to normal docker containers, then to docker compose, then kubernetes. It follows a logical progression of features and infrastructure complexity that occurs when an application scales. 

## Features

- CRUD operations for student records
- API versioning
- Proper HTTP verbs for different operations
- Meaningful logs with appropriate log levels
- Health check endpoint
- Unit tests
- Database migrations
- Environment-based configuration

## Prerequisites

### For Local Development:
- Go 1.21 or higher
- PostgreSQL database
- Git

### For Docker Deployment:
- **Docker** (version 20.10 or higher)
- **Docker Compose** (version 2.0 or higher)
- **Make** (GNU Make utility)
- **Git**

#### Automated Installation:

I have prepared an installation script to automatically all the required prerequisites necessary for this application to run. It is locatd in /install-prerequisites.sh 

```bash
# Download and run the installation script
curl -fsSL https://raw.githubusercontent.com/your-repo/stanford-students-project/main/install-prerequisites.sh | bash

# Or clone the repo first and run locally
git clone <repository-url>
cd stanford-students-project
chmod +x install-prerequisites.sh
./install-prerequisites.sh
```

#### Manual Installation Commands:
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install docker.io docker-compose make git

# CentOS/RHEL
sudo yum install docker docker-compose make git

# macOS (with Homebrew)
brew install docker docker-compose make git

# Verify installations
docker --version
docker-compose --version
make --version
```

## Installation

1. Clone the repository:
   ```
   git clone <repository-url>
   cd stanford-uni-students-api
   ```

2. Install dependencies:
   ```
   go mod download
   ```

3. Set up environment variables:
   - Copy the `.env.example` file to `.env` and update the values:
   ```
   cp .env.example .env
   ```
   - Edit the `.env` file with your database credentials



## Running the API

### Option 1: Using Helm Charts (Kubernetes - Recommended for Production)

#### Prerequisites:
- Kubernetes cluster (minikube, kind, or cloud provider)
- Helm 3.x installed
- kubectl configured

#### Quick Deployment:
```bash
# Deploy the entire stack with Helm
cd helm
chmod +x deploy.sh
./deploy.sh
```

#### Manual Helm Deployment:
```bash
# Update dependencies
cd helm/stanford-students-stack
helm dependency update
cd ..

# Deploy the stack
helm install stanford-students-stack ./stanford-students-stack \
  --namespace student-api \
  --create-namespace \
  --wait

# Check status
kubectl get pods -n student-api
```

#### Cleanup:
```bash
cd helm
./cleanup.sh
```

**Note:** See [helm/README.md](helm/README.md) for detailed Helm deployment instructions.

### Option 2: Using Make (Docker - Recommended for Development)


#### Quick Start:
```bash
# Start everything (database + migrations + API)
make run-api
```

#### Step-by-step execution:
```bash
# 1. Start database container
make start-db

# 2. Run database migrations
make migrate

# 3. Build API docker image
make build-api

# 4. Run API container (with dependency checks)
make run-api
```

#### Available Make Targets:
```bash
# Core targets
make start-db      # Start PostgreSQL database container
make migrate       # Run database DML migrations
make build-api     # Build REST API docker image
make run-api       # Run REST API container (auto-handles dependencies)

# Utility targets
make start-all     # Start all services (same as run-api)
make status        # Show container status
make logs          # View application logs
make stop-all      # Stop all containers
make clean         # Remove containers, networks, and volumes
make help          # Show all available targets
```

#### Execution Order:
The `run-api` target automatically handles dependencies in this order:
1. **Check Database**: Verifies if database container is running (starts if needed)
2. **Check Migrations**: Verifies if migrations are applied (runs if needed)
3. **Start API**: Uses docker-compose to start the API container

### Option 3: Using Docker Compose

```bash
# Start all services
docker-compose up --build

# Stop services
docker-compose down
```

### Option 4: Manual Setup (Local Development)

1. Start PostgreSQL database
2. Run: `go run main.go`

### Access Points:
- **Frontend**: `http://localhost:8080`
- **API**: `http://localhost:8080/api/v1`
- **Health Check**: `http://localhost:8080/healthcheck`

## Frontend Interface

The application now includes a web-based frontend interface accessible at `http://localhost:8080`. The frontend provides:

- **Students List**: View all registered students
- **Add Student**: Form to add new students
- **Edit Student**: Update existing student information
- **Delete Student**: Remove students from the system

## API Endpoints

### Health Check
- `GET /healthcheck` - Check if the API is running

### Student Operations
- `POST /api/v1/students` - Create a new student
- `GET /api/v1/students` - Get all students
- `GET /api/v1/students/:id` - Get a student by ID
- `PUT /api/v1/students/:id` - Update a student
- `DELETE /api/v1/students/:id` - Delete a student

## Testing

Run the unit tests:
```
go test ./...
```

## Postman Collection

A Postman collection is available in the `postman` directory. Import the `stanford_students_api.json` file into Postman to test the API endpoints.

## Project Structure

```
stanford-uni-students-api/
├── config/             # Configuration package
├── db/                 # Database connection and migrations
├── frontend/           # Web frontend interface
│   ├── index.html      # Main HTML file
│   ├── style.css       # CSS styles
│   └── script.js       # JavaScript functionality
├── handlers/           # HTTP request handlers
├── middleware/         # Middleware functions
├── models/             # Data models and repositories
├── router/             # API routes setup
├── postman/            # Postman collection
├── .env                # Environment variables (not in version control)
├── .env.example        # Example environment variables
├── docker-compose.yml  # Docker Compose configuration
├── Dockerfile          # Docker build instructions
├── go.mod              # Go module file
├── go.sum              # Go module checksum
├── main.go             # Application entry point
└── README.md           # Project documentation
```

## Environment Variables

- `DB_HOST` - Database host (default: localhost)
- `DB_PORT` - Database port (default: 5432)
- `DB_USER` - Database user (default: postgres)
- `DB_PASSWORD` - Database password (default: postgres)
- `DB_NAME` - Database name (default: stanford_students)
- `PORT` - API port (default: 8080)
- `LOG_LEVEL` - Logging level (default: info)


### This README will be constantly updated as the application is developed and modified. 


## For Normal Docker Deployment

Notethat Recommended Approach: Make + Docker Compose

#### Prerequisites Check:
```bash
# Verify required tools are installed
docker --version          # Should show Docker 20.10+
docker-compose --version   # Should show Docker Compose 2.0+
make --version            # Should show GNU Make
```

#### Deployment Steps:
```bash
# Clone and navigate to project
git clone <repository-url>
cd stanford-students-project

# Start the application (one command does everything)
make run-api

# Monitor status
make status

# View logs
make logs

# Stop when done
make stop-all
```

### Alternative Deployment Methods:

#### Using Shell Scripts:
```bash
# Make scripts executable
chmod +x *.sh

# Start containers
./start-containers.sh

# Check status
./status.sh

# View logs
./logs.sh

# Stop containers
./stop-containers.sh
```

#### Using Docker Compose Only:
```bash
docker-compose up --build    # Start all services
docker-compose down          # Stop all services
docker-compose ps            # Check status
docker-compose logs -f app   # View logs
```

#### Manual Docker Commands:
```bash
# Create network
docker network create stanford-network

# Start PostgreSQL
docker run -d --name stanford-postgres --network stanford-network \
  -e POSTGRES_DB=stanford_students -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres -p 5432:5432 \
  -v stanford_postgres_data:/var/lib/postgresql/data postgres:15-alpine

# Build and start application
docker build -t stanford-students-api .
docker run -d --name stanford-app --network stanford-network \
  -e DB_HOST=stanford-postgres -e DB_PORT=5432 \
  -e DB_USER=postgres -e DB_PASSWORD=postgres \
  -e DB_NAME=stanford_students -e PORT=8080 \
  -p 8080:8080 stanford-students-api
```

### Troubleshooting:

#### Common Issues:
```bash
# If containers fail to start
make clean          # Clean up everything
make run-api        # Try again

# If database connection fails
make start-db       # Ensure database is running
make migrate        # Ensure migrations are applied

# If port 8080 is busy
sudo lsof -i :8080  # Check what's using the port
# Kill the process or change port in docker-compose.yml
```

## Quick Reference

### Most Common Commands:
```bash
# Start everything
make run-api

# Check if running
make status

# View logs
make logs

# Stop everything
make stop-all
```

### Built with love by Johntoby .....

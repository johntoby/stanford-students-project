# Stanford University Students API

A RESTful API for managing Stanford University Computer Science students built with Golang and Gin framework.

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

- Go 1.21 or higher
- PostgreSQL database
- Git

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

### Option 1: Using Docker Compose (Recommended)

1. Run with Docker Compose:
   ```
   docker-compose up --build
   ```

2. The application will be available at:
   - Frontend: `http://localhost:8080`
   - API: `http://localhost:8080/api/v1`
   - Health Check: `http://localhost:8080/healthcheck`

### Option 2: Manual Setup

1. Start the PostgreSQL database

2. Run the API:
   ```
   go run main.go
   ```

3. The application will be available at `http://localhost:8080`

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


## Docker Deployment

The application is containerized and can be deployed using Docker:

### Option 1: Using Docker Compose
```bash
# Run with Docker Compose (includes PostgreSQL)
docker-compose up --build

# Stop the services
docker-compose down
```

### Option 2: Using Docker Commands (Automated Scripts)
```bash
# Make scripts executable (Linux/Mac)
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

### Manual Docker Commands
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

### Built with love by Johntoby .....
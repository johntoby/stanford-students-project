#!/bin/bash

# Stanford Students API - Container Startup Script
echo "🚀 Starting Stanford Students API with Docker containers..."

# Configuration
NETWORK_NAME="stanford-network"
POSTGRES_CONTAINER="stanford-postgres"
APP_CONTAINER="stanford-app"
POSTGRES_PASSWORD="postgres"
DB_NAME="stanford_students"

# Create Docker network if it doesn't exist
echo "📡 Creating Docker network..."
docker network create $NETWORK_NAME 2>/dev/null || echo "Network already exists"

# Stop and remove existing containers
echo "🛑 Stopping existing containers..."
docker stop $POSTGRES_CONTAINER $APP_CONTAINER 2>/dev/null || true
docker rm $POSTGRES_CONTAINER $APP_CONTAINER 2>/dev/null || true

# Start PostgreSQL container
echo "🐘 Starting PostgreSQL container..."
docker run -d \
  --name $POSTGRES_CONTAINER \
  --network $NETWORK_NAME \
  -e POSTGRES_DB=$DB_NAME \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
  -p 5432:5432 \
  -v stanford_postgres_data:/var/lib/postgresql/data \
  postgres:15-alpine

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
sleep 10

# Check if PostgreSQL is ready
until docker exec $POSTGRES_CONTAINER pg_isready -U postgres; do
  echo "Waiting for PostgreSQL..."
  sleep 2
done

echo "✅ PostgreSQL is ready!"

# Build the application image
echo "🔨 Building application image..."
docker build -t johntoby/stanford-students-api .

# Start application container
echo "🚀 Starting application container..."
docker run -d \
  --name $APP_CONTAINER \
  --network $NETWORK_NAME \
  -e DB_HOST=$POSTGRES_CONTAINER \
  -e DB_PORT=5432 \
  -e DB_USER=postgres \
  -e DB_PASSWORD=$POSTGRES_PASSWORD \
  -e DB_NAME=$DB_NAME \
  -e PORT=8080 \
  -e LOG_LEVEL=info \
  -p 8080:8080 \
   johntoby/stanford-students-api

# Wait for application to start
echo "⏳ Waiting for application to start..."
sleep 5

# Check application health
echo "🏥 Checking application health..."
if curl -f http://localhost:8080/healthcheck >/dev/null 2>&1; then
  echo "✅ Application is healthy!"
else
  echo "⚠️  Application might still be starting..."
fi

echo ""
echo "🎉 Stanford Students API is running!"
echo "📱 Frontend: http://localhost:8080"
echo "🔗 API: http://localhost:8080/api/v1"
echo "💚 Health Check: http://localhost:8080/healthcheck"
echo ""
echo "📊 Container Status:"
docker ps --filter "name=stanford-"
echo ""
echo "📝 To view logs:"
echo "   Application: docker logs -f $APP_CONTAINER"
echo "   Database: docker logs -f $POSTGRES_CONTAINER"
echo ""
echo "🛑 To stop: ./stop-containers.sh"
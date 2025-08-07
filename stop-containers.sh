#!/bin/bash

# Stanford Students API - Container Stop Script
echo "🛑 Stopping Stanford Students API containers..."

# Configuration
NETWORK_NAME="stanford-network"
POSTGRES_CONTAINER="stanford-postgres"
APP_CONTAINER="stanford-app"

# Stop containers
echo "⏹️  Stopping application container..."
docker stop $APP_CONTAINER 2>/dev/null || echo "Application container not running"

echo "⏹️  Stopping PostgreSQL container..."
docker stop $POSTGRES_CONTAINER 2>/dev/null || echo "PostgreSQL container not running"

# Remove containers
echo "🗑️  Removing containers..."
docker rm $APP_CONTAINER 2>/dev/null || echo "Application container already removed"
docker rm $POSTGRES_CONTAINER 2>/dev/null || echo "PostgreSQL container already removed"

# Remove network
echo "🌐 Removing network..."
docker network rm $NETWORK_NAME 2>/dev/null || echo "Network already removed"

echo "✅ All containers stopped and removed!"
echo ""
echo "📊 Remaining containers:"
docker ps -a --filter "name=stanford-"
echo ""
echo "💾 Data volume preserved: stanford_postgres_data"
echo "🗑️  To remove data: docker volume rm stanford_postgres_data"
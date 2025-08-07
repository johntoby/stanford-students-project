#!/bin/bash

# Stanford Students API - Status Check Script
echo "📊 Stanford Students API - Container Status"
echo "==========================================="

# Check if containers are running
APP_STATUS=$(docker ps --filter "name=stanford-app" --format "{{.Status}}" 2>/dev/null)
DB_STATUS=$(docker ps --filter "name=stanford-postgres" --format "{{.Status}}" 2>/dev/null)

echo "🚀 Application Container:"
if [ -n "$APP_STATUS" ]; then
    echo "   ✅ Running - $APP_STATUS"
else
    echo "   ❌ Not running"
fi

echo ""
echo "🐘 PostgreSQL Container:"
if [ -n "$DB_STATUS" ]; then
    echo "   ✅ Running - $DB_STATUS"
else
    echo "   ❌ Not running"
fi

echo ""
echo "🌐 Network Status:"
if docker network ls | grep -q "stanford-network"; then
    echo "   ✅ stanford-network exists"
else
    echo "   ❌ stanford-network not found"
fi

echo ""
echo "💾 Data Volume:"
if docker volume ls | grep -q "stanford_postgres_data"; then
    echo "   ✅ stanford_postgres_data exists"
else
    echo "   ❌ stanford_postgres_data not found"
fi

echo ""
echo "🏥 Health Check:"
if curl -f http://localhost:8080/healthcheck >/dev/null 2>&1; then
    echo "   ✅ Application is healthy"
    curl -s http://localhost:8080/healthcheck | jq . 2>/dev/null || curl -s http://localhost:8080/healthcheck
else
    echo "   ❌ Application not responding"
fi

echo ""
echo "📋 All Stanford Containers:"
docker ps -a --filter "name=stanford-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
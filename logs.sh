#!/bin/bash

# Stanford Students API - View Logs Script
echo "📝 Stanford Students API - Container Logs"
echo "========================================="

case "$1" in
  "app"|"application")
    echo "📱 Application Logs:"
    docker logs -f stanford-app
    ;;
  "db"|"database"|"postgres")
    echo "🐘 PostgreSQL Logs:"
    docker logs -f stanford-postgres
    ;;
  "all"|"")
    echo "📊 All Container Status:"
    docker ps --filter "name=stanford-"
    echo ""
    echo "📱 Application Logs (last 20 lines):"
    docker logs --tail 20 stanford-app
    echo ""
    echo "🐘 PostgreSQL Logs (last 10 lines):"
    docker logs --tail 10 stanford-postgres
    echo ""
    echo "Usage: ./logs.sh [app|db|all]"
    echo "  app  - Follow application logs"
    echo "  db   - Follow database logs"
    echo "  all  - Show recent logs from both (default)"
    ;;
  *)
    echo "Usage: ./logs.sh [app|db|all]"
    echo "  app  - Follow application logs"
    echo "  db   - Follow database logs"
    echo "  all  - Show recent logs from both"
    ;;
esac
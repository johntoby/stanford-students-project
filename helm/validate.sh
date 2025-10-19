#!/bin/bash

echo "🔍 Validating Helm Charts..."

# Function to validate a chart
validate_chart() {
    local chart_name=$1
    echo "Validating $chart_name..."
    
    if helm lint ./$chart_name; then
        echo "✅ $chart_name: Lint passed"
    else
        echo "❌ $chart_name: Lint failed"
        return 1
    fi
    
    if helm template test ./$chart_name > /dev/null; then
        echo "✅ $chart_name: Template rendering passed"
    else
        echo "❌ $chart_name: Template rendering failed"
        return 1
    fi
}

# Validate individual charts
validate_chart "external-secrets"
validate_chart "vault"
validate_chart "postgresql"
validate_chart "stanford-api"

# Validate umbrella chart
echo "Validating umbrella chart..."
cd stanford-students-stack
helm dependency update
cd ..

validate_chart "stanford-students-stack"

echo "🎉 All validations completed!"
#!/bin/bash

# TreeShop Backend Deployment Script

set -e

echo "🚀 Deploying TreeShop Backend API Server..."

# Check if required environment variables are set
if [ -z "$REGRID_API_TOKEN" ]; then
    echo "❌ Error: REGRID_API_TOKEN environment variable is required"
    exit 1
fi

# Install dependencies
echo "📦 Installing dependencies..."
npm ci --only=production

# Create logs directory
mkdir -p logs

# Stop existing PM2 process if running
echo "🛑 Stopping existing processes..."
pm2 stop treeshop-api 2>/dev/null || true
pm2 delete treeshop-api 2>/dev/null || true

# Start the application
echo "▶️ Starting TreeShop API server..."
pm2 start ecosystem.config.js

# Save PM2 configuration
pm2 save

# Show status
echo "✅ Deployment complete!"
echo ""
echo "📊 Server Status:"
pm2 status

echo ""
echo "🔗 API Endpoints:"
echo "  Health Check: https://api.treeshop.com/health"
echo "  Parcel Search: https://api.treeshop.com/v1/parcels/search"
echo "  Owner Lookup: https://api.treeshop.com/v1/parcels/search"
echo ""
echo "📋 Next Steps:"
echo "  1. Test health check endpoint"
echo "  2. Update iOS app with production URL"
echo "  3. Test parcel lookup from TreeShop Maps app"
echo "  4. Monitor logs with: pm2 logs treeshop-api"
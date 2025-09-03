# TreeShop Backend API Server

Secure backend proxy for TreeShop Maps app that provides parcel data access while keeping Regrid API tokens secure.

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- npm or yarn
- Regrid API token
- Redis (optional, for advanced rate limiting)

### Installation

```bash
cd backend
npm install
```

### Configuration

1. Copy environment template:
```bash
cp .env.example .env
```

2. Edit `.env` and add your Regrid API token:
```bash
REGRID_API_TOKEN=your_actual_regrid_token_here
PORT=3000
NODE_ENV=development
```

### Run Development Server

```bash
npm run dev
```

Server will start at: http://localhost:3000

### Test Health Check

```bash
curl http://localhost:3000/health
```

Should return:
```json
{
  "status": "healthy",
  "service": "TreeShop Parcel API",
  "version": "1.0.0",
  "timestamp": "2024-01-09T19:30:00.000Z"
}
```

## 📡 API Endpoints

### Base URL: `http://localhost:3000` (development)

All requests require `app_token` parameter:
```
?app_token=treeshop_app_<device_uuid>
```

### 1. Search Parcels by Location
```bash
GET /v1/parcels/search?app_token=<token>&lat=40.7128&lon=-74.0060&radius=100&limit=10
```

### 2. Search Parcel by APN
```bash
GET /v1/parcels/apn?app_token=<token>&apn=123-456-789
```

### 3. Search Parcel by Address
```bash
GET /v1/parcels/address?app_token=<token>&address=123%20Main%20St,%20City,%20State
```

### 4. Search Parcels in Area
```bash
POST /v1/parcels/area
Content-Type: application/json

{
  "app_token": "treeshop_app_<device_uuid>",
  "geojson": {
    "type": "Polygon",
    "coordinates": [[[lng1, lat1], [lng2, lat2], ...]]
  },
  "limit": 50
}
```

## 🔐 Security Features

### Rate Limiting
- **100 requests/hour** per app token
- **1000 requests/day** per app token
- **Automatic blocking** of abusive clients

### Authentication
- **App token validation** for all requests
- **Device UUID-based** tokens
- **No hardcoded credentials** in client app

### Token Security
- **Regrid token** stored securely on server
- **Environment variable** configuration
- **Never exposed** to client applications

## 🚀 Deployment

### Production Environment

1. **Set production environment variables:**
```bash
export REGRID_API_TOKEN=your_production_regrid_token
export NODE_ENV=production
export PORT=443
```

2. **Deploy with PM2:**
```bash
npm run deploy
```

3. **Monitor logs:**
```bash
pm2 logs treeshop-api
```

### Docker Deployment (Alternative)

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

## 📊 Monitoring & Logging

### Request Logging
All requests logged with:
- Timestamp
- App token (device ID)
- Endpoint accessed
- Parameters (sanitized)
- Response status

### Usage Statistics
- Requests per app token
- Geographic usage patterns
- Popular search types
- Error rates and types

## 🧪 Testing

### Run Tests
```bash
npm test
```

### Manual Testing
```bash
# Test coordinate search
curl "http://localhost:3000/v1/parcels/search?app_token=treeshop_app_test&lat=40.7128&lon=-74.0060"

# Test APN search  
curl "http://localhost:3000/v1/parcels/apn?app_token=treeshop_app_test&apn=123-456-789"

# Test address search
curl "http://localhost:3000/v1/parcels/address?app_token=treeshop_app_test&address=123%20Main%20St"
```

## 🛡️ Production Security Checklist

- [ ] Regrid API token in secure environment variables
- [ ] HTTPS/SSL certificate configured
- [ ] Rate limiting enabled and tested
- [ ] Request logging configured
- [ ] CORS properly configured
- [ ] Error handling doesn't expose internal details
- [ ] Health check endpoint working
- [ ] Monitoring and alerting set up

## 🔧 Configuration

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `REGRID_API_TOKEN` | Your Regrid API token | ✅ Yes |
| `PORT` | Server port | No (default: 3000) |
| `NODE_ENV` | Environment | No (default: development) |
| `REDIS_URL` | Redis connection string | No |
| `LOG_LEVEL` | Logging level | No (default: info) |

### TreeShop Maps App Configuration

Update the iOS app to use production backend:

```swift
// In RegridParcelManager.swift
private let baseURL = "https://api.treeshop.com/v1/parcels"
```

## 📈 Usage Examples

### Successful Response
```json
{
  "type": "FeatureCollection", 
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "Polygon",
        "coordinates": [[[lng, lat], ...]]
      },
      "properties": {
        "ll_uuid": "12345",
        "headline": "123 Main St",
        "owner_name": "John Smith",
        "acreage": 0.25,
        "apn": "123-456-789"
      }
    }
  ]
}
```

### Error Response
```json
{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Too many requests. Please try again later.",
    "retry_after": 3600
  }
}
```

---

**The backend is now ready for deployment and will keep your Regrid tokens completely secure while providing full parcel data access to TreeShop Maps users!** 🔐
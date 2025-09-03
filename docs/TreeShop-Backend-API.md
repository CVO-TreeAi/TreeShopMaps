# TreeShop Backend API - Regrid Proxy Service

## Overview
TreeShop backend server that securely proxies Regrid API requests to keep API tokens secure and provide system-wide parcel data access for TreeShop Maps app users.

## Security Architecture

```
TreeShop Maps App → TreeShop Backend → Regrid API
     (no tokens)    (secure tokens)    (full access)
```

**Benefits:**
- ✅ **Zero token exposure** in client app
- ✅ **Rate limiting** and usage monitoring  
- ✅ **User authentication** and access control
- ✅ **Cost control** and billing management
- ✅ **App Store compliance** with secure API handling

## Required Backend Endpoints

### Base URL: `https://api.treeshop.com/v1/parcels`

### Authentication
All requests require:
```json
{
  "app_token": "treeshop_app_<device_uuid>",
  "app_version": "1.0",
  "platform": "ios"
}
```

---

## 1. Parcel Search by Location
**GET** `/search`

**Parameters:**
```json
{
  "lat": 40.7128,
  "lon": -74.0060,
  "radius": 100,
  "limit": 10
}
```

**TreeShop Backend Logic:**
```javascript
// Backend forwards to Regrid with secure token
const regridRequest = {
  url: `https://app.regrid.com/api/v2/parcels`,
  headers: { Authorization: `Bearer ${REGRID_SECRET_TOKEN}` },
  params: { lat, lon, radius, limit }
}
```

---

## 2. Parcel Search by APN
**GET** `/apn`

**Parameters:**
```json
{
  "apn": "123-456-789",
  "limit": 1
}
```

---

## 3. Parcel Search by Address  
**GET** `/address`

**Parameters:**
```json
{
  "address": "123 Main St, City, State",
  "limit": 5
}
```

---

## 4. Parcel Search by Area
**POST** `/area`

**Body:**
```json
{
  "geojson": {
    "type": "Polygon",
    "coordinates": [[[lng1, lat1], [lng2, lat2], ...]]
  },
  "limit": 50
}
```

---

## Response Format
All endpoints return consistent GeoJSON FeatureCollection:

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
        "ll_uuid": "unique-parcel-id",
        "headline": "123 Main St",
        "owner_name": "John Smith",
        "owner_address": "123 Main St, City, State",
        "apn": "123-456-789",
        "address": "123 Main St",
        "city": "City",
        "state": "State", 
        "zip_code": "12345",
        "acreage": 0.25,
        "land_use": "Residential"
      }
    }
  ]
}
```

## Error Handling
```json
{
  "error": {
    "code": "INVALID_LOCATION",
    "message": "No parcels found at specified location",
    "details": "Latitude/longitude may be in water or invalid"
  }
}
```

## Rate Limiting
- **100 requests/hour** per app instance
- **1000 requests/day** per app instance  
- **429 Too Many Requests** when exceeded

## Usage Monitoring
Backend logs:
- Request counts per device
- Geographic usage patterns
- Popular search types
- Error rates

## Development vs Production

### Development (Current)
```swift
private let baseURL = "https://api-dev.treeshop.com/v1/parcels"
```

### Production (App Store)
```swift
private let baseURL = "https://api.treeshop.com/v1/parcels"  
```

## TreeShop Backend Implementation Notes

**Required Backend Features:**
1. **Secure Regrid token storage** (environment variables)
2. **Request authentication** (validate app tokens)
3. **Rate limiting** (prevent abuse)
4. **Request logging** (monitor usage)
5. **Error handling** (convert Regrid errors to TreeShop format)
6. **Caching** (reduce Regrid API costs)

**Example Node.js/Express Route:**
```javascript
app.get('/v1/parcels/search', authenticate, rateLimit, async (req, res) => {
  const { lat, lon, radius, limit } = req.query;
  
  try {
    const regridResponse = await fetch(`https://app.regrid.com/api/v2/parcels?token=${REGRID_TOKEN}&lat=${lat}&lon=${lon}&radius=${radius}&limit=${limit}`);
    const data = await regridResponse.json();
    
    // Log usage
    logParcelRequest(req.app_token, 'coordinate_search', { lat, lon });
    
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: 'Parcel lookup failed' });
  }
});
```

This architecture ensures:
- **Complete security** - no exposed tokens
- **Cost control** - monitored usage
- **App Store compliance** - proper API practices
- **Scalability** - centralized token management
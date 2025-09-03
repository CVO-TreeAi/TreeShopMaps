const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const fetch = (...args) => import('node-fetch').then(({default: fetch}) => fetch(...args));
const { v4: uuidv4 } = require('uuid');
const compression = require('compression');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());
app.use(compression());
app.use(cors({
  origin: ['https://treeshop.com', 'https://www.treeshop.com'],
  credentials: true
}));
app.use(express.json({ limit: '10mb' }));

// Rate limiting for parcel API - SUPER STRICT to prevent API abuse
const parcelRateLimit = rateLimit({
  windowMs: 5 * 60 * 1000, // 5 minutes
  max: 3, // ONLY 3 requests per 5 minutes - much stricter!  
  message: {
    error: {
      code: 'RATE_LIMIT_EXCEEDED',
      message: 'Too many parcel requests. Limit: 3 per 5 minutes.',
      retry_after: '5 minutes'
    }
  },
  standardHeaders: true,
  legacyHeaders: false
});

// Authentication middleware
const authenticateApp = (req, res, next) => {
  const appToken = req.query.app_token || req.body.app_token;
  
  if (!appToken || !appToken.startsWith('treeshop_app_')) {
    return res.status(401).json({
      error: {
        code: 'UNAUTHORIZED',
        message: 'Valid TreeShop app token required'
      }
    });
  }
  
  req.appToken = appToken;
  next();
};

// Logging middleware
const logRequest = (req, res, next) => {
  const timestamp = new Date().toISOString();
  const { appToken } = req;
  const endpoint = req.path;
  const params = { ...req.query, ...req.body };
  delete params.app_token; // Don't log tokens
  
  console.log(`[${timestamp}] ${appToken} - ${endpoint} - ${JSON.stringify(params)}`);
  next();
};

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    service: 'TreeShop Parcel API',
    version: '1.0.0',
    timestamp: new Date().toISOString()
  });
});

// Parcel search by coordinates
app.get('/v1/parcels/search', parcelRateLimit, authenticateApp, logRequest, async (req, res) => {
  try {
    const { lat, lon, radius = 100, limit = 10 } = req.query;
    
    if (!lat || !lon) {
      return res.status(400).json({
        error: {
          code: 'MISSING_COORDINATES',
          message: 'Latitude and longitude are required'
        }
      });
    }
    
    const regridUrl = `https://app.regrid.com/api/v2/parcels/point?token=${process.env.REGRID_API_TOKEN}&lat=${lat}&lon=${lon}&radius=${radius}&limit=${limit}`;
    
    const response = await fetch(regridUrl);
    
    if (!response.ok) {
      throw new Error(`Regrid API error: ${response.status}`);
    }
    
    const data = await response.json();
    res.json(data);
    
  } catch (error) {
    console.error('Parcel search error:', error);
    res.status(500).json({
      error: {
        code: 'PARCEL_SEARCH_FAILED',
        message: 'Failed to search parcels',
        details: error.message
      }
    });
  }
});

// Parcel search by APN
app.get('/v1/parcels/apn', parcelRateLimit, authenticateApp, logRequest, async (req, res) => {
  try {
    const { apn, limit = 1 } = req.query;
    
    if (!apn) {
      return res.status(400).json({
        error: {
          code: 'MISSING_APN',
          message: 'Assessor Parcel Number (APN) is required'
        }
      });
    }
    
    const regridUrl = `https://app.regrid.com/api/v2/parcels/apn?token=${process.env.REGRID_API_TOKEN}&parcelnumb=${encodeURIComponent(apn)}&limit=${limit}`;
    
    const response = await fetch(regridUrl);
    
    if (!response.ok) {
      throw new Error(`Regrid API error: ${response.status}`);
    }
    
    const data = await response.json();
    res.json(data);
    
  } catch (error) {
    console.error('APN search error:', error);
    res.status(500).json({
      error: {
        code: 'APN_SEARCH_FAILED',
        message: 'Failed to search parcel by APN',
        details: error.message
      }
    });
  }
});

// Parcel search by address
app.get('/v1/parcels/address', parcelRateLimit, authenticateApp, logRequest, async (req, res) => {
  try {
    const { address, limit = 5 } = req.query;
    
    if (!address) {
      return res.status(400).json({
        error: {
          code: 'MISSING_ADDRESS',
          message: 'Street address is required'
        }
      });
    }
    
    const regridUrl = `https://app.regrid.com/api/v2/parcels/address?token=${process.env.REGRID_API_TOKEN}&query=${encodeURIComponent(address)}&limit=${limit}`;
    
    const response = await fetch(regridUrl);
    
    if (!response.ok) {
      throw new Error(`Regrid API error: ${response.status}`);
    }
    
    const data = await response.json();
    res.json(data);
    
  } catch (error) {
    console.error('Address search error:', error);
    res.status(500).json({
      error: {
        code: 'ADDRESS_SEARCH_FAILED',
        message: 'Failed to search parcel by address',
        details: error.message
      }
    });
  }
});

// Parcel search within polygon area
app.post('/v1/parcels/area', parcelRateLimit, authenticateApp, logRequest, async (req, res) => {
  try {
    const { geojson, limit = 50 } = req.body;
    
    if (!geojson) {
      return res.status(400).json({
        error: {
          code: 'MISSING_GEOJSON',
          message: 'GeoJSON polygon is required'
        }
      });
    }
    
    const regridPayload = {
      token: process.env.REGRID_API_TOKEN,
      geojson: geojson,
      limit: limit
    };
    
    const response = await fetch('https://app.regrid.com/api/v2/parcels', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(regridPayload)
    });
    
    if (!response.ok) {
      throw new Error(`Regrid API error: ${response.status}`);
    }
    
    const data = await response.json();
    res.json(data);
    
  } catch (error) {
    console.error('Area search error:', error);
    res.status(500).json({
      error: {
        code: 'AREA_SEARCH_FAILED',
        message: 'Failed to search parcels in area',
        details: error.message
      }
    });
  }
});

// Get specific parcel by UUID
app.get('/v1/parcels/:uuid', parcelRateLimit, authenticateApp, logRequest, async (req, res) => {
  try {
    const { uuid } = req.params;
    
    const regridUrl = `https://app.regrid.com/api/v2/parcels/${uuid}?token=${process.env.REGRID_API_TOKEN}`;
    
    const response = await fetch(regridUrl);
    
    if (!response.ok) {
      if (response.status === 404) {
        return res.status(404).json({
          error: {
            code: 'PARCEL_NOT_FOUND',
            message: 'Parcel not found'
          }
        });
      }
      throw new Error(`Regrid API error: ${response.status}`);
    }
    
    const data = await response.json();
    res.json(data);
    
  } catch (error) {
    console.error('UUID search error:', error);
    res.status(500).json({
      error: {
        code: 'UUID_SEARCH_FAILED',
        message: 'Failed to get parcel by UUID',
        details: error.message
      }
    });
  }
});

// Usage statistics endpoint (for monitoring)
app.get('/v1/stats', authenticateApp, (req, res) => {
  // Basic stats - in production would use Redis/database
  res.json({
    app_token: req.appToken,
    requests_today: 0, // Would track actual usage
    rate_limit_remaining: 100, // Would calculate from Redis
    status: 'active'
  });
});

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('Unhandled error:', error);
  res.status(500).json({
    error: {
      code: 'INTERNAL_SERVER_ERROR',
      message: 'An unexpected error occurred'
    }
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: {
      code: 'ENDPOINT_NOT_FOUND',
      message: 'API endpoint not found'
    }
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 TreeShop Parcel API Server running on port ${PORT}`);
  console.log(`🔐 Regrid token configured: ${process.env.REGRID_API_TOKEN ? 'YES' : 'NO'}`);
  console.log(`📍 Health check: http://localhost:${PORT}/health`);
});

module.exports = app;
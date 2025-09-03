const rateLimit = require('express-rate-limit');

// Enhanced rate limiting with Redis (if available)
const createRateLimiter = (options = {}) => {
  const defaultOptions = {
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 60 * 60 * 1000, // 1 hour
    max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100, // 100 requests per hour
    standardHeaders: true,
    legacyHeaders: false,
    keyGenerator: (req) => {
      // Use app token for rate limiting instead of IP
      return req.query.app_token || req.body.app_token || req.ip;
    },
    message: {
      error: {
        code: 'RATE_LIMIT_EXCEEDED',
        message: 'Too many requests. Please try again later.',
        limit: options.max || 100,
        window: '1 hour'
      }
    }
  };
  
  return rateLimit({ ...defaultOptions, ...options });
};

// Specific rate limiters for different endpoints
const parcelSearchLimit = createRateLimiter({
  max: 100, // 100 parcel searches per hour
  message: {
    error: {
      code: 'PARCEL_SEARCH_LIMIT_EXCEEDED',
      message: 'Too many parcel searches. Limit: 100 per hour.',
      retry_after: 3600
    }
  }
});

const ownerLookupLimit = createRateLimiter({
  max: 50, // 50 owner lookups per hour
  message: {
    error: {
      code: 'OWNER_LOOKUP_LIMIT_EXCEEDED', 
      message: 'Too many owner lookups. Limit: 50 per hour.',
      retry_after: 3600
    }
  }
});

const generalAPILimit = createRateLimiter({
  max: 200, // 200 general API calls per hour
  message: {
    error: {
      code: 'API_LIMIT_EXCEEDED',
      message: 'Too many API requests. Limit: 200 per hour.',
      retry_after: 3600
    }
  }
});

module.exports = {
  parcelSearchLimit,
  ownerLookupLimit,
  generalAPILimit,
  createRateLimiter
};
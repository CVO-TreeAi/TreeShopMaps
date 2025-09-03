const fetch = require('node-fetch');

class RegridService {
  constructor() {
    this.baseURL = 'https://app.regrid.com/api/v2';
    this.token = process.env.REGRID_API_TOKEN;
    
    if (!this.token) {
      throw new Error('REGRID_API_TOKEN environment variable is required');
    }
  }
  
  async searchByCoordinates(lat, lon, radius = 100, limit = 10) {
    const url = `${this.baseURL}/parcels?token=${this.token}&lat=${lat}&lon=${lon}&radius=${radius}&limit=${limit}`;
    return this.makeRequest(url);
  }
  
  async searchByAPN(apn, limit = 1) {
    const url = `${this.baseURL}/parcels?token=${this.token}&parcel_id=${encodeURIComponent(apn)}&limit=${limit}`;
    return this.makeRequest(url);
  }
  
  async searchByAddress(address, limit = 5) {
    const url = `${this.baseURL}/parcels?token=${this.token}&address=${encodeURIComponent(address)}&limit=${limit}`;
    return this.makeRequest(url);
  }
  
  async searchByArea(geojson, limit = 50) {
    const url = `${this.baseURL}/parcels`;
    
    const payload = {
      token: this.token,
      geojson: geojson,
      limit: limit
    };
    
    return this.makeRequest(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(payload)
    });
  }
  
  async getParcelByUUID(uuid) {
    const url = `${this.baseURL}/parcels/${uuid}?token=${this.token}`;
    return this.makeRequest(url);
  }
  
  async makeRequest(url, options = {}) {
    try {
      const response = await fetch(url, options);
      
      if (!response.ok) {
        const errorData = await response.text();
        throw new Error(`Regrid API Error ${response.status}: ${errorData}`);
      }
      
      const data = await response.json();
      
      // Validate response structure
      if (!data || (data.type !== 'FeatureCollection' && !data.ll_uuid)) {
        throw new Error('Invalid response format from Regrid API');
      }
      
      return data;
      
    } catch (error) {
      console.error('Regrid API request failed:', error.message);
      throw error;
    }
  }
  
  // Helper method to validate coordinates
  validateCoordinates(lat, lon) {
    const latitude = parseFloat(lat);
    const longitude = parseFloat(lon);
    
    if (isNaN(latitude) || isNaN(longitude)) {
      throw new Error('Invalid coordinates: must be valid numbers');
    }
    
    if (latitude < -90 || latitude > 90) {
      throw new Error('Invalid latitude: must be between -90 and 90');
    }
    
    if (longitude < -180 || longitude > 180) {
      throw new Error('Invalid longitude: must be between -180 and 180');
    }
    
    return { latitude, longitude };
  }
  
  // Helper method to validate GeoJSON
  validateGeoJSON(geojson) {
    if (!geojson || typeof geojson !== 'object') {
      throw new Error('Invalid GeoJSON: must be an object');
    }
    
    if (geojson.type !== 'Polygon' && geojson.type !== 'MultiPolygon') {
      throw new Error('Invalid GeoJSON: must be Polygon or MultiPolygon');
    }
    
    if (!geojson.coordinates || !Array.isArray(geojson.coordinates)) {
      throw new Error('Invalid GeoJSON: coordinates array required');
    }
    
    return true;
  }
}

module.exports = new RegridService();
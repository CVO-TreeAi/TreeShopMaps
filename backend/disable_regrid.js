// Quick script to disable all expensive Regrid API endpoints
const fs = require('fs');

const serverFile = './server.js';
const content = fs.readFileSync(serverFile, 'utf8');

// Replace all the expensive endpoints with stub responses
const newContent = content
  .replace(/\/\/ Parcel search by APN[\s\S]*?}\);/g, 
    '// Parcel search by APN - DISABLED\napp.get(\'/v1/parcels/apn\', authenticateApp, logRequest, async (req, res) => {\n  res.json({ message: \'APN lookup disabled to save costs\', features: [], status: \'feature_disabled\' });\n});')
  
  .replace(/\/\/ Parcel search by address[\s\S]*?}\);/g,
    '// Parcel search by address - DISABLED\napp.get(\'/v1/parcels/address\', authenticateApp, logRequest, async (req, res) => {\n  res.json({ message: \'Address lookup disabled to save costs\', features: [], status: \'feature_disabled\' });\n});')
  
  .replace(/\/\/ Parcel search within polygon area[\s\S]*?}\);/g,
    '// Parcel search within polygon area - DISABLED\napp.post(\'/v1/parcels/area\', authenticateApp, logRequest, async (req, res) => {\n  res.json({ message: \'Area search disabled to save costs\', features: [], status: \'feature_disabled\' });\n});')
  
  .replace(/\/\/ Get specific parcel by UUID[\s\S]*?}\);/g,
    '// Get specific parcel by UUID - DISABLED\napp.get(\'/v1/parcels/:uuid\', authenticateApp, logRequest, async (req, res) => {\n  res.json({ message: \'Parcel UUID lookup disabled to save costs\', status: \'feature_disabled\' });\n});')
  
  .replace(/parcelRateLimit, /g, '') // Remove rate limiting since we're not hitting external APIs
  .replace('service: \'TreeShop Parcel API\'', 'service: \'TreeShop Maps API (Parcel features disabled)\'');

fs.writeFileSync(serverFile, newContent);
console.log('✅ All expensive Regrid endpoints disabled!');
console.log('💰 This will save money on API calls while keeping the app functional.');
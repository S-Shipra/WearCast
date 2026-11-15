require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const Cloth = require('./models/Cloth');
const { generateOutfits } = require('./services/recommender');
const { getWeather } = require('./services/weatherService');
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/user');

const app = express();
app.use(cors());
app.use(express.json());

// 1. Health check route
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'Wearcast backend is running' });
});

// 2. Catalog browse route
app.get('/api/catalog', async (req, res) => {
  try {
    const { category, warmth, gender } = req.query;
    const filter = {};
    
    if (category) filter.category = category;
    if (warmth)   filter.warmthLevel = Number(warmth);
    if (gender)   filter.gender = { $in: [gender, 'unisex'] };

    const items = await Cloth.find(filter).limit(500);
    res.json({ count: items.length, items });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 3. Recommendation route (REAL WEATHER + OCCASION)
app.get('/api/recommend', async (req, res) => {
  try {
    const { lat, lon, gender, occasion } = req.query;

    const latitude = lat || 28.6139;
    const longitude = lon || 77.2090;

    // 1. Fetch real weather from Open-Meteo
    const weather = await getWeather(latitude, longitude);

    // 2. Fetch all clothes from DB (let the engine handle occasion filtering)
    const catalog = await Cloth.find({});

    // 3. Generate outfits using our engine (passing occasion!)
    const outfits = generateOutfits(catalog, weather, gender || 'unisex', occasion);

    res.json({
      weather: weather,
      outfits: outfits
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
// 5. City Search & Weather Route
app.get('/api/weather', async (req, res) => {
  try {
    const { lat, lon } = req.query;
    if (!lat || !lon) return res.status(400).json({ error: "Missing coordinates" });

    const weather = await getWeather(lat, lon);
    res.json(weather);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
// 4. Auth routes
app.use('/api/auth', authRoutes);
app.use('/api/user', userRoutes);

// Connect to DB, then start server
mongoose.connect(process.env.MONGO_URI)
  .then(() => {
    console.log('✅ MongoDB connected');
    app.listen(process.env.PORT || 5000, () => {
      console.log(`🚀 Server running on http://localhost:${process.env.PORT || 5000}`);
    });
  })
  .catch(err => console.error('❌ MongoDB connection failed:', err.message));
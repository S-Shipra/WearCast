require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const Cloth = require('./models/Cloth');
const Outfit = require('./models/Outfit'); // NEW
const User = require('./models/User');     // NEW
const RecommendationFeedback = require('./models/RecommendationFeedback');
const { generateOutfits } = require('./services/recommender');
const { getWeather } = require('./services/weatherService');
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/user');
const requireAuth = require('./middleware/requireAuth');

const app = express();
app.use(cors());
app.use(express.json());

// 1. Health check route
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'Wearcast backend is running' });
});

// 2. Catalog browse route
app.get('/api/catalog', requireAuth, async (req, res) => {
  try {
    const { category, warmth, gender } = req.query;
    const filter = {};

    if (category && !['top', 'bottom', 'outerwear', 'footwear', 'accessory'].includes(category)) {
      return res.status(400).json({ error: 'Invalid category' });
    }
    if (warmth && (!Number.isInteger(Number(warmth)) || Number(warmth) < 1 || Number(warmth) > 5)) {
      return res.status(400).json({ error: 'Warmth must be between 1 and 5' });
    }
    if (gender && !['men', 'women', 'unisex'].includes(gender)) {
      return res.status(400).json({ error: 'Invalid gender' });
    }
    
    if (category) filter.category = category;
    if (warmth)   filter.warmthLevel = Number(warmth);
    if (gender)   filter.gender = { $in: [gender, 'unisex'] };
    filter.$or = [{ ownerId: null }, { ownerId: req.userId }];

    const items = await Cloth.find(filter).limit(500);
    res.json({ count: items.length, items });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 3. Recommendation route (REAL WEATHER + OCCASION)
app.get('/api/recommend', requireAuth, async (req, res) => {
  try {
    const { lat, lon, occasion } = req.query;

    const latitude = Number(lat ?? 28.6139);
    const longitude = Number(lon ?? 77.2090);
    if (!Number.isFinite(latitude) || latitude < -90 || latitude > 90 ||
        !Number.isFinite(longitude) || longitude < -180 || longitude > 180) {
      return res.status(400).json({ error: 'Valid latitude and longitude are required' });
    }
    if (occasion && !['Casual', 'Formal', 'Sports'].includes(occasion)) {
      return res.status(400).json({ error: 'Invalid occasion' });
    }

    const user = await User.findById(req.userId).select('gender thermalPreference preferredStyle preferredColors');
    if (!user) return res.status(401).json({ error: 'Invalid or expired session' });

    // 1. Fetch real weather from Open-Meteo
    const weather = await getWeather(latitude, longitude);

    // 2. Fetch all clothes from DB (let the engine handle occasion filtering)
    const [catalog, feedback] = await Promise.all([
      Cloth.find({ $or: [{ ownerId: null }, { ownerId: req.userId }] }),
      RecommendationFeedback.find({ userId: req.userId }).sort({ updatedAt: -1 }).limit(100).lean(),
    ]);

    // 3. Generate outfits using our engine (passing occasion!)
    const outfits = generateOutfits(
      catalog,
      weather,
      user.gender || 'unisex',
      occasion,
      user.thermalPreference || 'balanced',
      { style: user.preferredStyle || 'any', colors: user.preferredColors || [], feedback },
    );

    res.json({
      weather: weather,
      outfits: outfits
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 4. City Search & Weather Route
app.get('/api/weather', async (req, res) => {
  try {
    const { lat, lon } = req.query;
    const latitude = Number(lat);
    const longitude = Number(lon);
    if (!Number.isFinite(latitude) || latitude < -90 || latitude > 90 ||
        !Number.isFinite(longitude) || longitude < -180 || longitude > 180) {
      return res.status(400).json({ error: 'Valid latitude and longitude are required' });
    }

    const weather = await getWeather(latitude, longitude);
    res.json(weather);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ---- NEW: OUTFITS ROUTES (SAVE & FETCH) ----
app.post('/api/outfits/save', requireAuth, async (req, res) => {
  try {
    const { items, weatherSnapshot } = req.body;

    if (!Array.isArray(items) || items.length === 0 || items.length > 10 ||
        items.some((id) => !mongoose.isValidObjectId(id))) {
      return res.status(400).json({ error: 'A valid list of 1 to 10 clothing items is required' });
    }
    const uniqueItems = [...new Set(items.map(String))];
    const existingItems = await Cloth.countDocuments({ _id: { $in: uniqueItems }, $or: [{ ownerId: null }, { ownerId: req.userId }] });
    if (existingItems !== uniqueItems.length) {
      return res.status(400).json({ error: 'One or more clothing items no longer exist' });
    }

    // 1. Create the outfit document
    const outfit = new Outfit({
      userId: req.userId,
      items: uniqueItems,
      weatherSnapshot: weatherSnapshot || {}
    });
    await outfit.save();

    // 2. Link it to the user's savedOutfits array
    await User.findByIdAndUpdate(req.userId, {
      $push: { savedOutfits: outfit._id }
    });

    res.status(201).json({
      message: 'Outfit saved to wardrobe',
      outfitId: outfit._id
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/outfits', requireAuth, async (req, res) => {
  try {
    const outfits = await Outfit
      .find({ userId: req.userId })
      .populate('items')
      .sort({ dateSaved: -1 });
    res.json({ count: outfits.length, outfits });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
// Delete a saved outfit
app.delete('/api/outfits/:outfitId', requireAuth, async (req, res) => {
  try {
    const { outfitId } = req.params;

    // 1. Find and delete the outfit
    if (!mongoose.isValidObjectId(outfitId)) return res.status(400).json({ error: 'Invalid outfit id' });
    const outfit = await Outfit.findOneAndDelete({ _id: outfitId, userId: req.userId });
    if (!outfit) return res.status(404).json({ error: 'Outfit not found' });

    // 2. Remove the reference from the User's savedOutfits array
    await User.findByIdAndUpdate(outfit.userId, {
      $pull: { savedOutfits: outfitId }
    });

    res.json({ message: 'Outfit deleted successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
// ---------------------------------------------

// 5. Auth routes
app.use('/api/auth', authRoutes);
app.use('/api/user', requireAuth, userRoutes);

// Connect to DB, then start server
mongoose.connect(process.env.MONGO_URI)
  .then(() => {
    console.log('✅ MongoDB connected');
    app.listen(process.env.PORT || 5000, () => {
      console.log(`🚀 Server running on http://localhost:${process.env.PORT || 5000}`);
    });
  })
  .catch(err => console.error('❌ MongoDB connection failed:', err.message));

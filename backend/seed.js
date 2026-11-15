require('dotenv').config();
const mongoose = require('mongoose');
const fs = require('fs');
const path = require('path');
const Cloth = require('./models/Cloth');

(async () => {
  try {
    console.log('Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ MongoDB connected');

    const filePath = path.join(__dirname, 'clothes.json');
    const raw = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    console.log(`📦 Loaded ${raw.length} items from clothes.json`);

    // Normalize articleType to lowercase for consistent filtering
    const data = raw.map(item => ({
      ...item,
      articleType: item.articleType.toLowerCase()
    }));

    console.log('🗑️  Clearing existing clothes collection...');
    await Cloth.deleteMany({});

    console.log('💾 Inserting new data...');
    const inserted = await Cloth.insertMany(data);
    console.log(`✅ Seeded ${inserted.length} clothes into MongoDB`);

    await mongoose.disconnect();
    console.log('🔌 Disconnected. Done!');
    process.exit(0);
  } catch (err) {
    console.error('❌ Seed failed:', err.message);
    process.exit(1);
  }
})();
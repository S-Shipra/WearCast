require('dotenv').config();
const fs = require('fs');
const path = require('path');
const mongoose = require('mongoose');
const Cloth = require('./models/Cloth');

function readCatalog() {
  const filePath = path.join(__dirname, 'clothes.json');
  const raw = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  const imageUrls = new Set();

  return raw.map((item, index) => {
    if (imageUrls.has(item.imageUrl)) {
      throw new Error(`Duplicate image URL on catalog item ${index + 1} (${item.name})`);
    }
    imageUrls.add(item.imageUrl);

    const normalized = {
      ...item,
      articleType: item.articleType.toLowerCase(),
    };
    const validationError = new Cloth(normalized).validateSync();

    if (validationError) {
      throw new Error(`Invalid catalog item ${index + 1} (${item.name}): ${validationError.message}`);
    }
    if (['top', 'outerwear'].includes(item.category) &&
        (item.sleeveLength === 'not_applicable' || item.fabricWeight === 'not_applicable')) {
      throw new Error(`Catalog item ${index + 1} (${item.name}) needs sleeve and fabric tags`);
    }
    if (item.category === 'footwear' && item.footwearCoverage === 'not_applicable') {
      throw new Error(`Catalog item ${index + 1} (${item.name}) needs a footwear coverage tag`);
    }

    return normalized;
  });
}

async function seedCatalog() {
  if (!process.env.MONGO_URI) throw new Error('MONGO_URI is required');

  try {
    const data = readCatalog();
    await mongoose.connect(process.env.MONGO_URI);

    // Upsert by stable image URL so existing outfit references keep their IDs.
    const operations = data.map((item) => ({
      updateOne: {
        filter: { imageUrl: item.imageUrl },
        update: { $set: item },
        upsert: true,
      },
    }));
    const result = await Cloth.bulkWrite(operations, { ordered: false });

    console.log(
      `Catalog ready: ${data.length} validated items, ` +
      `${result.upsertedCount} added and ${result.modifiedCount} updated.`,
    );
  } finally {
    if (mongoose.connection.readyState !== 0) await mongoose.disconnect();
  }
}

seedCatalog().catch((error) => {
  console.error('Catalog seed failed:', error.message);
  process.exitCode = 1;
});

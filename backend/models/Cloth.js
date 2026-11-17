const mongoose = require('mongoose');

const clothSchema = new mongoose.Schema({
  name:        { type: String, required: true },
  category:    { type: String, enum: ['top','bottom','outerwear','footwear','accessory'], required: true },
  articleType: { type: String, required: true },
  gender:      { type: String, enum: ['men','women','unisex'], required: true },
  color:       { type: String, required: true },
  warmthLevel: { type: Number, min: 1, max: 5, required: true },
  sleeveLength: {
    type: String,
    enum: ['sleeveless', 'short', 'long', 'unknown', 'not_applicable'],
    required: true
  },
  fabricWeight: {
    type: String,
    enum: ['light', 'midweight', 'heavy', 'unknown', 'not_applicable'],
    required: true
  },
  footwearCoverage: {
    type: String,
    enum: ['open', 'covered', 'not_applicable'],
    required: true
  },
  waterproof:  { type: Boolean, default: false },
  breathable:  { type: Boolean, default: false },
  season:      [{ type: String }],
  occasion:    { type: String, enum: ['Casual','Formal','Sports'], required: true },
  imageUrl:    { type: String, default: '' },
  ownerId:     { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null, index: true },
  source:      { type: String }
});

module.exports = mongoose.model('Cloth', clothSchema);

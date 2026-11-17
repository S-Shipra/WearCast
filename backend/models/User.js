const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true, trim: true, lowercase: true },
  passwordHash: { type: String, required: true },
  gender: { type: String, default: 'unisex' },
  thermalPreference: {
    type: String,
    enum: ['cold', 'balanced', 'hot'],
    default: 'balanced',
  },
  preferredStyle: { type: String, enum: ['any', 'casual', 'formal', 'sports'], default: 'any' },
  preferredColors: [{ type: String, enum: ['black','white','blue','navy','red','green','brown','beige','grey','pink','purple','yellow','orange'] }],
  savedOutfits: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Outfit' }],
  favorites: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Cloth' }] // ADD THIS LINE
});

module.exports = mongoose.model('User', userSchema);

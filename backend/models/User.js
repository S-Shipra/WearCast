const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  passwordHash: { type: String, required: true },
  gender: { type: String, default: 'unisex' },
  savedOutfits: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Outfit' }],
  favorites: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Cloth' }] // ADD THIS LINE
});

module.exports = mongoose.model('User', userSchema);
module.exports = mongoose.model('User', userSchema);
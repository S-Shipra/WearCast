const mongoose = require('mongoose');

const outfitSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  items: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Cloth' }],
  weatherSnapshot: { type: Object },
  dateSaved: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Outfit', outfitSchema);
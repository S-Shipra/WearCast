const mongoose = require('mongoose');

const recommendationFeedbackSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  outfitKey: { type: String, required: true },
  itemIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Cloth' }],
  rating: { type: String, enum: ['like', 'dislike'], required: true },
}, { timestamps: true });

recommendationFeedbackSchema.index({ userId: 1, outfitKey: 1 }, { unique: true });
module.exports = mongoose.model('RecommendationFeedback', recommendationFeedbackSchema);

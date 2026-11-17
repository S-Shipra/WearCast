const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const User = require('../models/User');
const Outfit = require('../models/Outfit');
const Cloth = require('../models/Cloth');
const RecommendationFeedback = require('../models/RecommendationFeedback');

// Toggle favorite (Add or Remove)
router.post('/favorites/toggle', async (req, res) => {
  try {
    const { itemId } = req.body;
    if (!itemId || !mongoose.isValidObjectId(itemId)) {
      return res.status(400).json({ error: 'A valid item id is required' });
    }
    const visibleItem = await Cloth.exists({
      _id: itemId,
      $or: [{ ownerId: null }, { ownerId: req.userId }],
    });
    if (!visibleItem) return res.status(404).json({ error: 'Clothing item not found' });
    const user = await User.findById(req.userId);

    if (!user) return res.status(404).json({ error: 'User not found' });

    // Check if item is already in favorites
    const index = user.favorites.findIndex((favorite) => favorite.equals(itemId));

    if (index > -1) {
      // Remove it
      user.favorites.splice(index, 1);
    } else {
      // Add it
      user.favorites.push(itemId);
    }

    await user.save();
    res.json({ message: 'Favorite updated', favorites: user.favorites });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get user favorites
router.get('/favorites', async (req, res) => {
  try {
    const user = await User.findById(req.userId).populate('favorites');
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json(user.favorites);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update user profile (Name & Gender)
router.put('/update', async (req, res) => {
  try {
    const { name, gender, preferredStyle, preferredColors } = req.body;
    if (typeof name !== 'string' || !name.trim() ||
        !['men', 'women', 'unisex'].includes(gender)) {
      return res.status(400).json({ error: 'A name and valid wardrobe preference are required' });
    }
    const styles = ['any', 'casual', 'formal', 'sports'];
    const colors = ['black','white','blue','navy','red','green','brown','beige','grey','pink','purple','yellow','orange'];
    if ((preferredStyle !== undefined && !styles.includes(preferredStyle)) ||
        (preferredColors !== undefined && (!Array.isArray(preferredColors) || preferredColors.some(c => !colors.includes(c))))) {
      return res.status(400).json({ error: 'Invalid style or color preferences' });
    }
    const update = { name: name.trim(), gender };
    if (preferredStyle !== undefined) update.preferredStyle = preferredStyle;
    if (preferredColors !== undefined) update.preferredColors = [...new Set(preferredColors)];
    const user = await User.findByIdAndUpdate(
      req.userId,
      update,
      { new: true, runValidators: true }
    );
    if (!user) return res.status(404).json({ error: 'User not found' });

    // Send back the updated user object (matching the auth response format)
    res.json({
      user: { id: user._id, name: user.name, email: user.email, gender: user.gender,
        preferredStyle: user.preferredStyle, preferredColors: user.preferredColors,
        thermalPreference: user.thermalPreference }
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/wardrobe', async (req, res) => {
  try {
    const items = await Cloth.find({ ownerId: req.userId }).sort({ _id: -1 });
    res.json({ count: items.length, items });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

router.post('/wardrobe', async (req, res) => {
  try {
    const { name, category, color, warmthLevel, sleeveLength, fabricWeight,
      footwearCoverage, waterproof = false, breathable = false, occasion = 'Casual', imageUrl = '' } = req.body;
    const categories = ['top','bottom','outerwear','footwear','accessory'];
    const sleeves = ['sleeveless','short','long','unknown','not_applicable'];
    const weights = ['light','midweight','heavy','unknown','not_applicable'];
    const coverage = ['open','covered','not_applicable'];
    if (typeof name !== 'string' || !name.trim() || name.trim().length > 80 ||
        !categories.includes(category) || typeof color !== 'string' || !color.trim() ||
        !Number.isInteger(warmthLevel) || warmthLevel < 1 || warmthLevel > 5 ||
        !sleeves.includes(sleeveLength) || !weights.includes(fabricWeight) ||
        !coverage.includes(footwearCoverage) || !['Casual','Formal','Sports'].includes(occasion) ||
        typeof imageUrl !== 'string' || imageUrl.length > 500 ||
        (imageUrl && !/^https?:\/\//i.test(imageUrl))) {
      return res.status(400).json({ error: 'Please provide valid clothing details' });
    }
    const item = await Cloth.create({ name: name.trim(), category, articleType: 'personal-item', gender: 'unisex',
      color: color.trim().toLowerCase(), warmthLevel, sleeveLength, fabricWeight, footwearCoverage,
      waterproof: Boolean(waterproof), breathable: Boolean(breathable), season: [], occasion,
      imageUrl, source: 'user-wardrobe', ownerId: req.userId });
    res.status(201).json({ item });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

router.delete('/wardrobe/:itemId', async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.itemId)) return res.status(400).json({ error: 'Invalid item id' });
    const item = await Cloth.findOneAndDelete({ _id: req.params.itemId, ownerId: req.userId });
    if (!item) return res.status(404).json({ error: 'Wardrobe item not found' });
    await User.updateOne({ _id: req.userId }, { $pull: { favorites: item._id } });
    res.json({ message: 'Wardrobe item removed' });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

router.post('/recommendation-feedback', async (req, res) => {
  try {
    const { itemIds, rating } = req.body;
    if (!Array.isArray(itemIds) || !itemIds.length || itemIds.length > 10 ||
        itemIds.some(id => !mongoose.isValidObjectId(id)) || !['like','dislike'].includes(rating)) {
      return res.status(400).json({ error: 'Valid outfit items and rating are required' });
    }
    const uniqueIds = [...new Set(itemIds.map(String))].sort();
    const count = await Cloth.countDocuments({ _id: { $in: uniqueIds }, $or: [{ ownerId: null }, { ownerId: req.userId }] });
    if (count !== uniqueIds.length) return res.status(400).json({ error: 'Outfit contains unavailable items' });
    const outfitKey = uniqueIds.join(':');
    const feedback = await RecommendationFeedback.findOneAndUpdate(
      { userId: req.userId, outfitKey }, { userId: req.userId, outfitKey, itemIds: uniqueIds, rating },
      { upsert: true, new: true, runValidators: true });
    res.json({ rating: feedback.rating, outfitKey });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

router.put('/thermal-preference', async (req, res) => {
  try {
    const { thermalPreference } = req.body;
    if (!['cold', 'balanced', 'hot'].includes(thermalPreference)) {
      return res.status(400).json({ error: 'Thermal preference must be cold, balanced, or hot' });
    }

    const user = await User.findByIdAndUpdate(
      req.userId,
      { thermalPreference },
      { new: true, runValidators: true },
    );
    if (!user) return res.status(404).json({ error: 'User not found' });

    res.json({ thermalPreference: user.thermalPreference });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete user account
router.delete('/delete', async (req, res) => {
  try {
    const user = await User.findById(req.userId);
    if (!user) return res.status(404).json({ error: 'User not found' });
    await Outfit.deleteMany({ userId: user._id });
    await Cloth.deleteMany({ ownerId: user._id });
    await RecommendationFeedback.deleteMany({ userId: user._id });
    await user.deleteOne();
    res.json({ message: 'User account deleted successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;

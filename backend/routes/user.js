const express = require('express');
const router = express.Router();
const User = require('../models/User');

// Toggle favorite (Add or Remove)
router.post('/favorites/toggle', async (req, res) => {
  try {
    const { userId, itemId } = req.body;
    const user = await User.findById(userId);
    
    if (!user) return res.status(404).json({ error: 'User not found' });

    // Check if item is already in favorites
    const index = user.favorites.indexOf(itemId);

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
router.get('/favorites/:userId', async (req, res) => {
  try {
    const user = await User.findById(req.params.userId).populate('favorites');
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json(user.favorites);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
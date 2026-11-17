const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

const router = express.Router();
const JWT_SECRET = process.env.JWT_SECRET;

function issueToken(userId) {
  if (!JWT_SECRET) throw new Error('JWT_SECRET is not configured');
  return jwt.sign({ userId }, JWT_SECRET, { expiresIn: '7d' });
}

// Register
router.post('/register', async (req, res) => {
  try {
    const { name, email, password, gender } = req.body;
    if (typeof name !== 'string' || !name.trim() ||
        typeof email !== 'string' || !/^\S+@\S+\.\S+$/.test(email.trim()) ||
        typeof password !== 'string' || password.length < 8 ||
        !['men', 'women', 'unisex'].includes(gender)) {
      return res.status(400).json({ error: 'Enter a name, valid email, password with at least 8 characters, and wardrobe preference' });
    }
    if (!JWT_SECRET) return res.status(503).json({ error: 'Authentication is not configured' });
    const normalizedEmail = email.trim().toLowerCase();
    
    // Check if user exists
    const existingUser = await User.findOne({ email: normalizedEmail });
    if (existingUser) return res.status(400).json({ error: 'Email already exists' });

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    // Create user
    const user = new User({ name: name.trim(), email: normalizedEmail, passwordHash, gender });
    await user.save();

    // Create token
    const token = issueToken(user._id);
    
    res.status(201).json({
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        gender: user.gender,
        thermalPreference: user.thermalPreference || 'balanced',
        preferredStyle: user.preferredStyle || 'any',
        preferredColors: user.preferredColors || [],
      },
    });
  } catch (err) {
    if (err.code === 11000) return res.status(409).json({ error: 'Email already exists' });
    res.status(500).json({ error: err.message });
  }
});

// Login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (typeof email !== 'string' || typeof password !== 'string') {
      return res.status(400).json({ error: 'Email and password are required' });
    }
    if (!JWT_SECRET) return res.status(503).json({ error: 'Authentication is not configured' });
    
    const user = await User.findOne({ email: email.trim().toLowerCase() });
    if (!user) return res.status(400).json({ error: 'Invalid credentials' });

    const validPassword = await bcrypt.compare(password, user.passwordHash);
    if (!validPassword) return res.status(400).json({ error: 'Invalid credentials' });

    const token = issueToken(user._id);
    
    res.json({
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        gender: user.gender,
        thermalPreference: user.thermalPreference || 'balanced',
        preferredStyle: user.preferredStyle || 'any',
        preferredColors: user.preferredColors || [],
      },
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;

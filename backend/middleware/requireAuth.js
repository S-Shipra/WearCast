const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');
const User = require('../models/User');

const JWT_SECRET = process.env.JWT_SECRET;

async function requireAuth(req, res, next) {
  const authorization = req.get('authorization') || '';
  const [scheme, token] = authorization.split(' ');

  if (scheme !== 'Bearer' || !token) {
    return res.status(401).json({ error: 'Authentication required' });
  }
  if (!JWT_SECRET) {
    return res.status(503).json({ error: 'Authentication is not configured' });
  }

  try {
    const payload = jwt.verify(token, JWT_SECRET);
    if (!mongoose.isValidObjectId(payload.userId)) {
      return res.status(401).json({ error: 'Invalid or expired session' });
    }
    const user = await User.exists({ _id: payload.userId });
    if (!user) return res.status(401).json({ error: 'Invalid or expired session' });
    req.userId = user._id.toString();
    return next();
  } catch (_) {
    return res.status(401).json({ error: 'Invalid or expired session' });
  }
}

module.exports = requireAuth;

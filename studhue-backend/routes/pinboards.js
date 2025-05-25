const express = require('express');
const jwt = require('jsonwebtoken');

const SECRET_KEY = 'your_secret_key'; // Replace with environment variable in production

module.exports = function (db) {
  const router = express.Router();

  function authenticateToken(req, res, next) {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    if (!token) return res.sendStatus(401);

    jwt.verify(token, SECRET_KEY, (err, user) => {
      if (err) return res.sendStatus(403);
      req.user = user;
      next();
    });
  }

  // Pin a post to a pinboard
  router.post('/pin', authenticateToken, (req, res) => {
    const { board_ID, post_ID } = req.body;
    const userId = req.user.userId;

    // Optionally verify that the board belongs to the user

    db.run(
      'INSERT INTO Pinboard_Posts (board_ID, post_ID) VALUES (?, ?)',
      [board_ID, post_ID],
      function (err) {
        if (err) return res.status(400).json({ message: 'Already pinned or error', error: err.message });
        res.json({ message: 'Post pinned to pinboard' });
      }
    );
  });

  // Unpin a post from a pinboard
  router.delete('/pin', authenticateToken, (req, res) => {
    const { board_ID, post_ID } = req.body;
    const userId = req.user.userId;

    db.run(
      'DELETE FROM Pinboard_Posts WHERE board_ID = ? AND post_ID = ?',
      [board_ID, post_ID],
      function (err) {
        if (err) return res.status(500).json({ message: 'DB error', error: err.message });
        res.json({ message: 'Post unpinned from pinboard' });
      }
    );
  });

  return router;
};

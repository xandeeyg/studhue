const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');

const SECRET_KEY = 'your_secret_key';

// Middleware to authenticate JWT token
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) return res.sendStatus(401);

  jwt.verify(token, SECRET_KEY, (err, user) => {
    if (err) return res.sendStatus(403);
    req.user = user; // { userId, username }
    next();
  });
}

// Export a function that takes db so you can reuse the same db instance
module.exports = function(db) {
  // Create post (regular or product)
  router.post('/', authenticateToken, (req, res) => {
    const { caption, post_type, product_name, details, stock_quantity, price, variations } = req.body;
    const userId = req.user.userId;
    const postId = uuidv4();
    const postDate = new Date().toISOString();

    db.run(
      'INSERT INTO Posts (post_id, user_id, caption, post_type, post_date) VALUES (?, ?, ?, ?, ?)',
      [postId, userId, caption, post_type, postDate],
      function (err) {
        if (err) return res.status(500).json({ message: 'DB error creating post', error: err.message });

        if (post_type === 'product') {
          const productId = uuidv4();
          db.run(
            'INSERT INTO Products (product_id, user_id, post_id, product_name, details, stock_quantity, price) VALUES (?, ?, ?, ?, ?, ?, ?)',
            [productId, userId, postId, product_name, details, stock_quantity, price],
            function (err) {
              if (err) return res.status(500).json({ message: 'DB error creating product', error: err.message });

              if (variations && Array.isArray(variations) && variations.length > 0) {
                const stmt = db.prepare('INSERT INTO Product_Variations (variation_id, product_id, variation_name) VALUES (?, ?, ?)');
                for (const variationName of variations) {
                  stmt.run(uuidv4(), productId, variationName);
                }
                stmt.finalize((err) => {
                  if (err) return res.status(500).json({ message: 'DB error creating variations', error: err.message });
                  return res.status(201).json({ message: 'Product post created', postId, productId });
                });
              } else {
                return res.status(201).json({ message: 'Product post created', postId, productId });
              }
            }
          );
        } else {
          return res.status(201).json({ message: 'Regular post created', postId });
        }
      }
    );
  });

  // Edit post (caption for regular, caption + product info for product posts)
  router.put('/:postId', authenticateToken, (req, res) => {
    const { postId } = req.params;
    const { caption, product_name, details, stock_quantity, price } = req.body;
    const userId = req.user.userId;

    db.get('SELECT * FROM Posts WHERE post_id = ?', [postId], (err, post) => {
      if (err) return res.status(500).json({ message: 'DB error', error: err.message });
      if (!post) return res.status(404).json({ message: 'Post not found' });
      if (post.user_id !== userId) return res.status(403).json({ message: 'Not authorized' });

      // Update caption in Posts
      db.run('UPDATE Posts SET caption = ? WHERE post_id = ?', [caption, postId], function (err) {
        if (err) return res.status(500).json({ message: 'DB error updating post', error: err.message });

        if (post.post_type === 'product') {
          // Update product info as well
          db.get('SELECT * FROM Products WHERE post_id = ?', [postId], (err, product) => {
            if (err) return res.status(500).json({ message: 'DB error', error: err.message });
            if (!product) return res.status(404).json({ message: 'Product info not found' });

            db.run(
              'UPDATE Products SET product_name = ?, details = ?, stock_quantity = ?, price = ? WHERE post_id = ?',
              [
                product_name || product.product_name,
                details || product.details,
                stock_quantity !== undefined ? stock_quantity : product.stock_quantity,
                price !== undefined ? price : product.price,
                postId
              ],
              function (err) {
                if (err) return res.status(500).json({ message: 'DB error updating product', error: err.message });
                res.json({ message: 'Product post updated' });
              }
            );
          });
        } else {
          // Regular post updated
          res.json({ message: 'Post updated' });
        }
      });
    });
  });

  // Delete post (only if user owns post)
  router.delete('/:postId', authenticateToken, (req, res) => {
    const { postId } = req.params;
    const userId = req.user.userId;

    db.get('SELECT * FROM Posts WHERE post_id = ?', [postId], (err, post) => {
      if (err) return res.status(500).json({ message: 'DB error', error: err.message });
      if (!post) return res.status(404).json({ message: 'Post not found' });
      if (post.user_id !== userId) return res.status(403).json({ message: 'Not authorized' });

      if (post.post_type === 'product') {
        // Delete variations first
        db.run('DELETE FROM Product_Variations WHERE product_id = (SELECT product_id FROM Products WHERE post_id = ?)', [postId], function (err) {
          if (err) return res.status(500).json({ message: 'DB error deleting variations', error: err.message });

          // Delete product
          db.run('DELETE FROM Products WHERE post_id = ?', [postId], function (err) {
            if (err) return res.status(500).json({ message: 'DB error deleting product', error: err.message });

            // Delete post
            db.run('DELETE FROM Posts WHERE post_id = ?', [postId], function (err) {
              if (err) return res.status(500).json({ message: 'DB error deleting post', error: err.message });
              res.json({ message: 'Product post deleted' });
            });
          });
        });
      } else {
        // Regular post delete only post record
        db.run('DELETE FROM Posts WHERE post_id = ?', [postId], function (err) {
          if (err) return res.status(500).json({ message: 'DB error deleting post', error: err.message });
          res.json({ message: 'Post deleted' });
        });
      }
    });
  });

  // Get all posts
  router.get('/', authenticateToken, (req, res) => {
    const query = `
      SELECT 
        Posts.post_id,
        Posts.user_id,
        Posts.caption,
        Posts.post_type,
        Posts.post_date,
        Users.username,
        Users.profile_picture
      FROM Posts
      JOIN Users ON Posts.user_id = Users.user_id
      ORDER BY Posts.post_date DESC
    `;

    db.all(query, [], (err, rows) => {
      if (err) {
        console.error('DB error fetching posts:', err.message);
        return res.status(500).json({ message: 'DB error fetching posts' });
      }

      res.json(rows);
    });
  });

  return router;
};


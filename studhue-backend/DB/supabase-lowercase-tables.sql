-- Users table with lowercase names
CREATE TABLE IF NOT EXISTS users (
  user_id UUID PRIMARY KEY,
  email VARCHAR(255) UNIQUE,
  full_name VARCHAR(255),
  username VARCHAR(100) UNIQUE,
  age INTEGER,
  birthdate DATE,
  address TEXT,
  phone_number VARCHAR(20),
  password TEXT,
  category VARCHAR(50),
  account_date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  profile_picture TEXT
);

-- Posts table with lowercase names
CREATE TABLE IF NOT EXISTS posts (
  post_id UUID PRIMARY KEY,
  user_id UUID,
  caption TEXT,
  post_type VARCHAR(20) CHECK (post_type IN ('regular', 'product')),
  post_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  image_url TEXT,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Products table with lowercase names
CREATE TABLE IF NOT EXISTS products (
  product_id UUID PRIMARY KEY,
  post_id UUID,
  product_name VARCHAR(255),
  description TEXT,
  stock_quantity INTEGER,
  price NUMERIC(10, 2),
  FOREIGN KEY (post_id) REFERENCES posts(post_id) ON DELETE CASCADE
);

-- Product Variations table with lowercase names
CREATE TABLE IF NOT EXISTS product_variations (
  variation_id UUID PRIMARY KEY,
  product_id UUID,
  variation_name VARCHAR(100),
  FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
);

-- Followers table with lowercase names
CREATE TABLE IF NOT EXISTS followers (
  follower_id UUID,
  following_id UUID,
  PRIMARY KEY (follower_id, following_id),
  FOREIGN KEY (follower_id) REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (following_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Pinboards table with lowercase names
CREATE TABLE IF NOT EXISTS pinboards (
  board_id UUID PRIMARY KEY,
  user_id UUID,
  board_name VARCHAR(100),
  board_description TEXT,
  board_date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Pinboard Posts table with lowercase names
CREATE TABLE IF NOT EXISTS pinboard_posts (
  board_id UUID,
  post_id UUID,
  PRIMARY KEY (board_id, post_id),
  FOREIGN KEY (board_id) REFERENCES pinboards(board_id) ON DELETE CASCADE,
  FOREIGN KEY (post_id) REFERENCES posts(post_id) ON DELETE CASCADE
);

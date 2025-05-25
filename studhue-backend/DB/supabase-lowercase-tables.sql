-- Users table with lowercase names
CREATE TABLE IF NOT EXISTS users (
  user_id TEXT PRIMARY KEY,
  email TEXT UNIQUE,
  full_name TEXT,
  username TEXT UNIQUE,
  age INTEGER,
  birthdate TEXT,
  address TEXT,
  phone_number TEXT,
  password TEXT,
  category TEXT,
  account_date_creation TEXT
);

-- Posts table with lowercase names
CREATE TABLE IF NOT EXISTS posts (
  post_id TEXT PRIMARY KEY,
  user_id TEXT,
  caption TEXT,
  is_product INTEGER,
  product_name TEXT,
  product_price REAL,
  post_date TEXT,
  FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Followers table with lowercase names
CREATE TABLE IF NOT EXISTS followers (
  follower_id TEXT,
  following_id TEXT,
  PRIMARY KEY (follower_id, following_id),
  FOREIGN KEY (follower_id) REFERENCES users(user_id),
  FOREIGN KEY (following_id) REFERENCES users(user_id)
);

-- Pinboards table with lowercase names
CREATE TABLE IF NOT EXISTS pinboards (
  board_id TEXT PRIMARY KEY,
  user_id TEXT,
  board_name TEXT,
  board_description TEXT,
  board_date_creation TEXT,
  FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Pinboard_Posts table with lowercase names
CREATE TABLE IF NOT EXISTS pinboard_posts (
  board_id TEXT,
  post_id TEXT,
  PRIMARY KEY (board_id, post_id),
  FOREIGN KEY (board_id) REFERENCES pinboards(board_id),
  FOREIGN KEY (post_id) REFERENCES posts(post_id)
);

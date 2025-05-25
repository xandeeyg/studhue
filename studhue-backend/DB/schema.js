module.exports = function (db) {
  db.serialize(() => {
    db.run(`
      CREATE TABLE IF NOT EXISTS Users (
        user_ID TEXT PRIMARY KEY,
        email TEXT UNIQUE,
        full_name TEXT,
        username TEXT UNIQUE,
        age INTEGER,
        birthdate TEXT,           -- Store dates as ISO8601 string
        address TEXT,
        phone_number TEXT,        -- Store phone as text to preserve leading zeros
        password TEXT,
        category TEXT,            -- e.g., 'regular-user', 'digital-artist', 'artist'
        account_date_creation TEXT
      )
    `);

    db.run(`
      CREATE TABLE IF NOT EXISTS Posts (
        post_ID TEXT PRIMARY KEY,
        user_ID TEXT,
        caption TEXT,
        is_product INTEGER,
        product_name TEXT,
        product_price REAL,
        post_date TEXT,
        FOREIGN KEY (user_ID) REFERENCES Users(user_ID)
      )
    `);

    db.run(`
      CREATE TABLE IF NOT EXISTS Followers (
        follower_id TEXT,
        following_id TEXT,
        PRIMARY KEY (follower_id, following_id),
        FOREIGN KEY (follower_id) REFERENCES Users(user_ID),
        FOREIGN KEY (following_id) REFERENCES Users(user_ID)
      )
    `);

    db.run(`
      CREATE TABLE IF NOT EXISTS Pinboards (
        board_ID TEXT PRIMARY KEY,
        user_id TEXT,
        board_name TEXT,
        board_description TEXT,
        board_date_creation TEXT,
        FOREIGN KEY (user_id) REFERENCES Users(user_ID)
      )
    `);

    db.run(`
      CREATE TABLE IF NOT EXISTS Pinboard_Posts (
        board_ID TEXT,
        post_ID TEXT,
        PRIMARY KEY (board_ID, post_ID),
        FOREIGN KEY (board_ID) REFERENCES Pinboards(board_ID),
        FOREIGN KEY (post_ID) REFERENCES Posts(post_ID)
      )
    `);
  });
};


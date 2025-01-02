CREATE TABLE favorite (
  user_id INTEGER NOT NULL,
  tweet_id INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES user(id),
  FOREIGN KEY (tweet_id) REFERENCES tweet(id)
);

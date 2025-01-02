CREATE TABLE report (
  user_id INTEGER NOT NULL,
  tweet_id INTEGER NOT NULL,
  reason VARCHAR(255) NOT NULL,
  FOREIGN KEY (user_id) REFERENCES user(id),
  FOREIGN KEY (tweet_id) REFERENCES tweet(id)
);

/*Problem Statement: 3-Day Rolling Average of Tweets
As a data analyst, understanding user engagement trends over time is crucial. The goal of this query is to calculate the 3-day rolling average of tweet counts for every individual user in the dataset.
This calculation shows how a user's activity (tweet count) smooths out over a short, defined period.

Requirements:
Input Table: tweets (likely includes user_id, tweet_date, tweet_count or similar metrics).
Logic: Calculate the average tweet count based on the current day's data and the data from the two preceding days, for a total of three days.
Grouping: The average must be calculated separately for each user_id.
Output: Display the user_id, tweet_date, and the calculated rolling_avg_3d, rounded to 2 decimal places.*/


SELECT
user_id,
tweet_date,
ROUND(
  AVG(tweet_count) OVER(
  PARTITION BY user_id
  ORDER BY tweet_date
  ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ),
  2
  ) AS rolling_avg_3d
FROM tweets
ORDER BY user_id, tweet_date

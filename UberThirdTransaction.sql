/*Problem Statement: Uber Third Transaction

As part of transaction analysis, we need to extract a specific transaction record for every user based on chronological order.
The goal is to write an SQL query that identifies the third transaction made by each unique user.

Requirements:
Input Table: transactions (user_id, spend, transaction_date).
Logic: The "third" transaction is determined by ordering all transactions for a single user by transaction_date in ascending order.
Output: Display the user_id, spend, and transaction_date for only the third transaction of each user.*/


WITH view_top_3 AS (
SELECT
  user_id,
  spend,
  transaction_date,
  ROW_NUMBER () OVER (
    PARTITION BY user_id
    ORDER BY
      transaction_date
  ) AS ranka
FROM transactions
)

SELECT user_id, spend, transaction_date FROM view_top_3
where ranka = 3

Problem Statement: Calculating TikTok Account Activation Rate

As a Senior Data Analyst, the goal is to determine the activation rate for a specific cohort of users. 
New users sign up via email (recorded in the emails table) and confirm their account by responding to a text message (recorded in the texts table). Users may receive multiple confirmation texts before activating.

The crucial constraint is that the analysis must focus exclusively on the population of users found in the emails table.


emails: Contains user_id (or email_id as the unique user key) and signup details. This defines the total population (the denominator).
texts: Contains user_id (or email_id), action (e.g., 'confirm', 'send'), and timestamp. This defines the activation events.

Requirements:
Define Population (Denominator): Total count of unique users in the emails table.
Define Success (Numerator): Count of unique users from the emails table who successfully performed the 'confirm' action in the texts table.
Output: The final percentage, rounded to 2 decimal places.

SELECT 
  ROUND(COUNT(texts.email_id)::DECIMAL
    /COUNT(DISTINCT emails.email_id),2) AS activation_rate
FROM emails
LEFT JOIN texts
  ON emails.email_id = texts.email_id
  AND texts.signup_action = 'Confirmed';  

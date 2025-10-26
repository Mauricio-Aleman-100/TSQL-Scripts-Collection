/*Problem Statement: Snapchat Time Allocation
As a data analyst for a social media company, the task is to analyze how different age groups allocate their time between core activities (sending vs. opening content).
The goal is to write a query that provides a breakdown of time spent sending snaps versus time spent opening snaps, expressed as a percentage of the total time spent across both activities, grouped by user age.

Input Tables (Conceptual):

activities (or a similar join table): Contains user_id, activity_type, time_spent.
users (or a similar table): Contains user_id, age.

Requirements & Calculation Notes:
Grouping: The final results must be grouped by age (or age_group if the data is pre-grouped).
Metrics: Calculate two percentages for each age group:
Sending Percentage
Opening Percentage
Decimal Handling (Crucial): To prevent integer division (which would round the result to 0 or 1), ensure the numerator or denominator is converted to a decimal type before division. Multiplying by 100.0 is the most concise way to achieve this.

Output Format: Round the final percentage values to 2 decimal places.*/

WITH snaps_statistics AS (
  SELECT 
    age.age_bucket, 
    SUM(CASE WHEN activities.activity_type = 'send' 
      THEN activities.time_spent ELSE 0 END) AS send_timespent, 
    SUM(CASE WHEN activities.activity_type = 'open' 
      THEN activities.time_spent ELSE 0 END) AS open_timespent, 
    SUM(activities.time_spent) AS total_timespent 
  FROM activities
  INNER JOIN age_breakdown AS age 
    ON activities.user_id = age.user_id 
  WHERE activities.activity_type IN ('send', 'open') 
  GROUP BY age.age_bucket
) 

SELECT 
  age_bucket, 
  ROUND(100.0 * send_timespent / total_timespent, 2) AS send_perc, 
  ROUND(100.0 * open_timespent / total_timespent, 2) AS open_perc 
FROM snaps_statistics;

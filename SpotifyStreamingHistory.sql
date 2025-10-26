Problem Statement: Spotify User Activity Cumulative Sum
As a Data Engineer at Spotify, you need to consolidate streaming data to understand user engagement up to a specific date. 
The task is to write a query that outputs the cumulative count of song plays (streams) for every unique (user_id, song_id) pair, considering all plays up to the specified cut-off date of August 4th, 2022.

songs_history: Contains historical streaming data (e.g., user_id, song_id, play_count).
songs_weekly: Contains recent streaming data (e.g., user_id, song_id, play_count, play_date).

Requirements:
Data Consolidation: Combine the data from both songs_history and songs_weekly.
Date Filter: Only include plays that occurred up to and including August 4th, 2022. (Note: Historical data in songs_history is assumed to be valid and should be included).
Grouping: The count must be cumulative based on the (user_id, song_id) pair.
Output Fields: Display the user_id, song_id, and the calculated cumulative_plays.
Final Sort: Sort the results in descending order by cumulative_plays.

SELECT 
  user_id, 
  song_id, 
  SUM(song_plays) AS song_count
FROM (
  SELECT 
    user_id, 
    song_id, 
    song_plays
  FROM songs_history
  
  UNION ALL
  
  SELECT 
    user_id, 
    song_id, 
    COUNT(song_id) AS song_plays
  FROM songs_weekly
  WHERE listen_time <= '08/04/2022 23:59:59'
  GROUP BY user_id, song_id
) AS report
GROUP BY 
  user_id, 
  song_id
ORDER BY song_count DESC;

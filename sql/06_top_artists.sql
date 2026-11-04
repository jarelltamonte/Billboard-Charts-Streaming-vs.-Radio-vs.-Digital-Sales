WITH artist_stats AS (
  SELECT chart,
         regexp_replace(artist, '\s+(Featuring|&|x|X|With|\+)\s+.*$', '') AS lead_artist,
         COUNT(*) AS chart_weeks,
         COUNT(DISTINCT song) AS songs,
         COUNT(*) FILTER (WHERE chart_rank = 1) AS weeks_at_1
  FROM fair_charts
  GROUP BY chart, lead_artist
),
ranked AS (
  SELECT *,
         RANK() OVER (PARTITION BY chart ORDER BY chart_weeks DESC) AS artist_rank
  FROM artist_stats
)
SELECT chart, artist_rank, lead_artist, chart_weeks, songs, weeks_at_1
FROM ranked
WHERE artist_rank <= 5
ORDER BY chart, artist_rank;
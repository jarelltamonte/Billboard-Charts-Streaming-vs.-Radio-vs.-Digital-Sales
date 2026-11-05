-- QUESTION: Which artists spend the most weeks in the top 25 on each platform?
-- DATA:     fair_charts (top 25, 2013-01-16 onward). Needs 03_views.sql.
-- METHOD:   - chart_weeks = number of weekly top-25 appearances (one row per
--             song per week), summed per lead artist.
--           - regexp_replace keeps only the lead artist, so
--             "Drake Featuring Rihanna" counts toward Drake.
--           - RANK() ranks artists within each chart; ties share a rank.
-- CAVEATS:  - Guest artists get no credit for features.
--           - The regex can cut real group names that contain "&" or "With"
--             (e.g. "Macklemore & Ryan Lewis" becomes "Macklemore").
--           - "X" counts as a collaboration marker ("Marshmello X Jonas
--             Brothers") unless it is part of a name and is followed by
--             Featuring, &, x, With or + ("Lil Nas X Featuring ..." stays
--             "Lil Nas X"). The lookahead in the pattern handles this.
--           - A few rows have raw HTML in the artist field (a scraping
--             artifact in the source data).
-- FINDING:  Most weeks in the top 25:
--             streaming: Drake 808 (49 weeks at #1), Morgan Wallen 571,
--                        Taylor Swift 520
--             radio:     Taylor Swift 496, Ed Sheeran 415, The Weeknd 409
--             digital:   Taylor Swift 461, Ed Sheeran and Morgan Wallen 328 (tie)
--           Taylor Swift is the only artist in the top 3 on all three charts.
--           Drake leads streaming through volume (178 songs). BTS has 52 weeks
--           at #1 on digital sales without being a top-5 artist by weeks.

WITH artist_stats AS (
  SELECT chart,
         regexp_replace(artist, '\s+(Featuring|&|x|With|\+|X(?!\s+(Featuring|&|x|With|\+)\s))\s+.*$', '') AS lead_artist,
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
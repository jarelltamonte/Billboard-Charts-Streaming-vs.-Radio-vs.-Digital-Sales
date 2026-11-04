-- QUESTION: Which songs stay in the top 25 the longest on each platform?
-- DATA:     fair_charts (top 25, 2013-01-16 onward). Needs 03_views.sql.
-- METHOD:   - weeks_in_top25 = number of weeks a song appears in the top 25.
--           - Songs are grouped by song AND artist, so different songs that
--             share a title (e.g. "Stay") are never mixed together.
--           - RANK() ranks songs within each chart; ties share a rank.
--           - first_date / last_date show when each song entered and left.
-- CAVEATS:  - Songs still charting on 2026-10-21 (e.g. "Ordinary" by Alex
--             Warren on streaming) and songs already charting when the data
--             begins (e.g. "Gangnam Style" on streaming) have their weeks cut
--             off, so their true totals could be higher.
--           - A song that leaves the top 25 and re-enters is one song with all
--             its weeks added together.
--           - Titles are matched exactly, so the same song spelled with
--             different capitalisation would count as two songs.
-- FINDING:  "Lose Control" by Teddy Swims spent the most weeks in the top 25 on
--           all three charts (streaming 98, radio 91, digital 110).
--           "Beautiful Things" by Benson Boone is also in the top 5 on all
--           three (78 / 82 / 83). Radio's longest-running songs also spend the
--           most weeks at #1, e.g. "A Bar Song (Tipsy)" 27 and
--           "Blinding Lights" 26.

WITH song_stats AS (
  SELECT chart, song, artist,
         COUNT(*) AS weeks_in_top25,
         COUNT(*) FILTER (WHERE chart_rank = 1) AS weeks_at_1,
         MIN(chart_rank) AS best_rank,
         MIN(chart_date) AS first_date,
         MAX(chart_date) AS last_date
  FROM fair_charts
  GROUP BY chart, song, artist
),
ranked AS (
  SELECT *,
         RANK() OVER (PARTITION BY chart ORDER BY weeks_in_top25 DESC) AS song_rank
  FROM song_stats
)
SELECT chart, song_rank, song, artist,
       weeks_in_top25, weeks_at_1, best_rank, first_date, last_date
FROM ranked
WHERE song_rank <= 5
ORDER BY chart, song_rank, song;
-- QUESTION: How many different songs reach the top 25 each year, per platform?
-- DATA:     fair_charts (top 25, 2013-01-16 onward). Needs 03_views.sql.
-- METHOD:   A "song" is a distinct song + artist pair. SELECT DISTINCT in the
--           CTE keeps one row per song per year per chart, then the outer
--           query counts them.
-- CAVEATS:  - A song that charts in two different years counts once in each.
--           - 2026 is a partial year (42 weeks, through 2026-10-21); did not
--             compare its raw count with full years.
--           - Artist credits can vary slightly, so counts are approximate.
-- FINDING:  Digital sales has the most distinct songs in every year (189 in
--           2013, peaking at 416 in 2023). Radio stays flat to slightly down
--           (147 in 2013, 128 in 2025). Streaming grows from 131 in 2013 to a
--           peak of 324 in 2022, then falls to 207 in 2025.

WITH song_years AS (
  SELECT DISTINCT chart, EXTRACT(YEAR FROM chart_date)::int AS yr, song, artist
  FROM fair_charts
)
SELECT yr,
  COUNT(*) FILTER (WHERE chart = 'streaming') AS streaming,
  COUNT(*) FILTER (WHERE chart = 'radio')     AS radio,
  COUNT(*) FILTER (WHERE chart = 'digital')   AS digital
FROM song_years
GROUP BY yr
ORDER BY yr;
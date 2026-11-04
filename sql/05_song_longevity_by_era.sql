-- QUESTION: How many weeks does a typical song stay in the top 25 on each
--           platform, and has that changed over time?
-- DATA:     fair_charts (top 25, 2013-01-16 onward). Needs 03_views.sql.
-- METHOD:   - weeks_on_chart = number of weeks a song spent in the top 25.
--           - Only complete runs are kept: songs that first charted after
--             2013-01-16 and were gone before 2026-10-21. Otherwise runs
--             that started before the data or are still going get cut short.
--           - Songs are grouped into eras by the year they debuted.
--           - The median is used instead of the average, because a few very
--             long runs (e.g. "Lose Control" by Teddy Swims) pull averages up.
--           - LAG compares each era with the previous era on the same chart.
-- CAVEATS:  - A song that leaves a chart and re-enters is one song with all
--             its weeks added together.
--           - COALESCE turns the first era's missing "previous" value into 0.
--             For the first era, 0 means "no earlier era", NOT "median of 0".
-- FINDING:  Median weeks in the top 25, by debut era:
--             radio:     6 -> 8 -> 9  (songs stay longer over time)
--             streaming: 8 -> 1 -> 1  (the big drop happened by 2018-2022)
--             digital:   3 -> 1 -> 1
--           Since 2018 the typical streaming and digital song lasts one week,
--           while the typical radio song lasts 8-9 weeks.

WITH song_weeks AS (
  SELECT chart, song, artist,
         COUNT(*) AS weeks_on_chart,
         MIN(chart_date) AS debut
  FROM fair_charts
  GROUP BY chart, song, artist
  HAVING MIN(chart_date) > '2013-01-16'
     AND MAX(chart_date) < '2026-10-21'
),
era_medians AS (
  SELECT chart,
    CASE WHEN EXTRACT(YEAR FROM debut) <= 2017 THEN '2013-2017'
         WHEN EXTRACT(YEAR FROM debut) <= 2022 THEN '2018-2022'
         ELSE '2023-2026' END AS era,
    COUNT(*) AS songs,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY weeks_on_chart) AS median_weeks
  FROM song_weeks
  GROUP BY chart, era
)
SELECT chart, era, songs, median_weeks,
  COALESCE(LAG(median_weeks) OVER (PARTITION BY chart ORDER BY era), 0) AS prev_era_median,
  COALESCE(median_weeks - LAG(median_weeks) OVER (PARTITION BY chart ORDER BY era), 0) AS change
FROM era_medians
ORDER BY chart, era;
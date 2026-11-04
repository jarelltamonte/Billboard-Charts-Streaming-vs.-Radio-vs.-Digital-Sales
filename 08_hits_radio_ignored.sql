-- QUESTION: Which songs reached the top 5 of the digital sales chart but
--           never made the radio top 25?
-- DATA:     fair_charts (top 25, 2013-01-16 onward). Needs views.sql.
-- METHOD:   - best = each song's best (lowest) rank on each chart.
--           - LEFT JOIN from digital to radio; r.song IS NULL keeps the songs
--             with no radio match (an "anti-join").
--           - Songs are matched case-insensitively (LOWER) because the same
--             song can be capitalised differently on different charts, e.g.
--             "Highest In The Room" vs "HIGHEST IN THE ROOM".
-- CAVEATS:  - Matching is by song title + artist text. Different artist
--             credits ("Featuring" vs "&") or quote marks in titles can make a
--             song look "missing" when it is on radio under another spelling.
--             Matching on lead artist only changed the count by about 6.
--           - "Never made the radio top 25" means within fair_charts, i.e.
--             since 2013-01-16.
-- FINDING:  612 of the 1,065 songs that reached the digital top 5 (about 57%)
--           never made the radio top 25. Many are fan-driven acts such as BTS
--           and Jimin: sales charts reward fan intensity, radio rewards broad
--           appeal.
-- TIP:      Replace the SELECT list with COUNT(*) to get the total (612).

WITH best AS (
  SELECT chart, song, artist, MIN(chart_rank) AS best_rank
  FROM fair_charts
  GROUP BY chart, song, artist
),
digital_top5 AS (
  SELECT d.song, d.artist,
         (r.song IS NULL) AS never_on_radio
  FROM best d
  LEFT JOIN best r
    ON LOWER(r.song) = LOWER(d.song)
   AND LOWER(r.artist) = LOWER(d.artist)
   AND r.chart = 'radio'
  WHERE d.chart = 'digital'
    AND d.best_rank <= 5
)
SELECT COUNT(*) AS digital_top5_songs,
       COUNT(*) FILTER (WHERE never_on_radio) AS never_made_radio_top25,
       ROUND(100.0 * COUNT(*) FILTER (WHERE never_on_radio) / COUNT(*)) AS pct_never_on_radio
FROM digital_top5;
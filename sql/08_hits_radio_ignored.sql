-- QUESTION: Of the songs that reached the top 5 of the digital sales chart,
--           what share never made the radio top 25?
-- DATA:     Digital songs come from fair_charts (top 25, 2013-01-16 onward).
--           Radio is checked in the full radio table (top 25, every date back
--           to 1990). Needs 03_views.sql.
-- METHOD:   - norm: song and artist are lowercased and trimmed once, up front,
--             so the same song spelled with different capitalisation is one
--             song on both charts (e.g. "Highest In The Room" on digital vs
--             "HIGHEST IN THE ROOM" on radio).
--           - best: each song's best rank on the digital chart, plus the first
--             week it reached the top 5.
--           - NOT EXISTS keeps digital top-5 songs with no radio top-25 row
--             (an "anti-join"). Unlike a join it cannot duplicate rows.
--           - The radio check uses the whole radio table, not fair_charts.
--             Otherwise an old radio hit that returned to the digital top 5
--             (e.g. "Bohemian Rhapsody" after the 2018 film) would look like
--             a song radio ignored, just because its radio run was before 2013.
--           - Only songs that first reached the digital top 5 at least 180
--             days before the last week in the data are counted. Radio is the
--             slow chart: in this data about 95% of the songs that do reach
--             radio get there within roughly 160 days, so a newer song may
--             simply not have reached radio yet.
-- CAVEATS:  - Matching is by song title + artist text. Different artist
--             credits ("Featuring" vs "Feat.") or quote marks in titles can
--             make a song look "missing" when it is on radio under another
--             spelling (e.g. "Rihanna Featuring Mikky Ekko").
--           - The 180-day cutoff is a judgement call. No cutoff gives 599 of
--             1,065 (56%); a 365-day cutoff gives 539 of 982 (55%).
--           - Checking radio only since 2013 wrongly counted 12 old hits
--             (e.g. "Lose Yourself", "Gangsta's Paradise") as never on radio.
-- FINDING:  567 of the 1,022 songs that reached the digital top 5 (about 55%)
--           never made the radio top 25. Many are fan-driven acts such as BTS
--           and Jimin: sales charts reward fan intensity, radio rewards broad
--           appeal.
-- TIP:      To see the songs instead of the count, select song_key and
--           artist_key from digital_top5 WHERE never_on_radio.

WITH norm AS (
  SELECT chart,
         LOWER(TRIM(song))   AS song_key,
         LOWER(TRIM(artist)) AS artist_key,
         chart_rank, chart_date
  FROM fair_charts
),
best AS (
  SELECT chart, song_key, artist_key,
         MIN(chart_rank) AS best_rank,
         MIN(chart_date) FILTER (WHERE chart_rank <= 5) AS first_top5_date
  FROM norm
  GROUP BY chart, song_key, artist_key
),
digital_top5 AS (
  SELECT d.song_key, d.artist_key,
         NOT EXISTS (
           SELECT 1 FROM radio r
           WHERE r.chart_rank <= 25
             AND LOWER(TRIM(r.song))   = d.song_key
             AND LOWER(TRIM(r.artist)) = d.artist_key
         ) AS never_on_radio
  FROM best d
  WHERE d.chart = 'digital'
    AND d.best_rank <= 5
    AND d.first_top5_date <= (SELECT MAX(chart_date) FROM fair_charts) - 180
)
SELECT COUNT(*) AS digital_top5_songs,
       COUNT(*) FILTER (WHERE never_on_radio) AS never_made_radio_top25,
       ROUND(100.0 * COUNT(*) FILTER (WHERE never_on_radio) / COUNT(*)) AS pct_never_on_radio
FROM digital_top5;

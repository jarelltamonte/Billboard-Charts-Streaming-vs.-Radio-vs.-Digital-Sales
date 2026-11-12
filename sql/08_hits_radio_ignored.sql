-- QUESTION: Of the songs that reached the top 5 of the digital sales chart,
--           what share never made the radio top 25?
-- DATA:     Digital songs come from fair_charts (top 25, 2013-01-16 onward).
--           Radio is checked in the full radio table (top 25, every date back
--           to 1990). Needs 03_views.sql (including song_key / artist_key).
-- METHOD:   - song_key() and artist_key() clean song and artist text so the
--             same song matches across charts despite different spellings,
--             capitalisation or credits ("Featuring" vs "Feat.").
--           - digital_best: each digital song's best rank, plus the first
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
-- CAVEATS:  - Matching uses the song title plus the LEAD artist, so a remix
--             with extra guests counts as the same song. Credits that differ
--             in the lead artist itself can still cause a missed match.
--           - The 180-day cutoff is a judgement call.
--           - Matching on raw text instead (lowercase only) gave 567 of 1,022
--             (55%); 25 songs were wrongly counted as never on radio because
--             of credit differences such as "Featuring" vs "Feat.".
-- FINDING:  542 of the 1,022 songs that reached the digital top 5 (about 53%)
--           never made the radio top 25. The biggest groups are artists with
--           intense fan bases: Taylor Swift (29 songs), BTS (23) and Tom
--           MacDonald (19). Sales charts reward fan intensity, radio rewards
--           broad appeal.
-- TIP:      To see the songs instead of the count, select song_key and
--           artist_key from digital_top5 WHERE never_on_radio.

WITH digital_best AS (
  SELECT song_key(song)     AS song_key,
         artist_key(artist) AS artist_key,
         MIN(chart_rank)    AS best_rank,
         MIN(chart_date) FILTER (WHERE chart_rank <= 5) AS first_top5_date
  FROM fair_charts
  WHERE chart = 'digital'
  GROUP BY song_key(song), artist_key(artist)
),
radio_keys AS (
  SELECT DISTINCT song_key(song) AS song_key, artist_key(artist) AS artist_key
  FROM radio
  WHERE chart_rank <= 25
),
digital_top5 AS (
  SELECT d.song_key, d.artist_key,
         NOT EXISTS (
           SELECT 1 FROM radio_keys r
           WHERE r.song_key   = d.song_key
             AND r.artist_key = d.artist_key
         ) AS never_on_radio
  FROM digital_best d
  WHERE d.best_rank <= 5
    AND d.first_top5_date <= (SELECT MAX(chart_date) FROM fair_charts) - 180
)
SELECT COUNT(*) AS digital_top5_songs,
       COUNT(*) FILTER (WHERE never_on_radio) AS never_made_radio_top25,
       ROUND(100.0 * COUNT(*) FILTER (WHERE never_on_radio) / COUNT(*)) AS pct_never_on_radio
FROM digital_top5;

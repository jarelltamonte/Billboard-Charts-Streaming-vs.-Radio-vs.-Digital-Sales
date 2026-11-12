-- Every analysis file (04 onward) reads from fair_charts.

CREATE OR REPLACE VIEW all_charts AS
SELECT 'streaming' AS chart, chart_date, song, artist, chart_rank FROM streams
UNION ALL
SELECT 'radio',   chart_date, song, artist, chart_rank FROM radio
UNION ALL
SELECT 'digital', chart_date, song, artist, chart_rank FROM digital;

CREATE OR REPLACE VIEW fair_charts AS
SELECT * FROM all_charts
WHERE chart_date >= '2013-01-16'
  AND chart_rank <= 25;


-- Matching keys: used to recognise the SAME song across charts.
-- Billboard spells the same song differently on different charts
-- ("Drake Featuring Majid Jordan" vs "Drake Feat. Majid Jordan",
-- "Victoria's Secret" with a straight vs a curly apostrophe), so comparing
-- the raw text makes one song look like two.
--
-- song_key:   lowercase, punctuation removed, spaces tidied.
-- artist_key: lead artist only (everything from Featuring / Feat. / Ft. /
--             With / & / and / x / + / a comma onward is dropped), then
--             cleaned like a song. The pattern keeps "Lil Nas X" intact
--             ("Lil Nas X Featuring ..." -> "lil nas x").
-- Both sides of a match are cleaned the same way, so cutting a duo name short
-- (e.g. "Macklemore & Ryan Lewis" -> "macklemore") does not prevent a match.
-- Used by the cross-chart analyses (08 and 09).

CREATE OR REPLACE FUNCTION song_key(txt text) RETURNS text
LANGUAGE sql IMMUTABLE AS $$
  SELECT COALESCE(
    NULLIF(trim(regexp_replace(lower(txt), '[^a-z0-9]+', ' ', 'g')), ''),
    lower(trim(txt)))
$$;

CREATE OR REPLACE FUNCTION artist_key(txt text) RETURNS text
LANGUAGE sql IMMUTABLE AS $$
  SELECT song_key(
    regexp_replace(
      regexp_replace(txt,
        '\s+(Featuring|Feat\.?|Ft\.?|With|&|and|x|\+|X(?!\s+(Featuring|Feat\.?|Ft\.?|With|&|and|x|\+)\s))\s+.*$',
        ''),
      ',.*$', ''))
$$;

CREATE OR REPLACE VIEW all_charts AS
SELECT 'streaming' AS chart, chart_date, song, artist, chart_rank FROM streams
UNION ALL
SELECT 'radio', chart_date, song, artist, chart_rank FROM radio
UNION ALL
SELECT 'digital', chart_date, song, artist, chart_rank FROM digital;

CREATE OR REPLACE VIEW fair_charts AS
SELECT * FROM all_charts
WHERE chart_date >= '2013-01-16'
  AND chart_rank <= 25;
ALTER TABLE streams
  ALTER COLUMN weeks_in_charts TYPE INT
  USING NULLIF(weeks_in_charts, '-')::INT;
 
ALTER TABLE radio
  ALTER COLUMN weeks_in_charts TYPE INT
  USING NULLIF(weeks_in_charts, '-')::INT;
 
ALTER TABLE digital
  ALTER COLUMN weeks_in_charts TYPE INT
  USING NULLIF(weeks_in_charts, '-')::INT;


SELECT table_name, data_type
FROM information_schema.columns
WHERE column_name = 'weeks_in_charts'
  AND table_name IN ('streams', 'radio', 'digital');

SELECT 'streams' AS tbl, COUNT(*) AS row_count FROM streams
UNION ALL SELECT 'radio',   COUNT(*) FROM radio
UNION ALL SELECT 'digital', COUNT(*) FROM digital;
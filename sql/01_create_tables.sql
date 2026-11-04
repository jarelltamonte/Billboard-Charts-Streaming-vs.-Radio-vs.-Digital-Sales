DROP VIEW IF EXISTS fair_charts;
DROP VIEW IF EXISTS all_charts;
DROP TABLE IF EXISTS streams, radio, digital;
 
CREATE TABLE streams (
    chart_date      DATE,
    song            VARCHAR(255),
    artist          VARCHAR(255),
    chart_rank      INT,
    last_week       VARCHAR(10),
    peak_position   INT,
    weeks_in_charts VARCHAR(10),
    image_url       TEXT
);
 
CREATE TABLE radio   (LIKE streams);
CREATE TABLE digital (LIKE streams);
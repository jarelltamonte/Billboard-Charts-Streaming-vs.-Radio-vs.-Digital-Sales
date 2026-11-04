# Billboard Charts: Streaming vs. Radio vs. Digital Sales

A PostgreSQL project comparing how songs perform on three Billboard weekly charts: **streaming**, **radio airplay** and **digital sales**.

**Main takeaway:** radio is the slow, steady chart. Songs reach it about five weeks later than streaming and stay far longer. Streaming and digital sales move fast, and since 2018 the typical song on either lasts one week in the top 25.

## Data

The dataset files are inside the `data/` folder. It contains three CSV files, one row per song per week:

| Table | File | Rows | Date range | Chart size |
|---|---|---|---|---|
| `streams` | streaming.csv | 35,950 | 2013-01-16 to 2026-10-21 | top 50 |
| `radio` | radio.csv | 93,950 | 1990-10-24 to 2026-10-21 | top 50 |
| `digital` | digital.csv | 53,525 | 2004-10-20 to 2026-10-21 | top 50, then top 25 |

Columns: `chart_date`, `song`, `artist`, `chart_rank`, `last_week`, `peak_position`, `weeks_in_charts`, `image_url`.

### Data issues and how they were handled

- **`weeks_in_charts` contains `-`** in 300 rows each in streams and radio, and 150 in digital (all weeks from 2026-09-16 onward). The column is loaded as text, then converted to a number with `-` set to `NULL`. The analyses count weeks directly and don't use this column.
- **The digital chart shrank from 50 to 25 rows per week on 2023-10-25.** Comparing it with the others would be unfair, so every analysis uses the **top 25** only.
- **The streaming chart starts on 2013-01-16**, so all comparisons start there.
- **2026 is a partial year** (42 weeks, through 2026-10-21).

The `fair_charts` view applies the top-25 and 2013-01-16 filters, and every analysis reads from it.

## How to run

Run the files in `sql/` in this order:

1. `01_create_tables.sql` creates the three empty tables. **It deletes existing data.**
2. Import the three CSVs into the matching tables (pgAdmin: right-click the table, then Import/Export Data. Use format csv, header on, delimiter `,`).
3. `02_cleanup_after_import.sql` converts `weeks_in_charts` to a number and checks the row counts.
4. `03_views.sql` creates the `all_charts` and `fair_charts` views.
5. Run any analysis file (`04` to `09`) in any order.

## Analyses and findings

| File | Question | Finding |
|---|---|---|
| `04_distinct_songs_per_year.sql` | How many different songs reach the top 25 each year? | Digital has the most in every year (189 in 2013, peak 416 in 2023). Radio stays flat (147 in 2013, 127 in 2024). Streaming peaks at 324 in 2022. |
| `05_song_longevity_by_era.sql` | How many weeks does a typical song stay in the top 25? | Median weeks by debut era (2013-17, 2018-22, 2023-26): radio 6, 8, 9; streaming 8, 1, 1; digital 3, 1, 1. |
| `06_top_artists.sql` | Which artists spend the most weeks in the top 25? | Taylor Swift is the only artist in the top 3 on all three charts. Drake leads streaming (808 weeks, 178 songs). |
| `07_top_songs.sql` | Which songs stay in the top 25 the longest? | "Lose Control" by Teddy Swims is #1 on all three charts (streaming 98 weeks, radio 91, digital 110). "Beautiful Things" by Benson Boone is top 5 on all three. |
| `08_hits_radio_ignored.sql` | How many digital top-5 songs never made the radio top 25? | 612 of 1,065 (57%). Many are fan-driven acts such as BTS. |
| `09_debut_lag_stream_vs_radio.sql` | Which chart does a song reach first? | Of 680 songs on both charts, radio comes a median of 35 days after streaming. Radio is later for 79%, the same week for 9%, and first for 12%. |

## Limitations

- Songs are matched across charts by song title and artist text (ignoring capitalization). Different artist credits (for example "Featuring" vs "&") can make the same song look like two songs.
- Lead artist is found with a text pattern, so guest artists get no credit and some group names containing "&" may be cut.
- "Debut" means the first week a song entered the top 25, not its release date.
- A song that leaves a chart and returns is counted as one song with its weeks added together. Songs still charting on 2026-10-21, or already charting when the data begins, have their week counts cut off.
- Everything is limited to the top 25 since 2013-01-16, so it says nothing about songs ranked 26 to 50 or about earlier years.

## Tools

PostgreSQL 18, pgAdmin 4. SQL techniques used: CTEs, window functions (`RANK`, `LAG`), joins and anti-joins, `PERCENTILE_CONT`, and views.

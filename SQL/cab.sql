 --  CHECKING ALL THE ROWS 
 SELECT *
 from taxi1;
-- RENAMING THE HEADER TO SHORT
ALTER TABLE taxi1 RENAME COLUMN trip_start_timestamp TO start_ts;
ALTER TABLE taxi1 RENAME COLUMN trip_end_timestamp TO end_ts;
ALTER TABLE taxi1 RENAME COLUMN trip_seconds TO trp_sec;
ALTER TABLE taxi1 RENAME COLUMN trip_miles TO trp_mi;
ALTER TABLE taxi1 RENAME COLUMN pickup_lat TO p_lat;
ALTER TABLE taxi1 RENAME COLUMN pickup_lon TO p_lon;
ALTER TABLE taxi1 RENAME COLUMN dropoff_lat TO d_lat;
ALTER TABLE taxi1 RENAME COLUMN dropoff_lon TO d_lon;
-- CONVERTING EMPY VALUES TO NULL 
UPDATE taxi1
SET
trp_sec = NULLIF(trp_sec,''),
trp_mi = NULLIF(trp_mi,''),
fare = NULLIF(fare,''),
p_lat = NULLIF(p_lat,''),
p_lon = NULLIF(p_lon,''),
d_lat = NULLIF(d_lat,''),
d_lon = NULLIF(d_lon,'');
-- Check NULL Values
SELECT
SUM(trp_sec IS NULL) AS null_trp_sec,
SUM(trp_mi IS NULL) AS null_trp_mi,
SUM(fare IS NULL) AS null_fare,
SUM(p_lat IS NULL) AS null_plat,
SUM(p_lon IS NULL) AS null_plon,
SUM(d_lat IS NULL) AS null_dlat,
SUM(d_lon IS NULL) AS null_dlon
FROM taxi1;
-- replace null with values 
UPDATE taxi1 t
JOIN (
    SELECT 
        AVG(trp_sec) AS avg_sec,
        AVG(trp_mi) AS avg_mi,
        AVG(fare) AS avg_fare
    FROM taxi1
) a
SET
t.trp_sec = IFNULL(t.trp_sec, a.avg_sec),
t.trp_mi  = IFNULL(t.trp_mi, a.avg_mi),
t.fare    = IFNULL(t.fare, a.avg_fare),
t.p_lat   = IFNULL(t.p_lat, 0),
t.p_lon   = IFNULL(t.p_lon, 0),
t.d_lat   = IFNULL(t.d_lat, 0),
t.d_lon   = IFNULL(t.d_lon, 0);

-- CHECK DUPLICATE  VALUES 
SELECT trip_id, COUNT(*)
FROM taxi1
GROUP BY trip_id
HAVING COUNT(*) > 1;
-- REMOVING  ALL THE IDS
DELETE t1
FROM taxi1 t1
JOIN taxi1 t2
ON t1.trip_id = t2.trip_id
AND t1.start_ts > t2.start_ts;
-- 
DELETE FROM taxi1
-- NEGATIVE TRP DURATION 
SELECT *
FROM  taxi1
WHERE trp_sec<0; 
-- replace them with average 
UPDATE taxi1 t
JOIN (
    SELECT AVG(trp_sec) AS avg_sec
    FROM taxi1
    WHERE trp_sec > 0
) a
SET t.trp_sec = a.avg_sec
WHERE t.trp_sec < 0;
-- Convert the Columns to DATETIME
 ALTER TABLE taxi1
MODIFY start_ts DATETIME,
MODIFY end_ts DATETIME;
-- Convert the Timestamp Format
UPDATE taxi1
SET trp_sec = TIMESTAMPDIFF(
    SECOND,
    STR_TO_DATE(start_ts,'%Y-%m-%dT%H:%i:%s.000'),
    STR_TO_DATE(end_ts,'%Y-%m-%dT%H:%i:%s.000')
)
WHERE trp_sec < 0;

-- checking fake coordinates 
SELECT *
FROM taxi1
WHERE p_lat = 0
   OR p_lon = 0
   OR d_lat = 0
   OR d_lon = 0
   OR p_lat = 999
   OR p_lon = 999
   OR d_lat = 999
   OR d_lon = 999
   OR p_lat = -999
   OR p_lon = -999
   OR d_lat = -999
   OR d_lon = -999;
-- Convert Invalid Coordinates → NULL
UPDATE taxi1
SET
p_lat = CASE 
        WHEN p_lat IN (0,999,-999) THEN NULL 
        ELSE p_lat 
       END,

p_lon = CASE 
        WHEN p_lon IN (0,999,-999) THEN NULL 
        ELSE p_lon 
       END,

d_lat = CASE 
        WHEN d_lat IN (0,999,-999) THEN NULL 
        ELSE d_lat 
       END,

d_lon = CASE 
        WHEN d_lon IN (0,999,-999) THEN NULL 
        ELSE d_lon 
       END;
-- 3️Check If Any Invalid Coordinates Remain
SELECT
SUM(p_lat IS NULL) AS null_pickup_lat,
SUM(p_lon IS NULL) AS null_pickup_lon,
SUM(d_lat IS NULL) AS null_drop_lat,
SUM(d_lon IS NULL) AS null_drop_lon
FROM taxi1;

-- Remove Trips With Missing Coordinates
DELETE FROM taxi1
WHERE p_lat IS NULL
   OR p_lon IS NULL
   OR d_lat IS NULL
   OR d_lon IS NULL;
   -- checking Negative Trip Distance
SELECT *
FROM taxi1
WHERE trp_mi < 0;
-- Fix them (replace with average distance)
UPDATE taxi1 t
JOIN (
    SELECT AVG(trp_mi) AS avg_mi
    FROM taxi1
    WHERE trp_mi > 0
) a
SET t.trp_mi = a.avg_mi
WHERE t.trp_mi < 0;
-- Extremely High Fares
SELECT *
FROM taxi1
WHERE fare > 200;
UPDATE taxi1 t
JOIN (
    SELECT AVG(fare) AS avg_fare
    FROM taxi1
    WHERE fare < 200
) a
SET t.fare = a.avg_fare
WHERE t.fare > 200;
-- Trips With Same Start and End Time
SELECT *
FROM taxi1
WHERE start_ts = end_ts;
DELETE FROM taxi1
WHERE start_ts = end_ts;
SELECT * FROM taxi1 WHERE trp_mi < 0;

SELECT * FROM taxi1 WHERE start_ts = end_ts;
-- checking taxispeeds 
SELECT *,
(trp_mi / (trp_sec / 3600)) AS speed_mph
FROM taxi1;
-- Detect Unrealistic Trips
SELECT *,
(trp_mi / (trp_sec / 3600)) AS speed_mph
FROM taxi1
WHERE (trp_mi / (trp_sec / 3600)) > 100;
-- Fix Unrealistic Speed
DELETE FROM taxi1
WHERE (trp_mi / (trp_sec / 3600)) > 100;
-- Timestamp Conversion Order

--DATA  FEATUREING QUESTION 
SELECT
trip_id,
TIMESTAMPDIFF(SECOND, start_ts, end_ts) AS trip_duration
FROM taxi1;
-- create taxi deep feature 

-- pickup hour 
SELECT
trip_id,
HOUR(start_ts) AS pickup_hour
FROM taxi1;
-- day of the week
SELECT
trip_id,
DAYNAME(start_ts) AS day_of_week
FROM taxi1;
-- Create Distance Category
SELECT
trip_id,
trp_mi,
CASE
WHEN trp_mi < 2 THEN 'Short Trip'
WHEN trp_mi < 10 THEN 'Medium Trip'
ELSE 'Long Trip'
END AS trip_type
FROM taxi1;

-- what are busiest pickup hours 
--  helps taxi companies schedule drivers 
SELECT 
HOUR(start_ts) AS pickup_hour,
COUNT(*) AS total_trips
FROM taxi1
GROUP BY pickup_hour
ORDER BY total_trips DESC;  
-- Which day of week has highest demand 
select 
dayname(start_ts) as day_of_week,
count(*) as trips
from taxi1
group by day_of_week
order by trips desc;
-- what is average trip distance 
select
avg(trp_mi) as avg_trip_distance
from taxi1;
-- what are peak demand hours 
select 
hour(start_ts) as hour,
count(*) as trip_count
from taxi1
group by hour
order by trip_count desc
limit 5; 
-- what is average fare trip 
select
avg(fare) as avg_fare
from taxi1;
 -- which hour generates highest revenue 
 select 
 hour(start_ts) as hour,
 sum(fare) as total_revenue
 from taxi1
 group by hour
 order by total_revenue desc;
 -- most common pickup and drop location 
 select 
d_lat, d_lon,
COUNT(*) AS trips
FROM taxi1
GROUP BY d_lat, d_lon
ORDER BY trips DESC
LIMIT 10;
-- least commom
SELECT 
d_lat, d_lon,
COUNT(*) AS trips
FROM taxi1
GROUP BY d_lat, d_lon
ORDER BY trips DESC
LIMIT 10;
-- Customer Behavior
-- Short vs medium vs long trips
SELECT
CASE
WHEN trp_mi < 2 THEN 'Short'
WHEN trp_mi < 10 THEN 'Medium'
ELSE 'Long'
END AS trip_category,
COUNT(*) AS trips
FROM taxi1
GROUP BY trip_category;
-- Average fare by trip distance category
SELECT
CASE
WHEN trp_mi < 2 THEN 'Short'
WHEN trp_mi < 10 THEN 'Medium'
ELSE 'Long'
END AS trip_type,
AVG(fare) AS avg_fare
FROM taxi1
GROUP BY trip_type;
-- Total trips per day
SELECT
DATE(start_ts) AS trip_date,
COUNT(*) AS trips
FROM taxi1
GROUP BY trip_date
ORDER BY trip_date;
-- Find Top 3 Busiest Hours Each Day
WITH hourly_trips AS (
SELECT
DATE(start_ts) AS trip_day,
HOUR(start_ts) AS trip_hour,
COUNT(*) AS trip_count
FROM taxi1
GROUP BY trip_day, trip_hour
)

SELECT *
FROM (
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY trip_day
ORDER BY trip_count DESC
) AS rank_hour
FROM hourly_trips
) t
WHERE rank_hour <= 3;
-- Find Revenue Contribution by Each Hour
SELECT
HOUR(start_ts) AS hour,
SUM(fare) AS revenue,
SUM(fare) / SUM(SUM(fare)) OVER() * 100 AS revenue_percent
FROM taxi1
GROUP BY hour
ORDER BY revenue DESC;
-- Find Trips Above 95th Fare Percentile
SELECT *
FROM (
SELECT
trip_id,
fare,
PERCENT_RANK() OVER (ORDER BY fare) AS fare_percentile
FROM taxi1
) t
WHERE fare_percentile >= 0.95;
-- Detect Fare Spikes Compared to Hourly Average
SELECT *
FROM (
SELECT
trip_id,
fare,
HOUR(start_ts) AS hour,
AVG(fare) OVER (PARTITION BY HOUR(start_ts)) AS avg_hour_fare
FROM taxi1
) t
WHERE fare > avg_hour_fare * 2;
-- Find Top 5 Longest Trips Each Day
SELECT *
FROM (
SELECT
trip_id,
DATE(start_ts) AS trip_day,
trp_sec,
ROW_NUMBER() OVER(
PARTITION BY DATE(start_ts)
ORDER BY trp_sec DESC
) AS rank_trip
FROM taxi1
) t
WHERE rank_trip <= 5;
-- Moving Average Fare
SELECT
trip_id,
fare,
AVG(fare) OVER(
ORDER BY start_ts
ROWS BETWEEN 9 PRECEDING AND CURRENT ROW
) AS moving_avg_fare
FROM taxi1; 
-- Calculate Fare Change Between Consecutive Trips
SELECT
trip_id,
fare,
LAG(fare) OVER (ORDER BY start_ts) AS previous_fare,
fare - LAG(fare) OVER (ORDER BY start_ts) AS fare_change
FROM taxi1;
-- Calculate Rolling 1-Hour Trip Volume
SELECT
start_ts,
COUNT(*) OVER (
ORDER BY start_ts
RANGE BETWEEN INTERVAL 1 HOUR PRECEDING AND CURRENT ROW
) AS trips_last_hour
FROM taxi1;
-- Find top 5% longest trips 
SELECT *
FROM (
SELECT
trip_id,
trp_sec,
PERCENT_RANK() OVER (ORDER BY trp_sec) AS duration_percentile
FROM taxi1
) t
WHERE duration_percentile >= 0.95;
-- I analyzed a taxi trip dataset using SQL to understand demand patterns, revenue trends, and customer travel behavior.First, I cleaned the dataset by fixing missing values, removing duplicates, correcting negative durations, and eliminating invalid GPS coordinates.

-- Then I engineered new features such as trip duration, pickup hour, day of week, and trip distance categories.

 
-- The analysis provided insights that could help taxi companies optimize driver allocation, improve pricing strategies, and increase operational efficiency.
SHOW DATABASES;

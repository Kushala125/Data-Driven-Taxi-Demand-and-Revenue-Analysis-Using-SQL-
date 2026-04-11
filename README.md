## Project README: Urban Mobility & Revenue Dynamics
## 1. The Pulse of the City: A Storytelling Introduction
Imagine a city that breathes in a rhythmic cycle of movement. Every minute, hundreds of vehicles traverse the asphalt arteries of the urban landscape. For the city planner, these are numbers; for the driver, a livelihood; but for the data scientist, they are a story.

This project began with a simple question: How does a city move? By diving into thousands of raw trip records, we sought to uncover the hidden patterns behind the chaos—why demand spikes at 6 PM, where the most lucrative "honey pots" are located, and how traffic congestion physically slows the pulse of the city during the afternoon rush. This isn't just an analysis of distances; it is a digital reconstruction of urban life through the lens of mobility.

## 2. The Data Architecture (SQL)
Before analysis could begin, the raw data required a rigorous "cleaning odyssey" to transform it from a chaotic collection of entries into a high-performance analytical dataset.
The foundation of this project lies in a robust SQL-based ETL (Extract, Transform, Load) process. Before any visualization could occur, the dataset underwent a multi-stage refinement to ensure data integrity and high-performance querying.

1. Schema Optimization & Standardization
The raw dataset contained cumbersome column names and inconsistent formatting. The first step was to refactor the schema for developer efficiency and readability.

SQL
-- Standardizing headers for cleaner query syntax
ALTER TABLE taxi1 RENAME COLUMN trip_start_timestamp TO start_ts;
ALTER TABLE taxi1 RENAME COLUMN trip_end_timestamp TO end_ts;
ALTER TABLE taxi1 RENAME COLUMN trip_seconds TO trp_sec;
ALTER TABLE taxi1 RENAME COLUMN trip_miles TO trp_mi;

-- Normalizing empty strings to NULL to maintain mathematical integrity
UPDATE taxi1
SET 
    trp_sec = NULLIF(trp_sec, ''),
    trp_mi  = NULLIF(trp_mi, ''),
    fare    = NULLIF(fare, '');
2. Advanced Data Imputation
To prevent bias in our averages, we moved beyond simple deletion of missing values. We implemented a strategy of Mean Imputation, filling gaps in critical metrics with the dataset average to preserve the overall distribution.

SQL
UPDATE taxi1 t
JOIN (SELECT AVG(trp_sec) AS avg_sec, AVG(trp_mi) AS avg_mi FROM taxi1) a
SET t.trp_sec = IFNULL(t.trp_sec, a.avg_sec),
    t.trp_mi  = IFNULL(t.trp_mi, a.avg_mi);
3. Temporal Feature Engineering
To enable time-series analysis, we extracted granular time features. This allowed us to shift from viewing "trips" to viewing "trends."

SQL
-- Generating time-based dimensions for rush hour analysis
SELECT 
    trip_id,
    start_ts,
    HOUR(start_ts) AS pickup_hour,
    DAYNAME(start_ts) AS day_of_week,
    CASE 
        WHEN DAYOFWEEK(start_ts) IN (1, 7) THEN 'Weekend'
        ELSE 'Weekday' 
    END AS day_type
FROM taxi1;
4. Advanced Window Functions (The Insights Layer)
The most sophisticated part of the SQL section involves Analytical Window Functions. We utilized these to identify outliers and perform "Moving Average" smoothing to see past the noise of individual high-fare trips.

Percentile Ranking: We identified the top 5% of trips by duration to isolate long-haul outliers.

Moving Averages: A 10-trip rolling average for fares was calculated to visualize revenue stability over time.

SQL
-- Calculating the Top 5% Longest Trips
SELECT * FROM (
    SELECT 
        trip_id, 
        trp_sec,
        PERCENT_RANK() OVER (ORDER BY trp_sec) AS duration_percentile
    FROM taxi1
) t WHERE duration_percentile >= 0.95;

-- 10-Trip Rolling Revenue Average
SELECT 
    trip_id, 
    fare,
    AVG(fare) OVER(ORDER BY start_ts ROWS BETWEEN 9 PRECEDING AND CURRENT ROW) AS moving_avg_fare
FROM taxi1;
5. Data Integrity Audit
Final validation checks were performed to ensure no "impossible" data points (e.g., negative trip durations or miles) remained in the production-ready table.

SQL
-- Removing physical impossibilities
DELETE FROM taxi1 
WHERE trp_sec <= 0 OR trp_mi <= 0 OR fare < 0;

## 3. Behavioral Deep Dive (Python)
With a clean foundation, Python was employed to perform high-level statistical analysis and uncover the "why" behind the data.

Statistical Insights

The Efficiency Inverse: Analysis revealed that short-haul trips are actually more lucrative on a per-mile basis ($6.46/mile) compared to long-distance trips ($2.59/mile).


Revenue Concentration: The "Top 10% Rule" was confirmed; the highest-fare trips generate approximately 19.4% of the total revenue.


The Congestion Valley: By grouping by pickup_hour, we identified a clear dip in average speeds during the 4 PM rush hour (~20.18 mph) compared to the late-night free-flow (~26.23 mph).

Python
# Analyzing Revenue Concentration
top10_percentile = df["fare"].quantile(0.90)
revenue_contribution = df[df["fare"] >= top10_percentile]["fare"].sum() / df["fare"].sum() * 100
print(f"Top 10% trips contribute: {revenue_contribution:.2f}% of revenue")

# Calculating Efficiency per Mile
df["fare_per_mile"] = df["fare"] / df["trp_mi"]
avg_efficiency = df.groupby("trip_category")["fare_per_mile"].mean()
## 4. Challenged Insights: Breaking the Norms

The 6 PM Paradox: While demand peaks sharply at 6 PM due to commutes, it collapses rapidly after 8 PM. This suggests that the city’s taxi ecosystem is a "commuter hub" rather than a late-night service.


Speed vs. Distance: Interestingly, the average speed for "Long" trips (33.8 mph) is more than five times faster than "Short" trips (6.3 mph), likely because long-distance trips utilize highway corridors while short trips are trapped in urban street congestion.

## 5. Conclusion
This project demonstrates that urban mobility is far from random. By combining the structural power of SQL with the analytical flexibility of Python, we transformed 7,400 raw records into a vivid narrative of city life. We discovered that the most valuable trips for a driver’s efficiency are short bursts, while the most critical trips for the ecosystem’s total revenue are the long-distance outliers. These insights provide a roadmap for fleet optimization and urban infrastructure planning, proving that in the world of data, every trip has a destination beyond the map.

## Project README: Urban Mobility & Revenue Dynamics
## 1. The Pulse of the City: A Storytelling Introduction
Imagine a city that breathes in a rhythmic cycle of movement. Every minute, hundreds of vehicles traverse the asphalt arteries of the urban landscape. For the city planner, these are numbers; for the driver, a livelihood; but for the data scientist, they are a story.

This project began with a simple question: How does a city move? By diving into thousands of raw trip records, we sought to uncover the hidden patterns behind the chaos—why demand spikes at 6 PM, where the most lucrative "honey pots" are located, and how traffic congestion physically slows the pulse of the city during the afternoon rush. This isn't just an analysis of distances; it is a digital reconstruction of urban life through the lens of mobility.

## 2. The Data Architecture (SQL)
Before analysis could begin, the raw data required a rigorous "cleaning odyssey" to transform it from a chaotic collection of entries into a high-performance analytical dataset.

Data Cleaning & Standardization
We began by standardizing the schema and addressing integrity issues such as missing values and duplicates:


Header Refactoring: Renamed columns to intuitive shorthands (e.g., trip_start_timestamp to start_ts) for cleaner query logic.


The "Void" Conversion: Converted empty strings to NULL across all critical metrics like trp_sec, trp_mi, and fare.


Imputation Strategy: Missing numerical values were filled with the dataset's average to maintain statistical consistency, while missing geographic coordinates were defaulted to 0.


Duplicate Purging: Used self-joins to identify and delete redundant trip_id entries, ensuring a unique record for every journey.

SQL
-- Example: Cleaning and Standardizing Headers
ALTER TABLE taxi1 RENAME COLUMN trip_start_timestamp TO start_ts;
ALTER TABLE taxi1 RENAME COLUMN trip_miles TO trp_mi;

-- Example: Handling NULL values with Mean Imputation
UPDATE taxi1 t
JOIN (SELECT AVG(trp_sec) AS avg_sec, AVG(trp_mi) AS avg_mi FROM taxi1) a
SET t.trp_sec = IFNULL(t.trp_sec, a.avg_sec),
    t.trp_mi  = IFNULL(t.trp_mi, a.avg_mi);
Advanced Feature Engineering
SQL was further used to generate complex temporal and performance features:


Window Functions: Applied ROW_NUMBER() and PERCENT_RANK() to identify the top 5% of longest trips and daily duration leaders.


Moving Averages: Calculated a 10-trip rolling average for fares to smooth out volatility and identify long-term revenue trends.

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

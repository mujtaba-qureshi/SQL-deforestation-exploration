Creating the VIEW "forestation"
CREATE VIEW forestation AS
SELECT f.country_code c_code, f.country_name country, r.region, f.year yr, f.forest_area_sqkm forest_area, l.total_area_sq_mi*2.59 total_area,
r.income_group, f.forest_area_sqkm/(total_area_sq_mi*2.59)*100 percent_forest
FROM forest_area f
JOIN land_area l
ON f.country_code = l.country_code AND f.year = l.year
JOIN regions r
ON l.country_code = r.country_code
ORDER BY 1,4

CREATE VIEW forestation_2 AS
SELECT *
FROM forestation
WHERE percent_forest IS NOT NULL

//Global Situtaion//

(a) What was the total forest area (in sq km) of the world in 1990? and
(b) What was the total forest area (in sq km) of the world in 2016?
SELECT region, yr, forest_area, total_area, percent_forest
FROM forestation_2
WHERE region LIKE 'Worl%'
AND (yr = '1990' OR yr = '2016')


(c) What was the change (in sq km) in the forest area of the world from 1990 to 2016? and
WITH t1 AS
  (SELECT region, yr, forest_area, total_area, percent_forest
FROM forestation_2
WHERE region LIKE 'Worl%'
AND (yr = '1990' OR yr = '2016'))

SELECT MAX(forest_area) - MIN(forest_area) change_forest_area
FROM t1

(d) What was the percent change in forest area of the world between 1990 and 2016?
WITH t1 AS (SELECT *, LAG(forest_area) OVER(PARTITION BY country ORDER BY yr) AS forest_area_1990
FROM forestation_2
WHERE yr = '1990' OR yr = '2016'
ORDER BY 1,4),

t2 AS (SELECT *, forest_area - forest_area_1990 AS area_change,
    (forest_area - forest_area_1990)/forest_area_1990*100 AS percent_change
FROM t1
WHERE forest_area_1990 IS NOT NULL)

SELECT country, percent_change
FROM t2
WHERE country LIKE 'Worl%'

(e)If you compare the amount of forest area lost between 1990 and 2016,
to which countrys total area in 2016 is it closest to
SELECT country, total_area
FROM forestation_2
WHERE total_area < 1324449 AND yr = '2016'
ORDER BY 2 DESC
LIMIT 1

//Regional Situation//

Create a table that shows the Regions and their percent forest area
(sum of forest area divided by sum of land area) in 1990 and 2016.
SELECT region, yr, SUM(forest_area)/SUM(total_area)*100 regional_forest_cover
FROM forestation_2
WHERE (yr ='1990' OR yr = '2016')
GROUP BY 1,2
ORDER BY 1,2

(a) What was the percent forest of the entire world in 2016?
Which region had the HIGHEST percent forest in 2016, and which had the LOWEST, to 2 decimal places?
WITH t1 AS (
SELECT region, yr, SUM(forest_area)/SUM(total_area)*100 regional_forest_cover
FROM forestation_2
GROUP BY 1,2
ORDER BY 1,2)

SELECT region, yr, regional_forest_cover
FROM t1
WHERE yr = '2016'
ORDER BY 3 DESC

(b)What was the percent forest of the entire world in 1990?
Which region had the HIGHEST percent forest in 1990, and which had the LOWEST, to 2 decimal places?
WITH t1 AS (
SELECT region, yr, SUM(forest_area)/SUM(total_area)*100 regional_forest_cover
FROM forestation_2
GROUP BY 1,2
ORDER BY 1,2)

SELECT region, yr, regional_forest_cover
FROM t1
WHERE yr = '1990'
ORDER BY 3 DESC

(c)Based on the table you created, which regions of the world DECREASED in
forest area from 1990 to 2016?
WITH t1 AS (
SELECT region, yr, SUM(forest_area)/SUM(total_area)*100 regional_forest_cover
FROM forestation_2
WHERE yr = '1990' OR yr = '2016'
GROUP BY 1,2
ORDER BY 1,2),

t2 AS (SELECT region, yr, regional_forest_cover,
LAG(regional_forest_cover) OVER(PARTITION BY region ORDER BY yr)
FROM t1),

t3 AS (SELECT *,
CASE WHEN (regional_forest_cover-lag) < 0 THEN 'DECREASE' END AS forest_cover
FROM t2)

SELECT *
FROM t3
WHERE forest_cover IS NOT NULL

##OR##

WITH t1 AS (
SELECT region, yr, SUM(forest_area)/SUM(total_area)*100 regional_forest_cover
FROM forestation_2
GROUP BY 1,2
ORDER BY 1,2)

SELECT *
FROM t1 a
JOIN t1 b
ON a.region = b.region
WHERE (a.yr = '1990' AND b.yr = '2016')
AND (a.regional_forest_cover > b.regional_forest_cover)

//Country-Wise Situation

(a)Which 5 countries saw the largest amount decrease in
forest area from 1990 to 2016? What was the difference in forest area for each?
WITH t1 AS
(SELECT country, region, yr, forest_area forest_cover_area
FROM forestation_2
ORDER BY 1,3),

t2 AS
(SELECT *, LAG(forest_cover_area) OVER(PARTITION BY country ORDER BY yr),
forest_cover_area - LAG(forest_cover_area) OVER(PARTITION BY country ORDER BY yr) AS diff_area
FROM t1)

SELECT country, region, SUM(diff_area)
FROM t2
WHERE country NOT LIKE 'World'
GROUP BY 1,2
ORDER BY 3
LIMIT 5

(b)Which 5 countries saw the largest percent decrease in
WITH t1 AS (SELECT *, LAG(forest_area) OVER(PARTITION BY country ORDER BY yr) AS forest_area_1990
FROM forestation_2
WHERE yr = '1990' OR yr = '2016'
ORDER BY 1,4),

t2 AS (SELECT *, forest_area - forest_area_1990 AS area_change,
    (forest_area - forest_area_1990)/forest_area_1990*100 AS percent_change
FROM t1
WHERE forest_area_1990 IS NOT NULL)

SELECT country, region, percent_change
FROM t2
WHERE country NOT LIKE 'World'
ORDER BY 3
LIMIT 5

(c)If countries were grouped by percent forestation in quartiles,
which group had the most countries in it in 2016?
WITH t1 AS (SELECT *, CASE
    WHEN (percent_forest <= 25) THEN 1
    WHEN (percent_forest > 25 AND percent_forest <= 50) THEN 2
    WHEN (percent_forest > 50 AND percent_forest <= 75) THEN 3
    WHEN (percent_forest > 75 AND percent_forest <= 100) THEN 4 END AS quartile
FROM forestation_2)

SELECT quartile, COUNT(*)
FROM t1
WHERE yr = '2016' AND country NOT LIKE 'World'
GROUP BY 1
ORDER BY 1

(d) List all of the countries that were in the 4th quartile (percent forest > 75%) in 2016
WITH t1 AS (SELECT *, CASE
    WHEN (percent_forest/(SELECT MAX(percent_forest)
      FROM forestation_2
      WHERE country NOT LIKE 'Worl%') <= 0.25) THEN 1
    WHEN (percent_forest/(SELECT MAX(percent_forest)
      FROM forestation_2
      WHERE country NOT LIKE 'Worl%') > 0.25 AND percent_forest/(SELECT MAX(percent_forest)
      FROM forestation_2
      WHERE country NOT LIKE 'Worl%') <= 0.5) THEN 2
    WHEN (percent_forest/(SELECT MAX(percent_forest)
      FROM forestation_2
      WHERE country NOT LIKE 'Worl%'
      LIMIT 10) > 0.5 AND percent_forest/(SELECT MAX(percent_forest)
      FROM forestation_2
      WHERE country NOT LIKE 'Worl%') <= 0.75) THEN 3
    WHEN (percent_forest/(SELECT MAX(percent_forest)
      FROM forestation_2
      WHERE country NOT LIKE 'Worl%'
      LIMIT 10) > 0.75 AND percent_forest/(SELECT MAX(percent_forest)
      FROM forestation_2
      WHERE country NOT LIKE 'Worl%') <= 1) THEN 4 END AS quartile
FROM forestation_2),

t2 AS (SELECT quartile, COUNT(*)
FROM t1
WHERE yr = '2016' AND country NOT LIKE 'World'
GROUP BY 1
ORDER BY 1)

SELECT country, region, percent_forest
FROM t1
WHERE quartile = 4 AND yr = '2016'
ORDER BY 3 DESC


(e)How many countries had a percent forestation higher than the United States in 2016?
SELECT COUNT(*)
FROM forestation_2
WHERE percent_forest > (SELECT percent_forest
	FROM forestation_2
	WHERE country LIKE 'United States%' AND yr = '2016')
AND yr = '2016'


// Recommendations
WITH t1 AS (SELECT *, LAG(forest_area) OVER(PARTITION BY country ORDER BY yr) AS forest_area_1990
FROM forestation_2
WHERE yr = '1990' OR yr = '2016'
ORDER BY 1,4),

t2 AS (SELECT *, forest_area - forest_area_1990 AS area_change,
    (forest_area - forest_area_1990)/forest_area_1990*100 AS percent_change
FROM t1
WHERE forest_area_1990 IS NOT NULL)

SELECT income_group, AVG(percent_change) AVG_CHANGE, AVG(percent_forest) AVG_FOREST
FROM t2
WHERE income_group NOT LIKE NULL
GROUP BY 1
ORDER BY 2,3


WITH t1 AS (SELECT *, LAG(forest_area) OVER(PARTITION BY country ORDER BY yr) AS forest_area_1990
FROM forestation_2
WHERE yr = '1990' OR yr = '2016'
ORDER BY 1,4),

t2 AS (SELECT *, forest_area - forest_area_1990 AS area_change,
    (forest_area - forest_area_1990)/forest_area_1990*100 AS percent_change
FROM t1
WHERE forest_area_1990 IS NOT NULL)

SELECT region, income_group, COUNT(*)
FROM t2
WHERE income_group NOT LIKE 'NULL' AND region LIKE 'Sub%'
GROUP BY 1, 2
ORDER BY 3 DESC

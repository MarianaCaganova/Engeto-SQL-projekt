/*Pohlad - počasie v roku 2020 a 2021 a zmena dátového typu teplota a nárazový vietor na int a pretypovanie dátumu z datetime na date*/
CREATE VIEW v_MC_weather_year AS
SELECT
	time,
	rain,
	city,
	CAST (w.date AS date) AS date,
	CAST(REPLACE(w.temp, ' °c', '') AS int) AS temp_num,
	CAST(REPLACE(w.gust, ' km/h', '') AS int) AS gust_num
FROM
	weather w
WHERE
	date >= '2020-01-01';

/*Pohlad - úprava názvov miest a štátov pre lepšie párovanie a medzivýpočty pre počasie*/
CREATE VIEW v_MC_weather AS
WITH countries_city AS (
SELECT
	CASE
		WHEN country = 'Myanmar' THEN 'Burma'
		WHEN country = 'Cape Verde' THEN 'Cabo Verde'
		WHEN country = 'Congo' THEN 'Congo (Brazzaville)'
		WHEN country = 'The Democratic Republic of Congo' THEN 'Congo (Kinshasa)'
		WHEN country = 'Ivory Coast' THEN 'Cote d''Ivoire'
		WHEN country = 'Czech Republic' THEN 'Czechia'
		WHEN country = 'Swaziland' THEN 'Eswatini'
		WHEN country = 'Fiji Islands' THEN 'Fiji'
		WHEN country = 'Holy See (Vatican City State)' THEN 'Holy See'
		WHEN country = 'South Korea' THEN 'Korea, South'
		WHEN country = 'Libyan Arab Jamahiriya' THEN 'Libya'
		WHEN country = 'Micronesia, Federated States of' THEN 'Micronesia'
		WHEN country = 'Russian Federation' THEN 'Russia'
		WHEN country = 'United States' THEN 'US'
		ELSE country
	END AS country ,
	CASE
		WHEN capital_city = 'Athenai' THEN 'Athens'
		WHEN capital_city = 'Bruxelles [Brussel]' THEN 'Brussels'
		WHEN capital_city = 'Bucuresti' THEN 'Bucharest'
		WHEN capital_city = 'Helsinki [Helsingfors]' THEN 'Helsinki'
		WHEN capital_city = 'Kyiv' THEN 'Kiev'
		WHEN capital_city = 'Lisboa' THEN 'Lisbon'
		WHEN capital_city = 'Luxembourg [Luxemburg/L' THEN 'Luxembourg'
		WHEN capital_city = 'Praha' THEN 'Prague'
		WHEN capital_city = 'Roma' THEN 'Rome'
		WHEN capital_city = 'Wien' THEN 'Vienna'
		WHEN capital_city = 'Warszawa' THEN 'Warsaw'
		ELSE capital_city
	END AS capital_city
FROM
	countries c 
)
SELECT 
	cc.country,
	w.date,
	cc.capital_city,
	w.max_gust_day,
	CASE WHEN w_rain.rainy_hours IS NULL THEN 0 ELSE w_rain.rainy_hours END AS rainy_hours,
	w_temp.avg_temp_day
FROM
	countries_city cc
LEFT JOIN (
	SELECT
		city,
		date,
		MAX(gust_num) AS max_gust_day
	FROM
		v_MC_weather_year w
	GROUP BY
		city,
		date
) w ON
	cc.capital_city = w.city
LEFT JOIN (
	SELECT
		w.city,
		w.date,
		count(time) AS 'rainy_hours'
	FROM
		v_MC_weather_year w
	WHERE
		w.rain != '0.0 mm'
	GROUP BY
		w.city,
		w.date
) w_rain ON
	cc.capital_city = w_rain.city AND w.date = w_rain.date
LEFT JOIN (
	SELECT
		city,
		date,
		ROUND(avg(temp_num), 2) AS avg_temp_day
	FROM
		v_MC_weather_year w
	WHERE
		time >= '06:00'
		AND time <= '18:00'
	GROUP BY
		city,
		w.date
)  w_temp ON 
	cc.capital_city = w_temp.city AND w.date = w_temp.date;



/*Pohlad - podiely náboženstiev v jednotlivých krajinách pre rok 2020*/
CREATE VIEW v_MC_rel_per_country AS
WITH rel_chris AS (
	SELECT
		country,
		population
	FROM
		religions r
	WHERE
		religion = 'Christianity'
		AND `year` = 2020
	ORDER BY
		country
),
rel_islam AS (
	SELECT
		country,
		population
	FROM
		religions r
	WHERE
		religion = 'Islam'
		AND `year` = 2020
	ORDER BY
		country
),
rel_hindi AS (
	SELECT
		country,
		population
	FROM
		religions r
	WHERE
		religion = 'Hinduism'
		AND `year` = 2020
	ORDER BY
		country
),
rel_budhi AS (
	SELECT
		country,
		population
	FROM
		religions r
	WHERE
		religion = 'Buddhism'
		AND `year` = 2020
	ORDER BY
		country
),
rel_juda AS (
	SELECT
		country,
		population
	FROM
		religions r
	WHERE
		religion = 'Judaism'
		AND `year` = 2020
	ORDER BY
		country
),
rel_folk AS (
	SELECT
		country,
		population
	FROM
		religions r
	WHERE
		religion = 'Folk Religions'
		AND `year` = 2020
	ORDER BY
		country
),
rel_oth AS (
	SELECT
		country,
		population
	FROM
		religions r
	WHERE
		religion = 'Other Religions'
		AND `year` = 2020
	ORDER BY
		country
),
rel_unaffil AS (
	SELECT
		country,
		population
	FROM
		religions r
	WHERE
		religion = 'Unaffiliated Religions'
		AND `year` = 2020
	ORDER BY
		country
)
SELECT
	rel_2020.country,
	ROUND((rc.population / total_population_2020) * 100, 2) AS Christianity_proc,
	ROUND((ri.population / total_population_2020) * 100, 2) AS Islam_proc,
	ROUND((rh.population / total_population_2020) * 100, 2) AS Hinduism_proc,
	ROUND((rb.population / total_population_2020) * 100, 2) AS Buddhism_proc,
	ROUND((rj.population / total_population_2020) * 100, 2) AS Judaism_proc,
	ROUND((rf.population / total_population_2020) * 100, 2) AS Folk_rel_proc,
	ROUND((ro.population / total_population_2020) * 100, 2) AS Other_rel_proc,
	ROUND((ru.population / total_population_2020) * 100, 2) AS Unaffiliated_rel_proc
FROM
	(
	SELECT
		r.country ,
		r.year,
		sum(r.population) AS total_population_2020
	FROM
		religions r
	WHERE
		r.year = 2020
	GROUP BY
		r.country) rel_2020
LEFT JOIN rel_chris rc ON
	rc.country = rel_2020.country
LEFT JOIN rel_islam ri ON
	ri.country = rel_2020.country
LEFT JOIN rel_hindi rh ON
	rh.country = rel_2020.country
LEFT JOIN rel_budhi rb ON
	rb.country = rel_2020.country
LEFT JOIN rel_juda rj ON
	rj.country = rel_2020.country
LEFT JOIN rel_folk rf ON
	rf.country = rel_2020.country
LEFT JOIN rel_oth ro ON
	ro.country = rel_2020.country
LEFT JOIN rel_unaffil ru ON
	ru.country = rel_2020.country;


/*Pohlad - rozdiel v life expectancy v roku 2015 a 1965*/
CREATE VIEW v_MC_life_expectancy_diff AS
WITH life_expectancy_2015 AS (
	SELECT
		*
	FROM
		life_expectancy le
	WHERE
		`year` = 2015
),
life_expectancy_1965 AS (
	SELECT
		*
	FROM
		life_expectancy le
	WHERE
		`year` = 1965
)
SELECT
	c.country,
	le2015.life_expectancy - le1965.life_expectancy AS diff
FROM
	countries c
LEFT JOIN life_expectancy_2015 le2015 ON
	c.country = le2015.country
LEFT JOIN life_expectancy_1965 le1965 ON
	c.country = le1965.country;


/*Finálna tabuľka s pridanými medzivýpočtami ako je pridanie ročného obdobia, pracovného týždňa a zmena názvov krajín*/
CREATE TABLE t_mariana_caganova_projekt_SQL_final AS
WITH covid19_basic_diff_date AS (
	SELECT
		country,
		confirmed,
		date,  
		CASE
			WHEN WEEKDAY(date) IN (5, 6) THEN 1
			ELSE 0
		END AS WEEKDAY,
		CASE
			WHEN MONTH(date) IN (12, 1, 2) THEN 0
			WHEN MONTH(date) IN (3, 4, 5) THEN 1
			WHEN MONTH(date) IN (6, 7, 8) THEN 2
			WHEN MONTH(date) IN (9, 10, 11) THEN 3
		END AS SEASON
	FROM
		covid19_basic_differences cbd
),
covid19_tests_updated AS (
	SELECT
		ct.tests_performed,
		ct.`date`,
		CASE
			WHEN country = 'Myanmar' THEN 'Burma'
			WHEN country = 'Democratic Republic of Congo' THEN 'Congo (Kinshasa)'
			WHEN country = 'Czech Republic' THEN 'Czechia'
			WHEN country = 'South Korea' THEN 'Korea, South'
			WHEN country = 'Macedonia' THEN 'North Macedonia'
			WHEN country = 'Taiwan' THEN 'Taiwan*'
			WHEN country = 'United States' THEN 'US'
		ELSE country
		END AS country
	FROM covid19_tests ct
),
economies_2020 AS (
	SELECT
		CASE
			WHEN country = 'Bahamas, The' THEN 'Bahamas'
			WHEN country = 'Brunei Darussalam' THEN 'Brunei'
			WHEN country = 'Myanmar' THEN 'Burma'
			WHEN country = 'Congo' THEN 'Congo (Brazzaville)'
			WHEN country = 'The Democratic Republic of Congo' THEN 'Congo (Kinshasa)'
			WHEN country = 'Ivory Coast' THEN 'Cote d''Ivoire'
			WHEN country = 'Czech Republic' THEN 'Czechia'
			WHEN country = 'Swaziland' THEN 'Eswatini'
			WHEN country = 'South Korea' THEN 'Korea, South'
			WHEN country = 'Micronesia, Fed. Sts.' THEN 'Micronesia'
			WHEN country = 'Russian Federation' THEN 'Russia'
			WHEN country = 'St. Kitts and Nevis' THEN 'Saint Kitts and Nevis'
			WHEN country = 'St. Lucia' THEN 'Saint Lucia'
			WHEN country = 'St. Vincent and the Grenadines' THEN 'Saint Vincent and the Grenadines'
			WHEN country = 'United States' THEN 'US'
			ELSE country
		END AS country,
		YEAR,
		gdp,
		gini
	FROM
		economies e
	WHERE
		e.`year` = 2020
),
economies_2019_mortality AS (
	SELECT
		CASE
			WHEN country = 'Bahamas, The' THEN 'Bahamas'
			WHEN country = 'Brunei Darussalam' THEN 'Brunei'
			WHEN country = 'Myanmar' THEN 'Burma'
			WHEN country = 'Congo' THEN 'Congo (Brazzaville)'
			WHEN country = 'The Democratic Republic of Congo' THEN 'Congo (Kinshasa)'
			WHEN country = 'Ivory Coast' THEN 'Cote d''Ivoire'
			WHEN country = 'Czech Republic' THEN 'Czechia'
			WHEN country = 'Swaziland' THEN 'Eswatini'
			WHEN country = 'South Korea' THEN 'Korea, South'
			WHEN country = 'Micronesia, Fed. Sts.' THEN 'Micronesia'
			WHEN country = 'Russian Federation' THEN 'Russia'
			WHEN country = 'St. Kitts and Nevis' THEN 'Saint Kitts and Nevis'
			WHEN country = 'St. Lucia' THEN 'Saint Lucia'
			WHEN country = 'St. Vincent and the Grenadines' THEN 'Saint Vincent and the Grenadines'
			WHEN country = 'United States' THEN 'US'
			ELSE country
		END AS country,
		e.mortaliy_under5
	FROM
		economies e
	WHERE
		e.`year` = 2019
),
v_MC_rel_per_country_updated AS (
	SELECT
		vrc.Christianity_proc,
		vrc.Islam_proc,
		vrc.Hinduism_proc,
		vrc.Buddhism_proc,
		vrc.Judaism_proc,
		vrc.Folk_rel_proc,
		vrc.Other_rel_proc,
		vrc.Unaffiliated_rel_proc,
		CASE 
			WHEN country = 'Myanmar' THEN 'Burma'
			WHEN country = 'Cape Verde' THEN 'Cabo Verde'
			WHEN country = 'Congo' THEN 'Congo (Brazzaville)'
			WHEN country = 'The Democratic Republic of Congo' THEN 'Congo (Kinshasa)'
			WHEN country = 'Ivory Coast' THEN 'Cote d''Ivoire'
			WHEN country = 'Czech Republic' THEN 'Czechia'
			WHEN country = 'Swaziland' THEN 'Eswatini'
			WHEN country = 'South Korea' THEN 'Korea, South'
			WHEN country = 'Federated States of Micronesia' THEN 'Micronesia'
			WHEN country = 'Russian Federation' THEN 'Russia'
			WHEN country = 'St. Kitts and Nevis' THEN 'Saint Kitts and Nevis'
			WHEN country = 'St. Lucia' THEN 'Saint Lucia'
			WHEN country = 'St. Vincent and the Grenadines' THEN 'Saint Vincent and the Grenadines'
			WHEN country = 'Taiwan' THEN 'Taiwan*'
			WHEN country = 'United States' THEN 'US'
			ELSE country
		END AS country
	FROM
		v_MC_rel_per_country vrc
),
v_MC_life_expectancy_diff_updated AS (
	SELECT
		vled.diff,
		CASE
			WHEN country = 'Myanmar' THEN 'Burma'
			WHEN country = 'Cape Verde' THEN 'Cabo Verde'
			WHEN country = 'Congo' THEN 'Congo (Brazzaville)'
			WHEN country = 'The Democratic Republic of Congo' THEN 'Congo (Kinshasa)'
			WHEN country = 'Ivory Coast' THEN 'Cote d''Ivoire'
			WHEN country = 'Czech Republic' THEN 'Czechia'
			WHEN country = 'Swaziland' THEN 'Eswatini'
			WHEN country = 'Vatican' THEN 'Holy See'
			WHEN country = 'South Korea' THEN 'Korea, South'
			WHEN country = 'Micronesia' THEN 'Micronesia'
			WHEN country = 'Russian Federation' THEN 'Russia'
			WHEN country = 'Taiwan' THEN 'Taiwan*'
			WHEN country = 'United States' THEN 'US'
		ELSE country
		END AS country
	FROM
		v_MC_life_expectancy_diff vled
),
countries_updated AS (
	SELECT
	c.population_density,
	c.median_age_2018,
	c.capital_city,
	CASE
		WHEN country = 'Myanmar' THEN 'Burma'
		WHEN country = 'Cape Verde' THEN 'Cabo Verde'
		WHEN country = 'Congo' THEN 'Congo (Brazzaville)'
		WHEN country = 'The Democratic Republic of Congo' THEN 'Congo (Kinshasa)'
		WHEN country = 'Ivory Coast' THEN 'Cote d''Ivoire'
		WHEN country = 'Czech Republic' THEN 'Czechia'
		WHEN country = 'Swaziland' THEN 'Eswatini'
		WHEN country = 'Fiji Islands' THEN 'Fiji'
		WHEN country = 'Holy See (Vatican City State)' THEN 'Holy See'
		WHEN country = 'South Korea' THEN 'Korea, South'
		WHEN country = 'Libyan Arab Jamahiriya' THEN 'Libya'
		WHEN country = 'Micronesia, Federated States of' THEN 'Micronesia'
		WHEN country = 'Russian Federation' THEN 'Russia'
		WHEN country = 'United States' THEN 'US'
		ELSE country
	END AS country 
FROM
	countries c 
)
SELECT
	cbdd.country,
	cbdd.`date`,
	cbdd.confirmed,
	ctu.tests_performed,
	lt.population,
	cbdd.weekday,
	cbdd.season,
	cu.population_density,
	cu.median_age_2018,
	e2.GDP / lt.population AS GDP_per_person,
	e2.gini,
	e2m.mortaliy_under5,
	vrcu.Christianity_proc,
	vrcu.Islam_proc,
	vrcu.Hinduism_proc,
	vrcu.Buddhism_proc,
	vrcu.Judaism_proc,
	vrcu.Folk_rel_proc,
	vrcu.Other_rel_proc,
	vrcu.Unaffiliated_rel_proc,
	vledu.diff,
	vmw.max_gust_day,
	vmw.rainy_hours,
	vmw.avg_temp_day
FROM
	covid19_basic_diff_date cbdd
LEFT JOIN v_mc_weather vmw ON
	cbdd.country = vmw.country AND cbdd.date = vmw.`date` 
LEFT JOIN covid19_tests_updated ctu ON
	cbdd.country = ctu.country AND cbdd.date = ctu.`date`
LEFT JOIN lookup_table lt ON
	cbdd.country = lt.country
LEFT JOIN countries_updated cu ON
	cbdd.country = cu.country
LEFT JOIN economies_2020 e2 ON
	cbdd.country = e2.country
LEFT JOIN economies_2019_mortality e2m ON
	cbdd.country = e2m.country
LEFT JOIN v_MC_rel_per_country_updated vrcu ON 
	cbdd.country = vrcu.country
LEFT JOIN v_MC_life_expectancy_diff_updated vledu ON
	cbdd.country = vledu.country
;

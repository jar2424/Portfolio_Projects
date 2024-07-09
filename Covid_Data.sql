-- Select Data we are going to be using
SELECT country, date, total_cases, new_cases, total_deaths, population
FROM public."Covid_Deaths"
	WHERE continent IS NOT NULL
	ORDER BY country, date;

-- Looking at total cases vs total deaths
-- Shows likelyhood of dying if you contract Covid in your country
SELECT country, date, total_cases, total_deaths, ROUND((total_deaths::numeric / total_cases::numeric),4) * 100 AS death_percentage
FROM public."Covid_Deaths"
	ORDER BY country, date;

-- Looking at total cases vs population
-- Shows what percentage of population got Covid
SELECT country, population, date, total_cases, ROUND((total_cases::numeric / population::numeric),4) * 100 AS infection_percentage
FROM public."Covid_Deaths"
	ORDER BY country, date;

-- Countries with highest infection rate compared to population
SELECT country, population, MAX(total_cases) AS total_cases, MAX(ROUND((total_cases::numeric / population::numeric),4)) * 100 AS infection_percentage
FROM public."Covid_Deaths"
	WHERE total_cases IS NOT NULL
	GROUP BY country, population
	ORDER BY infection_percentage DESC;

-- Showing Countries with highest death rate per population
SELECT country, population, MAX(total_deaths) AS total_death_count, MAX(ROUND((total_deaths::numeric / population::numeric),4)) * 100 AS death_percentage
FROM public."Covid_Deaths"
	WHERE total_deaths IS NOT NULL
	GROUP BY country, population
	ORDER BY death_percentage DESC;

-- Break total deaths down by continent
SELECT country, MAX(total_deaths) AS total_death_count
FROM public."Covid_Deaths"
	WHERE continent IS NULL
	AND country NOT LIKE '%income'
	GROUP BY country
	ORDER BY total_death_count DESC;

-- Global Numbers weekly
SELECT date, SUM(new_cases) AS total_new_cases, SUM(new_deaths) AS total_new_deaths, ROUND((SUM(new_deaths)/(SUM(new_cases)+0.0000001)),4)*100 AS death_percentage
FROM public."Covid_Deaths"
	WHERE continent IS NOT NULL
	GROUP BY date
	ORDER BY date;

-- Join Death & Vaccination Info
-- Running_Totals of New Vaccinations per Country
SELECT dea.continent, dea.country, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.country ORDER BY dea.country, dea.date) AS rolling_vaccination_count
FROM public."Covid_Deaths" AS dea
JOIN public."Covid_Vaccinations" AS vac
	ON dea.country = vac.country
	AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	ORDER BY dea.country, dea.date;

-- USE CTE
WITH PopVsVac (continent, country, date, population, new_vaccinations, rolling_vaccination_count)
	AS (
	SELECT dea.continent, dea.country, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.country ORDER BY dea.country, dea.date) AS rolling_vaccination_count
	FROM public."Covid_Deaths" AS dea
	JOIN public."Covid_Vaccinations" AS vac
		ON dea.country = vac.country
		AND dea.date = vac.date
		WHERE dea.continent IS NOT NULL
		ORDER BY dea.country, dea.date
)

SELECT country, date, rolling_vaccination_count, ROUND(rolling_vaccination_count / population,4)*100 AS vaccination_percentage
FROM PopVsVac;

-- TEMP TABLE
DROP TABLE if exists PercentPopulationVaccinated
CREATE TABLE PercentPopulationVaccinated (
    continent varchar(255),
    country varchar(255),
    date date,
    population numeric,
    new_vaccinations numeric,
    rolling_vaccination_count numeric
);

INSERT INTO PercentPopulationVaccinated
SELECT dea.continent, dea.country, dea.date, dea.population, vac.new_vaccinations, 
       SUM(vac.new_vaccinations) OVER (PARTITION BY dea.country ORDER BY dea.date) AS rolling_vaccination_count
FROM public."Covid_Deaths" AS dea
JOIN public."Covid_Vaccinations" AS vac
ON dea.country = vac.country
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT *, ROUND(rolling_vaccination_count / population, 4) * 100 AS vaccination_percentage
FROM PercentPopulationVaccinated;

-- Creating View to Store Data Later for Visualizations
CREATE VIEW PercentPopulationVaccinated_ AS
SELECT dea.continent, dea.country, dea.date, dea.population, vac.new_vaccinations, 
       SUM(vac.new_vaccinations) OVER (PARTITION BY dea.country ORDER BY dea.date) AS rolling_vaccination_count
FROM public."Covid_Deaths" AS dea
JOIN public."Covid_Vaccinations" AS vac
ON dea.country = vac.country
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;
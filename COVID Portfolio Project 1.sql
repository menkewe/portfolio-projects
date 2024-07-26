-- looking at data I will be using for analysis using basic SQL SELECT query
-- 1. covid deaths table
-- 2. covid vaccinations table

SELECT *
FROM [portfolio-project].dbo.coviddeaths
ORDER BY location, date;

SELECT *
FROM [portfolio-project]..covidvaccinations
ORDER BY 3, 4;

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM [portfolio-project]..coviddeaths
ORDER BY location, date;

-- looking at total cases vs. total deaths

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)
FROM [portfolio-project]..coviddeaths
ORDER BY location, date;

-- does not work due to t_d and t_c being nvarchar data type 
-- update to int and rerun

ALTER TABLE [portfolio-project]..coviddeaths
ALTER COLUMN total_deaths INT;

ALTER TABLE [portfolio-project]..coviddeaths
ALTER COLUMN total_cases INT;

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)
FROM [portfolio-project]..coviddeaths
ORDER BY location, date;

-- calc still does not work as int
-- update to decimal and rerun

ALTER TABLE [portfolio-project]..coviddeaths
ALTER COLUMN total_deaths DECIMAL;

ALTER TABLE [portfolio-project]..coviddeaths
ALTER COLUMN total_cases DECIMAL;

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)
FROM [portfolio-project]..coviddeaths
ORDER BY location, date;

-- update column to percentage and add column name
-- shows death rate of covid as percentage

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
FROM [portfolio-project]..coviddeaths
ORDER BY location, date;

-- shows death rate of covid for US

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
FROM [portfolio-project]..coviddeaths
WHERE location = 'United States'
ORDER BY location, date;

-- shows dates with highest covid death rate in US 

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
FROM [portfolio-project]..coviddeaths
WHERE location like 'United States'
ORDER BY death_percentage DESC;

-- looking at total cases vs. population
-- shows what percentage of US population contracted covid

SELECT location, date, total_cases, population, (total_cases/population)*100 as percent_population_infected
FROM [portfolio-project]..coviddeaths
WHERE location = 'United States'
ORDER BY location, date;

-- looking at countries with highest infection rate per population

SELECT 
	location, 
	MAX(total_cases) as highest_number_of_cases, 
	population, 
	MAX((total_cases/population))*100 as percent_population_infected
FROM 
	[portfolio-project].dbo.coviddeaths
GROUP BY
	location, 
	population
ORDER BY 
	percent_population_infected DESC;

-- looking at countries with highest number of covid deaths

SELECT 
	location, 
	MAX(total_deaths) as total_death_count
FROM 
	[portfolio-project].dbo.coviddeaths
WHERE
	continent is not null
GROUP BY
	location
ORDER BY 
	total_death_count DESC;


-- CONTINENT DATA


-- showing continents with highest death count 

SELECT 
	continent, 
	MAX(total_deaths) as total_death_count
FROM 
	[portfolio-project].dbo.coviddeaths
WHERE
	continent is not null
GROUP BY
	continent
ORDER BY 
	total_death_count DESC;


-- GLOBAL DATA


--looking at total cases vs total deaths each day globally
--used NULLIF to bypass divide by zero error

SELECT 
	date, 
	SUM(total_cases) as total_cases_globally,
	SUM(total_deaths) as total_deaths_globally,
	SUM(total_deaths)/NULLIF(SUM(total_cases),0)*100 as death_percentage
FROM
	[portfolio-project]..coviddeaths
WHERE
	continent is not null
GROUP BY 
	date
ORDER BY 
	date;

-- looking at global total cases, deaths, and death rate

SELECT 
	SUM(new_cases) as total_cases_globally,
	SUM(new_deaths) as total_deaths_globally,
	SUM(new_deaths)/NULLIF(SUM(new_cases),0)*100 as death_percentage
FROM
	[portfolio-project]..coviddeaths
WHERE
	continent is not null;

-- joining covid deaths and covid vaccinations tables

SELECT *
FROM [portfolio-project]..coviddeaths dea
	JOIN [portfolio-project]..covidvaccinations vax
		ON dea.location = vax.location
		AND dea.date = vax.date;

-- looking at population vs vaccinations

SELECT 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vax.new_vaccinations,
	SUM(CAST(vax.new_vaccinations as DECIMAL)) 
		OVER(PARTITION BY dea.location 
		ORDER BY dea.location, dea.date)
		as rolling_total_vaccinations
FROM [portfolio-project]..coviddeaths dea
	JOIN [portfolio-project]..covidvaccinations vax
		ON dea.location = vax.location
		AND dea.date = vax.date
WHERE 
	dea.continent is not null
ORDER BY 
	dea.location,
	dea.date;

-- options for calculating population vs vax
-- 1. USE CTE

WITH popvsvax (continent, location, date, population, new_vaccinations, rolling_total_vaccinations) AS
(
SELECT 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vax.new_vaccinations,
	SUM(CAST(vax.new_vaccinations as DECIMAL)) 
		OVER(PARTITION BY dea.location 
		ORDER BY dea.location, dea.date)
		as rolling_total_vaccinations
FROM [portfolio-project]..coviddeaths dea
	JOIN [portfolio-project]..covidvaccinations vax
		ON dea.location = vax.location
		AND dea.date = vax.date
WHERE 
	dea.continent is not null
)
SELECT *, (rolling_total_vaccinations/population)*100 as percent_population_vaccinated
FROM popvsvax
ORDER BY location, date;

-- 2. USE TEMP TABLE

DROP TABLE IF exists #percent_population_vaccinated
CREATE TABLE #percent_population_vaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_total_vaccinations numeric
)
INSERT INTO #percent_population_vaccinated
SELECT 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vax.new_vaccinations,
	SUM(CAST(vax.new_vaccinations as DECIMAL)) 
		OVER(PARTITION BY dea.location 
		ORDER BY dea.location, dea.date)
		as rolling_total_vaccinations
FROM [portfolio-project]..coviddeaths dea
	JOIN [portfolio-project]..covidvaccinations vax
		ON dea.location = vax.location
		AND dea.date = vax.date
WHERE 
	dea.continent is not null
	
SELECT *, (rolling_total_vaccinations/population)*100 as percent_population_vaccinated
FROM #percent_population_vaccinated
ORDER BY location, date;

--CREATING VIEW TO STORE DATA FOR LATER VIZ

CREATE VIEW percent_population_vaccinated AS 
SELECT 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vax.new_vaccinations,
	SUM(CAST(vax.new_vaccinations as DECIMAL)) 
		OVER(PARTITION BY dea.location 
		ORDER BY dea.location, dea.date)
		as rolling_total_vaccinations
FROM [portfolio-project]..coviddeaths dea
	JOIN [portfolio-project]..covidvaccinations vax
		ON dea.location = vax.location
		AND dea.date = vax.date
WHERE 
	dea.continent is not null

SELECT *
FROM percent_population_vaccinated

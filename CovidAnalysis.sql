--LINK TO TABLEAU DASHBOARD: https://public.tableau.com/app/profile/yash.manot/viz/CovidDashboard_17160672988070/Dashboard1?publish=yes

USE CovidProject

-- Analyzing the CovidDeaths table

SELECT *
FROM CovidProject..CovidDeaths
ORDER BY 3,4

-- To Select and Analyze the important features of the data

SELECT location, date, total_cases, new_cases, total_deaths, new_deaths, population
FROM CovidProject..CovidDeaths
ORDER BY 1,2

-- To Calculate the death percentage

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM CovidProject..CovidDeaths
ORDER BY 1,2

-- Death percentage in India

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentInd
FROM CovidProject..CovidDeaths
WHERE location = 'India'
ORDER BY 1,2

-- To Calculate the Infection percentage

SELECT location, date, total_cases, population, (total_cases/population)*100 as InfectionPercentage
FROM CovidProject..CovidDeaths
ORDER BY 1,2

-- Infection percentage in India

SELECT location, date, total_cases, population, (total_cases/population)*100 as InfectionPercentInd
FROM CovidProject..CovidDeaths
WHERE location = 'India'
ORDER BY 1,2

-- Countries ordered by highest Infection Percentage

SELECT location, max(total_cases) as TOTAL_CASES, population, max((total_cases/population))*100 as MaxInfectionPercentage
FROM CovidProject..CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY 4 desc

-- Countries ordered by highest number of deaths

SELECT location, max(cast(total_deaths as int)) as TOTAL_DEATHS
FROM CovidProject..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY 2 desc

-- Continents ordered by highest number of deaths

SELECT location, max(cast(total_deaths as int)) as TOTAL_DEATHS_CONTINENT
FROM CovidProject..CovidDeaths
WHERE continent is null and location != 'World' and location != 'International'
GROUP BY location
ORDER BY 2 desc

-- GLOBAL numbers

SELECT SUM(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))*100/sum(new_cases) as DeathPercentage
FROM CovidProject..CovidDeaths
WHERE continent is not null
ORDER BY 1

-- Daily GLOBAL numbers

SELECT date, SUM(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))*100/sum(new_cases) as DeathPercentage
FROM CovidProject..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1

-- Analyzing the CovidVaccinations table

SELECT *
FROM CovidProject..CovidVaccinations
ORDER BY 3,4

--Joining both the tables

SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations
FROM CovidProject..CovidDeaths d
JOIN CovidProject..CovidVaccinations v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent is not null
ORDER BY 2,3

-- To Calculate the Vaccinated percentage using CTE, Temp table and VIEW

SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, sum(CONVERT(int,v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) as cumulative_vaccinations
FROM CovidProject..CovidDeaths d
JOIN CovidProject..CovidVaccinations v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent is not null
ORDER BY 2,3

-- Using CTE

WITH Populationvaccinated (Continent, Location, Date, Population, New_vaccinations, Cumulative_vaccinations) --Creating CTE
AS(
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, sum(CONVERT(bigint,v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) as cumulative_vaccinations
FROM CovidProject..CovidDeaths d
JOIN CovidProject..CovidVaccinations v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent is not null
)
SELECT *, (Cumulative_vaccinations/Population)*100 as VaccinatedPercentage --Selecting data from CTE
FROM Populationvaccinated
ORDER BY 2,3

-- Using Temp table

DROP TABLE if exists #PercentageVaccinatedTemp
CREATE TABLE #PercentageVaccinatedTemp --Creating Temp Table
(Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population int,
New_vaccinations int,
Cumulative_vaccinations bigint)

INSERT INTO #PercentageVaccinatedTemp --Inserting data into Temp Table
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, sum(CONVERT(bigint,v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date)
FROM CovidProject..CovidDeaths d
JOIN CovidProject..CovidVaccinations v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent is not null

SELECT *,(CONVERT(decimal,Cumulative_vaccinations)/Population)*100 as VaccinatedPercentage --Selecting data from Temp Table
FROM #PercentageVaccinatedTemp
ORDER BY 2,3

-- Using VIEW

DROP VIEW IF EXISTS PercentageVaccinated;

CREATE VIEW PercentageVaccinated as --Creating VIEW
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, sum(CONVERT(bigint,v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) as Cumulative_vaccinations
FROM CovidProject..CovidDeaths d
JOIN CovidProject..CovidVaccinations v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent is not null

SELECT *, (Cumulative_vaccinations/Population)*100 as VaccinatedPercentage --Selecting data from VIEW
FROM dbo.PercentageVaccinated
ORDER BY 2,3

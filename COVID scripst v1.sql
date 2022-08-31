USE PortfolioProject

SELECT *
FROM CovidDeaths
WHERE continent is not null
ORDER BY 3,4

/*
SELECT *
from CovidVaccinations
order by 3,4
*/

-- Select Data that we are going to be using

SELECT
	location,
	date,
	total_cases,
	new_cases,
	total_deaths,
	population
FROM CovidDeaths
WHERE continent is not null
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows the liklihood of dying if you contract Covid in your country

SELECT
	location,
	date,
	total_cases,
	total_deaths,
	(total_deaths/total_cases)*100 AS Death_Percentage
FROM CovidDeaths
WHERE location = 'Israel'
	AND continent is not null
ORDER BY 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid

SELECT
	location,
	date,
	population,
	total_cases,
	(total_cases/population)*100 AS Infected_Population_Percentage
FROM CovidDeaths
WHERE location = 'Israel'
	AND continent is not null
ORDER BY 1,2

-- Looking at countries with Highest Infection Rate compared to Population

SELECT
	location,
	population,
	MAX(total_cases) AS Highest_Infection_Count,
	MAX((total_cases/population))*100 AS Max_Infected_Population_Percentage
FROM CovidDeaths
WHERE continent is not null
GROUP BY location,population
ORDER BY 4 DESC

-- Showing countries with the highest Death Count per Population

SELECT
	location,
	MAX(CAST(total_deaths AS INT)) AS Total_Death_Count
FROM CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY 2 DESC

-- Showing the continents with the highest Death Count per Population

SELECT
	continent,
	MAX(CAST(total_deaths AS INT)) AS Total_Death_Count
FROM CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY 2 DESC

-- Global Numbers

SELECT
	SUM(new_cases) AS Total_cases,
	SUM(CAST(new_deaths AS INT)) AS Total_deaths,
	SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS death_percentage
FROM CovidDeaths
WHERE continent is not null
--GROUP BY date 
ORDER BY 1,2

-- Looking at Total Population vs Vaccinations

SELECT A.continent,
		A.location,
		A.date,
		A.population,
		B.new_vaccinations,
		SUM(CAST(B.new_vaccinations AS BIGINT)) OVER(PARTITION BY A.location ORDER BY A.location,A.date) AS Rolling_People_Vaccinated
		--(Rolling_People_Vaccinated/population)*100
FROM CovidDeaths AS A
JOIN CovidVaccinations AS B
	ON A.location = B.location
		AND
	A.date = B.date
WHERE A.continent is not null
ORDER BY 2,3

--Using CTE with Date for "Rolling_People_Vaccinated"

WITH PopvsVac (Continent,Location,Date,Population,new_vaccinations,Rolling_People_Vaccinated)
	AS 
	(
	SELECT 
		A.continent,
		A.location,
		A.date,
		A.population,
		B.new_vaccinations,
		SUM(CAST(B.new_vaccinations AS BIGINT)) OVER(PARTITION BY A.location ORDER BY A.location,A.date) AS Rolling_People_Vaccinated
		--(Rolling_People_Vaccinated/population)*100
	FROM CovidDeaths AS A
	JOIN CovidVaccinations AS B
		ON A.location = B.location
		AND A.date = B.date
	WHERE A.continent is not null
	--ORDER BY 2,3
	)
SELECT *,(Rolling_People_Vaccinated/population)*100
FROM PopvsVac


--Using CTE for Total People_got_Vaccinated In each country

WITH PopvsVac (Location,Population,new_vaccinations,People_got_Vaccinated)
	AS 
	(
	SELECT  top(50) 
			A.location,
			A.population,
			B.new_vaccinations,
			MAX(CAST(B.new_vaccinations AS BIGINT)) OVER(PARTITION BY A.location ORDER BY A.location) AS People_got_Vaccinated
			--(People_got_Vaccinated/population)*100
	FROM CovidDeaths AS A
	JOIN CovidVaccinations AS B
		ON A.location = B.location
	WHERE A.continent is not null
	GROUP BY A.location,A.population, B.new_vaccinations
	ORDER BY 4 desc
	)
SELECT *,(People_got_Vaccinated/population)*100 AS Percent_of_population_got_vaccinated
FROM PopvsVac


--TEMP TABLE
DROP TABLE if Exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT 
		A.continent,
		A.location,
		A.date,
		A.population,
		B.new_vaccinations,
		SUM(CAST(B.new_vaccinations AS BIGINT)) OVER(PARTITION BY A.location ORDER BY A.location,A.date) AS RollingPeopleVaccinated
		--(Rolling_People_Vaccinated/population)*100
	FROM CovidDeaths AS A
	JOIN CovidVaccinations AS B
		ON A.location = B.location
		AND A.date = B.date
	WHERE A.continent is not null
	--ORDER BY 2,3

SELECT *,(RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated

--Creating view to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS 

SELECT 
		A.continent,
		A.location,
		A.date,
		A.population,
		B.new_vaccinations,
		SUM(CAST(B.new_vaccinations AS BIGINT)) OVER(PARTITION BY A.location ORDER BY A.location,A.date) AS RollingPeopleVaccinated
		--(Rolling_People_Vaccinated/population)*100
	FROM CovidDeaths AS A
	JOIN CovidVaccinations AS B
		ON A.location = B.location
		AND A.date = B.date
	WHERE A.continent is not null
	--ORDER BY 2,3

SELECT *
FROM PercentPopulationVaccinated
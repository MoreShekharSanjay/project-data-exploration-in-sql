
---- Project: DATA EXPLORATION IN SQL --------------------------------------------------------------------
---- Description: In this project we explore the Covid-19 death and vaccination data in SQL Server. ------
----------------------------------------------------------------------------------------------------------
---- Note: The data and observations are valid as of 16 May 2022. ----------------------------------------
---- Note: "population" column has been moved to position 5 before the column deletion in next steps. ----
---- Note: To get deaths.xlsx, remove columns AA to BO from owid-covid-data.xlsx file. -------------------
---- Note: To get vaccinations.xlsx, remove columns E to Z from owid-covid-data.xlsx file. ---------------
---- Note: The functions and commands are consistent with Microsoft SQL Server. --------------------------
----------------------------------------------------------------------------------------------------------

-- 1) Let's look at both the "deaths" and "vaccinations" tables.
	SELECT * FROM deaths
	ORDER BY location, date

	SELECT * FROM vaccinations
	ORDER BY location, date

-- 2) Let's change the data type of "date" column in both tables to DATE, and look at the important columns.
	ALTER TABLE deaths
	ALTER COLUMN date DATE

	ALTER TABLE vaccinations
	ALTER COLUMN date DATE

	SELECT location, date, total_cases, new_cases, total_deaths, population
	FROM deaths
	ORDER BY 1,2

-- 3) Let's look at Total Cases vs Total Deaths in India.
	SELECT location, date, total_deaths, total_cases, total_deaths/total_cases*100 as DeathPercentage
	FROM deaths
	WHERE location LIKE '%india%'
	ORDER BY 1, 2 DESC
---  Observation: Death percentage in India is 1.22%.

-- 4) Let's look at Total Cases vs Population in India.
	SELECT location, date, total_cases, population, total_cases/population*100 as InfectedPercentage
	FROM deaths
	WHERE location LIKE '%india%'
	ORDER BY 1, 2 DESC
---  Observation: Case percentage in India is 3.09%.

-- 5) Let's look at the countries with Highest Infection Rate compared to the population.
	SELECT location, MAX(total_cases) AS HighestInfectedCount, population, MAX(total_cases)/population*100 as InfectedPercentage
	FROM deaths
	WHERE continent IS NOT NULL
	GROUP BY location, population
	ORDER BY InfectedPercentage DESC 
---  Observation: Faroe Islands has had 70.65% population infected over the period.

-- 6) Let's convert the type of columns "total_deaths" and "new_deaths" in "deaths" table from NVARCHAR(255) to INT.
	ALTER TABLE deaths
	ALTER COLUMN total_deaths INT

	ALTER TABLE deaths
	ALTER COLUMN new_deaths INT

-- 7) Now let's look at the countries with Highest number of Deaths.
	SELECT location, MAX(total_deaths) AS TotalDeathCount
	FROM deaths
	WHERE continent IS NOT NULL
	GROUP BY location
	ORDER BY TotalDeathCount DESC 
---  Observation: United State has highest number of deaths at 999842.

-- 8) Let's focus on the data for the world.
	SELECT SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths,
		SUM(new_deaths)/SUM(new_cases)*100 AS GlobalDeathPercentage
	FROM deaths
	WHERE continent IS NOT NULL
---  Observation: Globally, the death percentage has been 1.20%.

-- 9) Let's get the Total number of Vaccinations on each day for each country using a rolling count.
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinationCount
	FROM deaths as dea
	JOIN vaccinations as vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	ORDER BY 2,3

-- 10) Let's find the Average of number of doses received by a person in a country.
	WITH AvgDoses (continent, location, date, population, new_vaccinations, RollingVaccinationCount) AS
	(
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinationCount
	FROM deaths as dea
	JOIN vaccinations as vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	)
	SELECT continent, location, population, ROUND(MAX(RollingVaccinationCount)/population,2) AS AvgDosesPerPerson
	FROM AvgDoses
	WHERE continent IS NOT NULL
	GROUP BY continent, location, population
	ORDER BY AvgDosesPerPerson DESC
---  Observation: Chile has given an average of 2.83 doses per person (highest), while India has given 1.32.

-- 11) Let's store the results from the previous query into a view for later use.
	CREATE VIEW ViewAvgDoses AS
	WITH AvgDoses (continent, location, date, population, new_vaccinations, RollingVaccinationCount) AS
	(
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinationCount
	FROM deaths as dea
	JOIN vaccinations as vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	)
	SELECT continent, location, population, ROUND(MAX(RollingVaccinationCount)/population,2) AS AvgDosesPerPerson
	FROM AvgDoses
	WHERE continent IS NOT NULL
	GROUP BY continent, location, population
	--ORDER BY AvgDosesPerPerson DESC (commented out because orderby is invalid in creating views)

-- 12) Let's see the created view.
	SELECT * FROM ViewAvgDoses
	ORDER BY AvgDosesPerPerson DESC
/*
Covid 19 Cases Data Exploration 
Raw data is downloaded from https://ourworldindata.org/covid-deaths
Techniques used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

--This query shows the whole picture of the CovidDeaths table.
--It ignored null values in its continent column and is sorted by Date as well as Population
Select *
From Covid19Database..CovidDeaths
Where continent is not null 
order by 3,4


-- By selecting key columns from the CovidDeath table, this query shows a clearer picture on countries level

Select Location, date, population, total_cases, new_cases, total_deaths 
From Covid19Database..CovidDeaths
Where continent is not null 
order by 1,2


-- Micro view: Total Cases vs Total Deaths
-- This query shows the likelihood of dying when contracted covid in Hong Kong.
-- We can see that the death percentage has remained under 2% since October last year.

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From Covid19Database..CovidDeaths
Where location = 'Hong Kong'
and continent is not null 
order by 1,2

--This query shows the total cases to date and the total deaths to date.
--Figures from the raw data are not neccessarily numeric, conversions are done for the sake of calculation.

Select Location, sum(cast(total_cases as int)) as TotalCasesToDate, sum(convert(int, total_deaths)) as TotalDeathsToDate
From Covid19Database..CovidDeaths
Where location = 'Hong Kong'
and continent is not null 
group by location


-- Macro View: Total Cases vs Population
-- This query shows the percentage of population contracted by Covid19 across the world.

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationContracted
From Covid19Database..CovidDeaths
order by 1,2


-- This query looks into countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestContractionCount,  Max((total_cases/population))*100 as PopulationContractedPercentage
From Covid19Database..CovidDeaths
Group by Location, Population
order by PopulationContractedPercentage desc

-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathsCount
From Covid19Database..CovidDeaths
Where continent is not null 
Group by Location
order by TotalDeathsCount desc



-- Below continues exploring the data on a continent level.

-- This query shows contintents with the highest death count per population
-- We found North America has the highest total death count per population.

Select Continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From Covid19Database..CovidDeaths
Where Continent is not null 
Group by Continent
order by TotalDeathCount desc



-- Now we continues to explore the covid situation on a global level.

--This query finds out total cases, total deaths, as well as the death percentage globally.

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From Covid19Database..CovidDeaths
where continent is not null 
order by 1,2

--Now we merge another table called CovidVaccinations to check out the vaccination scene.

-- Total Population vs Vaccinations
-- This query shows the percentage of Population that has recieved at least one Covid Vaccine.
-- 

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Covid19Database..CovidDeaths dea
Join Covid19Database..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
and vac.new_vaccinations is not null
order by 1,2,3


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From Covid19Database..CovidDeaths dea
Join Covid19Database..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Covid19Database..CovidDeaths dea
Join Covid19Database..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date


Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated




-- This query creates a view to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From Covid19Database..CovidDeaths dea
Join Covid19Database..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

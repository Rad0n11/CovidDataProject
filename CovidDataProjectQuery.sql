select *
from CovidDataProject..CovidDeaths
order by 3,4

select *
from CovidDataProject..CovidVaccinations
order by 3,4

select *
from CovidDataProject..CovidDeaths
where location like '%Afg%'

-- Total cases vs total deaths
Select location, date, total_cases, total_deaths
,(total_deaths/total_cases)*100 as percent_deaths
from CovidDataProject..CovidDeaths
where location = 'Pakistan'
order by 1,2

-- Max percentage of death for each location with partition clause
Select location, date, population, total_deaths, total_cases
,(total_cases/population)*100 as rate_of_cases,(cast(total_deaths as int)/total_cases)*100 as rate_of_deaths
,Avg((total_cases/population)*100) OVER (Partition by location) as avg_cases_rate 
,Avg((cast(total_deaths as int)/total_cases)*100) OVER (partition by location) as avg_death_rate
from CovidDataProject..CovidDeaths
where total_deaths is not null AND total_cases is not null
order by 1,2

-- Max percentage of death for each location (1 row for each location)
Select location
,Avg((total_cases/population)*100) as avg_cases_rate 
,Avg((cast(total_deaths as int)/total_cases)*100) as avg_death_rate
from CovidDataProject..CovidDeaths
where total_deaths is not null AND total_cases is not null
group by location
order by 1

--Countries with their infection rate in descending order

select location, population, MAX(total_cases) as MaxInfectionCount
,MAX((total_cases/population)*100) as PercentPopuInfected
from CovidDataProject..CovidDeaths
where continent is not null
Group by location, population
order by MaxInfectionCount Desc

--Countries with highest death rate

Select location, MAX(cast(total_deaths as int)) as MaxDeathCount
,Max((total_deaths/population)*100) as MaxPercentDeath
,Max((total_deaths/total_cases)*100) as MaxDeathByCases
from CovidDataProject..CovidDeaths
where continent is not null
Group by location
order by 2 Desc

--Contitnents with highest death rate (wrong numbers)

Select continent, MAX(cast(total_deaths as int)) as MaxDeathCount
,Max((total_deaths/population)*100) as MaxPercentDeath
,Max((total_deaths/total_cases)*100) as MaxDeathByCases
from CovidDataProject..CovidDeaths
where continent is not null
Group by continent
order by 2 Desc



--Contitnents with highest death rate (wrong numbers)

Select location, MAX(cast(total_deaths as int)) as MaxDeathCount
,Max((total_deaths/population)*100) as MaxPercentDeath
,Max((total_deaths/total_cases)*100) as MaxDeathByCases
from CovidDataProject..CovidDeaths
where continent is null
Group by location
order by 2 Desc


-- Global numbers

select date, sum(new_cases) cases_that_day
, sum(total_cases) cases_upto_that_day
, sum(cast(new_deaths as int)) deaths_that_day
, sum(cast(total_deaths as int)) deaths_upto_that_day
, (sum(cast(total_deaths as int))/sum(total_cases))*100 as percent_death
from CovidDataProject..CovidDeaths
where continent is not null
group by date
order by 1

-- total count worldwide

select sum(new_cases) total_cases--cases_that_day
--, sum(total_cases) cases_upto_that_day
, sum(cast(new_deaths as int)) total_deaths--deaths_that_day
--, sum(cast(total_deaths as int)) deaths_upto_that_day
, (sum(cast(new_deaths as int))/sum(new_cases))*100 as percent_death
from CovidDataProject..CovidDeaths
where continent is not null
order by 1

-- Vaccination data

select *
from CovidDataProject..CovidVaccinations

select *
from CovidDataProject..CovidDeaths

-- Joining deaths and vaccinations
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by
dea.date) total_vac_to_date
from CovidDataProject..CovidDeaths dea
join CovidDataProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- Using a custom column to create another column
--		CTE

With PopVsVax (continent, location, date, population, new_vaccinations, total_vac_to_date)
as(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert(bigint,vac.new_vaccinations)) OVER (Partition by dea.location 
Order by dea.date) total_vac_to_date
--, (total_vac_to_date/population)*100 as percent_vac_to_date
from CovidDataProject..CovidDeaths dea
inner join CovidDataProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
--order by dea.location, dea.date
)
Select *, (total_vac_to_date/population)*100 as percent_vac_to_date
From PopVsVax
Order by 2,3


--			Temp Table

DROP Table if exists #PopVsVax2
Create Table #PopVsVax2
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric,
total_vac_to_date numeric
)

Insert into #PopVsVax2
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert(bigint,vac.new_vaccinations)) OVER (Partition by dea.location 
Order by dea.date) total_vac_to_date
--, (total_vac_to_date/population)*100 as percent_vac_to_date
from CovidDataProject..CovidDeaths dea
inner join CovidDataProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
--order by dea.location, dea.date

Select *, (total_vac_to_date/population)*100 as percent_vac_to_date
From #PopVsVax2
Order by 2,3


-- Create view for visualization

DROP View if exists PopVsVaxView
GO
Create View PopVsVaxView as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert(bigint,vac.new_vaccinations)) OVER (Partition by dea.location 
Order by dea.date) total_vac_to_date
--, (total_vac_to_date/population)*100 as percent_vac_to_date
from CovidDataProject..CovidDeaths dea
inner join CovidDataProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
--order by dea.location, dea.date
)
GO

Select *
From PopVsVaxView


Create Table PopVsVaxTable
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric,
total_vac_to_date numeric
)

Insert into PopVsVaxTable
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert(bigint,vac.new_vaccinations)) OVER (Partition by dea.location 
Order by dea.date) total_vac_to_date
--, (total_vac_to_date/population)*100 as percent_vac_to_date
from CovidDataProject..CovidDeaths dea
inner join CovidDataProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
--order by dea.location, dea.date

Insert into dbo.PopVsVaxTable (Continent, Location,Population)
Values ('AAFarwaniya', 'Home', 15)


Delete From PopVsVaxTable
where Continent = 'AAFarwaniya' and Population = 13
Select *
From PopVsVaxTable
Order by Continent



Insert into PopVsVaxTable (Continent, Location,Population)
Values ('AAFarwaniya', 'Home', 13)



DROP Table PopVsVaxTable
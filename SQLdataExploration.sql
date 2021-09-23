--select * from PortfolioProject.dbo.[covid-deaths]
--order by 3,4

select * from PortfolioProject.dbo.[covid-deaths];

select location,date, total_cases, new_cases, total_deaths, population
from PortfolioProject.dbo.[covid-deaths]
order by 1,2;

-- TOTAL CASES VS TOTAL DEATHS
-- POSSIBILITY OF DEATH IF YOU CONTRACT COVID IN YOUR COUNTRY

select location,date, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100, 2) AS DEATH_PERCENTAGE
from PortfolioProject.dbo.[covid-deaths]
WHERE location LIKE '%INDIA%'
order by 1,2;


-- TOTAL CASES VS POPULATION
-- PERCENTAGE OF POPULATION GOT COVID

select location,date, POPULATION, total_cases, (total_cases/POPULATION)*100 AS COVID_PERCENTAGE
from PortfolioProject.dbo.[covid-deaths]
WHERE location LIKE '%INDIA%'
order by 1,2;

-- COUNTRIES WITH HIGHEST INFECTION RATE COMPARED TO POPULATION	

select location, POPULATION, MAX(total_cases) AS HighestInfectionCount, max((total_cases/POPULATION)*100) AS PercentPopulationInfected
from PortfolioProject.dbo.[covid-deaths]
group by Location, population
order by PercentPopulationInfected desc;

--Countries with Highest Death Count per Population

select location, max(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject.dbo.[covid-deaths]
where continent is not null
group by Location
order by TotalDeathCount desc;


-- Continent with Highest Death Count per Population

select location, max(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject.dbo.[covid-deaths]
where continent is null
group by Location
order by TotalDeathCount desc;


--Death Percentage by DATE


select  sum(new_cases) as TotalCases, sum(cast(new_deaths as int) ) as TotalDeaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
from PortfolioProject.dbo.[covid-deaths]
where continent is not null
--group by date
order by DeathPercentage desc;


-- Total Population vs Vaccinations

select dea.continent, dea.location, dea.date, dea.population,vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.date) RollingPeopleVaccinated
from PortfolioProject..[covid-deaths] dea
join PortfolioProject..[covid-vaccinations] vac
	on dea.location= vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3


-- use CTE
with PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population,vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..[covid-deaths] dea
join PortfolioProject..[covid-vaccinations] vac
	on dea.location= vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
select * , (RollingPeopleVaccinated/population)*100
from 
PopvsVac

-- TEMP TABLE


CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations int,
RollingPeopleVaccinated int
)

insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population,vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..[covid-deaths] dea
join PortfolioProject..[covid-vaccinations] vac
	on dea.location= vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
select * , (RollingPeopleVaccinated/population)*100
from 
#PercentPopulationVaccinated


-- Creating VIEW for visualizations

Create view PercentPopVaccinated as
select dea.continent, dea.location, dea.date, dea.population,vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..[covid-deaths] dea
join PortfolioProject..[covid-vaccinations] vac
	on dea.location= vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
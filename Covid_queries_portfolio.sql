-- Update date column from text to Date format
UPDATE portfolio_project.covid_vaccination SET date = STR_TO_DATE(date, '%d-%m-%Y');


select * from portfolio_project.covid_death
where continent is not null
order by 1,2;

-- select * from portfolio_project.covid_vaccination
-- order by 3,4;
select location,date, total_cases,new_cases, total_deaths,population 
from portfolio_project.covid_death
where continent is not null
order by 1,2;

-- Total Cases vs Total Death
select location,date, total_cases, total_deaths,icu_patients
,(total_deaths/total_cases)*100 as death_percentage
from portfolio_project.covid_death
where location like '%india%' and continent is not null
order by 1,2;

-- Total cases vs population
select location,date, total_cases,population,(total_deaths/population)*100 as covid_percentage
from portfolio_project.covid_death
where location like '%india%'
order by 5 desc;

select location,date, total_cases,icu_patients,total_deaths, (total_deaths/icu_patients)*100
from portfolio_project.covid_death
order by 6 desc;

-- countries with highest infection vs population
select location,population, max(total_cases) as highest_infection_count, max((total_cases/population)*100) as percent_population_infected
from portfolio_project.covid_death
-- where location like '%india%'
group by 1,2
order by 4 desc;

-- countries with highest death count
-- Typecaste total death as int from varchar 
select location,max(CAST(total_deaths as SIGNED)) as total_death_count
from portfolio_project.covid_death
where continent is not null
group by 1
order by 2 desc;

-- By Continent
select continent,location,max(CAST(total_deaths as SIGNED)) as total_death_count
from portfolio_project.covid_death
where continent =''
group by 1,2
order by 3 desc;

-- By Continent and location
select continent,location,max(CAST(total_deaths as SIGNED)) as total_death_count
from portfolio_project.covid_death
where continent <> ''
group by 1,2
order by 3 desc;


-- By Continent alone
select continent,max(CAST(total_deaths as SIGNED)) as total_death_count
from portfolio_project.covid_death
where continent <> ''
group by 1
order by 2 desc;

-- Global Numbers
select date, sum(new_cases) as total_cases, sum(CAST(new_deaths as SIGNED)) as total_deaths,
(sum(CAST(new_deaths as SIGNED))/sum(new_cases))*100 as death_percentage
from portfolio_project.covid_death
where continent <> ''
group by 1
order by 1,2;


-- Overall Global Death Percentage
select  sum(new_cases) as total_cases, sum(CAST(new_deaths as SIGNED)) as total_deaths,
(sum(CAST(new_deaths as SIGNED))/sum(new_cases))*100 as death_percentage
from portfolio_project.covid_death
where continent <> '' and location like '%india%'
-- group by 1
order by 1,2;

-- Vaccine Table
select * from portfolio_project.covid_vaccination;

-- Joining both Tables
select * 
from portfolio_project.covid_Death dea
join portfolio_project.covid_vaccination vac 
on dea.location = vac.location
and dea.date = vac.date;


-- Total population vs vaccination
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(CAST(vac.new_vaccinations as SIGNED)) over (partition by dea.location order by dea.location, dea.date) as rolling_people_vaccinated
from portfolio_project.covid_Death dea
join portfolio_project.covid_vaccination vac 
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent <> ''
order by 2,3;

-- Using CTE to use rolling people vaccinated
with popvsvac (continent,location,date,population,new_vaccinations,rolling_people_vaccinated
)
as
(
	select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(CAST(vac.new_vaccinations as SIGNED)) over (partition by dea.location order by dea.location, dea.date) as rolling_people_vaccinated
	from portfolio_project.covid_Death dea
	join portfolio_project.covid_vaccination vac 
		on dea.location = vac.location
		and dea.date = vac.date
	where dea.continent <> ''
	-- order by 2,3;
)
select *, (rolling_people_vaccinated/population)*100
from popvsvac;


-- Temp Table
drop table if exists portfolio_project.percent_population_vaccinated; 
CREATE TABLE portfolio_project.percent_population_vaccinated (
    continent VARCHAR(255),
    location VARCHAR(255),
    date DATETIME,
    population NUMERIC,
    new_vaccination NUMERIC,
    rolling_people_vaccinated NUMERIC
);

INSERT INTO portfolio_project.percent_population_vaccinated
	SELECT dea.continent, dea.location, dea.date, dea.population,
		   CASE WHEN vac.new_vaccinations <> '' THEN CAST(vac.new_vaccinations AS DECIMAL(10, 2)) ELSE NULL END,
		   SUM(CASE WHEN vac.new_vaccinations <> '' THEN CAST(vac.new_vaccinations AS SIGNED) ELSE 0 END) OVER (PARTITION BY dea.location ORDER BY dea.date) AS rolling_people_vaccinated
	FROM portfolio_project.covid_Death dea
	JOIN portfolio_project.covid_vaccination vac 
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent <> '';

SELECT *, (rolling_people_vaccinated / population) * 100
FROM portfolio_project.percent_population_vaccinated;


-- create view
create view percent_population_vaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population,
		   CASE WHEN vac.new_vaccinations <> '' THEN CAST(vac.new_vaccinations AS DECIMAL(10, 2)) ELSE NULL END,
		   SUM(CASE WHEN vac.new_vaccinations <> '' THEN CAST(vac.new_vaccinations AS SIGNED) ELSE 0 END) OVER (PARTITION BY dea.location ORDER BY dea.date) AS rolling_people_vaccinated
	FROM portfolio_project.covid_Death dea
	JOIN portfolio_project.covid_vaccination vac 
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent <> '';



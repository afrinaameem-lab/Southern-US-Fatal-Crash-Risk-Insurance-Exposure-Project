--analysis query 1: exposure by state
--identifying which southern states have the highest fatal crash exposure based on crash count, fatalities, and average insurance exposure score.

select
    STATENAME,
    count(*) as fatal_crash_count,
    sum(FATALS) as total_fatalities,
    avg(cast(INSURANCE_EXPOSURE_SCORE as float)) as avg_exposure_score,
    sum(case when EXPOSURE_TIER in ('High Exposure', 'Very High Exposure') then 1 else 0 end) as high_exposure_crashes
from risk.vw_insurance_exposure_score
group by STATENAME
order by avg_exposure_score desc;

--analysis query 2: exposure by roadway group
--comparing fatal crash exposure across roadway types to identify which road environments carry higher insurance risk.

select
    ROADWAY_GROUP,
    count(*) as fatal_crash_count,
    sum(FATALS) as total_fatalities,
    avg(cast(INSURANCE_EXPOSURE_SCORE as float)) as avg_exposure_score,
    sum(case when EXPOSURE_TIER in ('High Exposure', 'Very High Exposure') then 1 else 0 end) as high_exposure_crashes
from risk.vw_insurance_exposure_score
group by ROADWAY_GROUP
order by avg_exposure_score desc;

--analysis query 3: exposure by environmental condition
--comparing weather and light conditions to understand how environmental factors contribute to fatal crash exposure.


select
    WEATHER_GROUP,
    LGT_CONDNAME,
    count(*) as fatal_crash_count,
    sum(FATALS) as total_fatalities,
    avg(cast(INSURANCE_EXPOSURE_SCORE as float)) as avg_exposure_score
from risk.vw_insurance_exposure_score
group by
    WEATHER_GROUP,
    LGT_CONDNAME
order by avg_exposure_score desc;

--analysis query 4: exposure by human risk factors
--measuring how substance involvement and restraint use relate to fatal crash exposure.


select
    SUBSTANCE_INVOLVED,
    case
        when NOT_RESTRAINED_COUNT > 0 then 'Unrestrained Involved'
        else 'No Unrestrained Involved'
    end as restraint_status,
    count(*) as fatal_crash_count,
    sum(FATALS) as total_fatalities,
    avg(cast(INSURANCE_EXPOSURE_SCORE as float)) as avg_exposure_score
from risk.vw_insurance_exposure_score
group by
    SUBSTANCE_INVOLVED,
    case
        when NOT_RESTRAINED_COUNT > 0 then 'Unrestrained Involved'
        else 'No Unrestrained Involved'
    end
order by avg_exposure_score desc;

--analysis query 5: top high-exposure crash profiles
--reviewing the highest-scoring crash records to understand the combination of factors behind severe insurance exposure.


select top (25)
    ST_CASE,
    STATENAME,
    COUNTYNAME,
    CITYNAME,
    FATALS,
    TIME_PERIOD,
    RUR_URBNAME,
    ROADWAY_GROUP,
    LGT_CONDNAME,
    WEATHER_GROUP,
    SUBSTANCE_INVOLVED,
    SPEEDING_INVOLVED,
    ROLLOVER_INVOLVED,
    MOTORCYCLE_COUNT,
    PEDESTRIAN_COUNT,
    INSURANCE_EXPOSURE_SCORE,
    EXPOSURE_TIER
from risk.vw_insurance_exposure_score
order by INSURANCE_EXPOSURE_SCORE desc;

--dashboard summary view

--dashboard view 1: state exposure summary
--summarizing fatal crash exposure by southern state for dashboard maps, bar charts, and KPI comparisons.


create or alter view risk.vw_state_exposure_summary as
select
    STATENAME,
    count(*) as FATAL_CRASH_COUNT,
    sum(FATALS) as TOTAL_FATALITIES,
    avg(cast(INSURANCE_EXPOSURE_SCORE as float)) as AVG_EXPOSURE_SCORE,
    sum(case when EXPOSURE_TIER = 'Very High Exposure' then 1 else 0 end) as VERY_HIGH_EXPOSURE_CRASHES,
    sum(case when EXPOSURE_TIER = 'High Exposure' then 1 else 0 end) as HIGH_EXPOSURE_CRASHES,
    sum(case when SUBSTANCE_INVOLVED = 1 then 1 else 0 end) as SUBSTANCE_INVOLVED_CRASHES,
    sum(case when SPEEDING_INVOLVED = 1 then 1 else 0 end) as SPEEDING_INVOLVED_CRASHES,
    sum(case when IS_DARK = 1 then 1 else 0 end) as DARK_CONDITION_CRASHES,
    sum(case when IS_RURAL = 1 then 1 else 0 end) as RURAL_CRASHES
from risk.vw_insurance_exposure_score
group by STATENAME;

select *
from risk.vw_state_exposure_summary
order by AVG_EXPOSURE_SCORE desc;

--dashboard view 2: risk factor exposure summary
--comparing major environmental, roadway, human, and vehicle-related risk factors in one dashboard-ready view.


create or alter view risk.vw_risk_factor_summary as

select
    'Human Factor' as FACTOR_CATEGORY,
    'Substance Involved' as RISK_FACTOR,
    count(*) as CRASH_COUNT,
    sum(FATALS) as TOTAL_FATALITIES,
    avg(cast(INSURANCE_EXPOSURE_SCORE as float)) as AVG_EXPOSURE_SCORE
from risk.vw_insurance_exposure_score
where SUBSTANCE_INVOLVED = 1

union all

select
    'Human Factor',
    'Unrestrained Occupant',
    count(*),
    sum(FATALS),
    avg(cast(INSURANCE_EXPOSURE_SCORE as float))
from risk.vw_insurance_exposure_score
where NOT_RESTRAINED_COUNT > 0

union all

select
    'Environmental Factor',
    'Dark Condition',
    count(*),
    sum(FATALS),
    avg(cast(INSURANCE_EXPOSURE_SCORE as float))
from risk.vw_insurance_exposure_score
where IS_DARK = 1

union all

select
    'Environmental Factor',
    'Rain or Adverse Weather',
    count(*),
    sum(FATALS),
    avg(cast(INSURANCE_EXPOSURE_SCORE as float))
from risk.vw_insurance_exposure_score
where WEATHER_GROUP in ('Rain', 'Adverse Weather')

union all

select
    'Roadway Factor',
    'Rural Road',
    count(*),
    sum(FATALS),
    avg(cast(INSURANCE_EXPOSURE_SCORE as float))
from risk.vw_insurance_exposure_score
where IS_RURAL = 1

union all

select
    'Roadway Factor',
    'High Speed Limit',
    count(*),
    sum(FATALS),
    avg(cast(INSURANCE_EXPOSURE_SCORE as float))
from risk.vw_insurance_exposure_score
where HIGH_SPEED_LIMIT_INVOLVED = 1

union all

select
    'Vehicle / Crash Factor',
    'Speeding Involved',
    count(*),
    sum(FATALS),
    avg(cast(INSURANCE_EXPOSURE_SCORE as float))
from risk.vw_insurance_exposure_score
where SPEEDING_INVOLVED = 1

union all

select
    'Vehicle / Crash Factor',
    'Rollover Involved',
    count(*),
    sum(FATALS),
    avg(cast(INSURANCE_EXPOSURE_SCORE as float))
from risk.vw_insurance_exposure_score
where ROLLOVER_INVOLVED = 1

union all

select
    'Vehicle / Crash Factor',
    'Motorcycle Involved',
    count(*),
    sum(FATALS),
    avg(cast(INSURANCE_EXPOSURE_SCORE as float))
from risk.vw_insurance_exposure_score
where MOTORCYCLE_COUNT > 0;

select *
from risk.vw_risk_factor_summary
order by AVG_EXPOSURE_SCORE desc;

--dashboard view 3: exposure tier summary
--showing how fatal crashes are distributed across lower, moderate, high, and very high insurance exposure tiers.


create or alter view risk.vw_exposure_tier_summary as
select
    EXPOSURE_TIER,
    count(*) as CRASH_COUNT,
    sum(FATALS) as TOTAL_FATALITIES,
    avg(cast(INSURANCE_EXPOSURE_SCORE as float)) as AVG_EXPOSURE_SCORE
from risk.vw_insurance_exposure_score
group by EXPOSURE_TIER;

select *
from risk.vw_exposure_tier_summary
order by AVG_EXPOSURE_SCORE desc;
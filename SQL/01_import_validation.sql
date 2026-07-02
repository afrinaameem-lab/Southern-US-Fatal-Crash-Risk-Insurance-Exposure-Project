create database SouthernCrashInsuranceRisk;
go


use SouthernCrashInsuranceRisk;
go


create schema risk;
go


drop table if exists risk.weather;
drop table if exists risk.vehicle;
drop table if exists risk.person;
drop table if exists risk.accident;
go

create table risk.accident
(
    st_case int not null constraint pk_accident primary key,
    state int not null,
    state_name varchar(50) not null,
    crash_year int not null,
    month_name varchar(20) not null,
    day_week_name varchar(20) not null,
    hour_name varchar(30) not null,
    rural_urban varchar(50) null,
    functional_system varchar(100) null,
    light_condition varchar(100) null,
    weather_condition varchar(100) null,
    fatalities int not null
);
go

create table risk.person
(
    st_case int not null,
    veh_no int not null,
    per_no int not null,
    age int null,
    age_name varchar(50) null,
    sex_name varchar(30) null,
    person_type varchar(100) null,
    injury_severity varchar(100) null,
    drinking_name varchar(100) null,
    drugs_name varchar(100) null,
    constraint pk_person primary key (st_case, veh_no, per_no),
    constraint fk_person_accident foreign key (st_case)
        references risk.accident(st_case)
);
go

create table risk.vehicle
(
    st_case int not null,
    veh_no int not null,
    model_year int null,
    make_name varchar(100) null,
    body_type varchar(150) null,
    rollover_name varchar(100) null,
    fire_explosion varchar(100) null,

    constraint pk_vehicle primary key (st_case, veh_no),
    constraint fk_vehicle_accident foreign key (st_case)
        references risk.accident(st_case)
);
go

create table risk.weather
(
    st_case int not null,
    weather int not null,
    weather_name varchar(100) not null,

    constraint pk_weather primary key (st_case, weather),
    constraint fk_weather_accident foreign key (st_case)
        references risk.accident(st_case)
);
go

create schema staging;
go

drop table if exists staging.weather;
drop table if exists staging.vehicle;
drop table if exists staging.person;
drop table if exists staging.accident;
go

create table staging.accident
(
    st_case int null,
    state int null,
    statename varchar(50) null,
    year int null,
    monthname varchar(20) null,
    day_weekname varchar(20) null,
    hourname varchar(30) null,
    rur_urbname varchar(50) null,
    func_sysname varchar(100) null,
    lgt_condname varchar(100) null,
    weathername varchar(100) null,
    fatals int null
);
go

create table staging.person
(
    st_case int null,
    veh_no int null,
    per_no int null,
    age int null,
    agename varchar(50) null,
    sexname varchar(30) null,
    per_typname varchar(100) null,
    inj_sevname varchar(100) null,
    drinkingname varchar(100) null,
    drugsname varchar(100) null
);
go

create table staging.vehicle
(
    st_case int null,
    veh_no int null,
    mod_year int null,
    makename varchar(100) null,
    body_typname varchar(150) null,
    rollovername varchar(100) null,
    fire_expname varchar(100) null
);
go

create table staging.weather
(
    st_case int null,
    weather int null,
    weathername varchar(100) null
);
go

select db_name() as current_database;

exec sp_rename 'dbo.[accident-model]', 'accident_model';

select
    table_schema,
    table_name
from information_schema.tables
where table_type = 'BASE TABLE'
order by table_name;

select count(*) as accident_rows
from dbo.accident_model;

select count(*) as person_rows
from dbo.person_model;

select count(*) as vehicle_rows
from dbo.vehicle_model;

-- missing key validation

select count(*) as missing_accident_keys
from dbo.accident_model
where ST_CASE is null;

select count(*) as missing_person_keys
from dbo.person_model
where ST_CASE is null
   or VEH_NO is null
   or PER_NO is null;

select count(*) as missing_vehicle_keys
from dbo.vehicle_model
where ST_CASE is null
   or VEH_NO is null;

--coordinate quality check
--coordinates after cleaning. invalid FARS coordinates were changed to 0,
--so 0 will be treated as missing location data later in analysis.


select
    count(*) as total_crashes,
    sum(case when LATITUDE is null then 1 else 0 end) as null_latitude,
    sum(case when LONGITUD is null then 1 else 0 end) as null_longitude,
    sum(case when LATITUDE = 0 then 1 else 0 end) as zero_latitude,
    sum(case when LONGITUD = 0 then 1 else 0 end) as zero_longitude
from dbo.accident_model;

--checking whether every person and vehicle record connects
--relationship validation

select count(*) as person_without_matching_accident
from dbo.person_model p
left join dbo.accident_model a
    on p.ST_CASE = a.ST_CASE
where a.ST_CASE is null;

select count(*) as vehicle_without_matching_accident
from dbo.vehicle_model v
left join dbo.accident_model a
    on v.ST_CASE = a.ST_CASE
where a.ST_CASE is null;

-- ============================================================
--crash base analytical view
--creating a clean accident-level view with derived fields for environmental and roadway risk analysis.
--columns that will support the fatal crash exposure model.


create or alter view risk.vw_crash_base as
select
    ST_CASE,
    STATE,
    STATENAME,
    COUNTYNAME,
    CITYNAME,
    YEAR,
    MONTH,
    MONTHNAME,
    DAY_WEEK,
    DAY_WEEKNAME,
    HOUR,
    HOURNAME,
    RUR_URB,
    RUR_URBNAME,
    FUNC_SYS,
    FUNC_SYSNAME,
    LGT_COND,
    LGT_CONDNAME,
    HARM_EV,
    HARM_EVNAME,
    WEATHER,
    WEATHERNAME,
    FATALS,

    case
        when LATITUDE = 0 then null
        else LATITUDE
    end as LATITUDE_CLEAN,

    case
        when LONGITUD = 0 then null
        else LONGITUD
    end as LONGITUD_CLEAN,

    case
        when DAY_WEEKNAME in ('Saturday', 'Sunday') then 1
        else 0
    end as IS_WEEKEND,

    case
        when HOUR between 0 and 5 then 'Overnight'
        when HOUR between 6 and 11 then 'Morning'
        when HOUR between 12 and 17 then 'Afternoon'
        when HOUR between 18 and 23 then 'Evening/Night'
        else 'Unknown'
    end as TIME_PERIOD,

    case
        when RUR_URBNAME = 'Rural' then 1
        else 0
    end as IS_RURAL,

    case
        when LGT_CONDNAME like '%Dark%' then 1
        else 0
    end as IS_DARK,

    case
        when WEATHERNAME = 'Clear' then 'Clear'
        when WEATHERNAME = 'Cloudy' then 'Cloudy'
        when WEATHERNAME like '%Rain%' then 'Rain'
        when WEATHERNAME like '%Snow%'
          or WEATHERNAME like '%Fog%'
          or WEATHERNAME like '%Sleet%'
          or WEATHERNAME like '%Hail%'
          or WEATHERNAME like '%Crosswind%' then 'Adverse Weather'
        when WEATHERNAME like '%Unknown%'
          or WEATHERNAME like '%Not Reported%' then 'Unknown'
        else 'Other'
    end as WEATHER_GROUP,

    case
        when FUNC_SYSNAME like '%Interstate%' then 'Interstate'
        when FUNC_SYSNAME like '%Freeway%' then 'Freeway / Expressway'
        when FUNC_SYSNAME like '%Arterial%' then 'Arterial'
        when FUNC_SYSNAME like '%Collector%' then 'Collector'
        when FUNC_SYSNAME like '%Local%' then 'Local Road'
        when FUNC_SYSNAME like '%Unknown%'
          or FUNC_SYSNAME like '%Not Reported%' then 'Unknown'
        else 'Other'
    end as ROADWAY_GROUP
from dbo.accident_model;

select top (20) *
from risk.vw_crash_base;

--\creating a clean person-level view for alcohol, drug to acquire the age, injury, and restraint-related fatal crash risk analysis.


create or alter view risk.vw_person_factors as
select
    ST_CASE,
    VEH_NO,
    PER_NO,
    STATE,
    STATENAME,
    AGE,
    AGENAME,
    SEX,
    SEXNAME,
    PER_TYP,
    PER_TYPNAME,
    INJ_SEV,
    INJ_SEVNAME,
    REST_USE,
    REST_USENAME,
    DRINKING,
    DRINKINGNAME,
    ALC_RES,
    ALC_RESNAME,
    DRUGS,
    DRUGSNAME,

    case
        when AGE between 0 and 15 then '0-15'
        when AGE between 16 and 20 then '16-20'
        when AGE between 21 and 24 then '21-24'
        when AGE between 25 and 34 then '25-34'
        when AGE between 35 and 44 then '35-44'
        when AGE between 45 and 64 then '45-64'
        when AGE between 65 and 110 then '65+'
        else 'Unknown'
    end as AGE_GROUP,

    case
        when DRINKINGNAME like '%Yes%' then 1
        else 0
    end as ALCOHOL_FLAG,

    case
        when DRUGSNAME like '%Yes%' then 1
        else 0
    end as DRUG_FLAG,

    case
        when DRINKINGNAME like '%Yes%'
          or DRUGSNAME like '%Yes%' then 1
        else 0
    end as SUBSTANCE_INVOLVED,

    case
        when PER_TYPNAME like '%Driver%' then 'Driver'
        when PER_TYPNAME like '%Passenger%' then 'Passenger'
        when PER_TYPNAME like '%Pedestrian%' then 'Pedestrian'
        when PER_TYPNAME like '%Bicyclist%' then 'Bicyclist'
        else 'Other / Unknown'
    end as PERSON_GROUP,

    case
        when INJ_SEVNAME like '%Fatal%' then 'Fatal Injury'
        when INJ_SEVNAME like '%Suspected Serious%' then 'Serious Injury'
        when INJ_SEVNAME like '%Suspected Minor%' then 'Minor Injury'
        when INJ_SEVNAME like '%Possible Injury%' then 'Possible Injury'
        when INJ_SEVNAME like '%No Apparent Injury%' then 'No Apparent Injury'
        else 'Unknown'
    end as INJURY_GROUP,

    case
        when REST_USENAME like '%Shoulder and Lap Belt Used%' then 'Restrained'
        when REST_USENAME like '%None Used%' then 'Not Restrained'
        when REST_USENAME like '%Unknown%'
          or REST_USENAME like '%Not Reported%' then 'Unknown'
        else 'Other'
    end as RESTRAINT_GROUP
from dbo.person_model;

select top (20) *
from risk.vw_person_factors;

--creating a clean vehicle-level view for vehicle type, speed, rollover, fire, road surface, and vehicle-age risk analysis.


create or alter view risk.vw_vehicle_factors as
select
    ST_CASE,
    VEH_NO,
    STATE,
    STATENAME,
    MOD_YEAR,
    MOD_YEARNAME,
    MAKENAME,
    BODY_TYP,
    BODY_TYPNAME,
    VPICBODYCLASSNAME,
    ROLLOVER,
    ROLLOVERNAME,
    FIRE_EXP,
    FIRE_EXPNAME,
    DEATHS,
    DR_DRINK,
    DR_DRINKNAME,
    SPEEDREL,
    SPEEDRELNAME,
    VSPD_LIM,
    VSPD_LIMNAME,
    VSURCOND,
    VSURCONDNAME,

    case
        when MOD_YEAR between 1950 and 2024 then 2024 - MOD_YEAR
        else null
    end as VEHICLE_AGE,

    case
        when MOD_YEAR between 2020 and 2024 then '0-4 Years'
        when MOD_YEAR between 2015 and 2019 then '5-9 Years'
        when MOD_YEAR between 2010 and 2014 then '10-14 Years'
        when MOD_YEAR between 2000 and 2009 then '15-24 Years'
        when MOD_YEAR between 1950 and 1999 then '25+ Years'
        else 'Unknown'
    end as VEHICLE_AGE_GROUP,

    case
        when BODY_TYPNAME like '%Passenger Car%' then 'Passenger Car'
        when BODY_TYPNAME like '%Sport Utility%' 
          or BODY_TYPNAME like '%Utility%' then 'SUV / Utility'
        when BODY_TYPNAME like '%Pickup%' then 'Pickup'
        when BODY_TYPNAME like '%Motorcycle%' then 'Motorcycle'
        when BODY_TYPNAME like '%Truck%' then 'Truck'
        when BODY_TYPNAME like '%Van%' then 'Van'
        when BODY_TYPNAME like '%Unknown%'
          or BODY_TYPNAME like '%Not Reported%' then 'Unknown'
        else 'Other'
    end as VEHICLE_TYPE_GROUP,

    case
        when ROLLOVERNAME like '%Rollover%' 
          and ROLLOVERNAME not like '%No Rollover%' then 1
        else 0
    end as ROLLOVER_FLAG,

    case
        when FIRE_EXPNAME like '%Yes%' then 1
        else 0
    end as FIRE_FLAG,

    case
        when SPEEDRELNAME like '%Yes%' 
          or SPEEDRELNAME like '%Speed%' then 1
        else 0
    end as SPEEDING_FLAG,

    case
        when VSPD_LIM between 1 and 34 then 'Low Speed Limit'
        when VSPD_LIM between 35 and 54 then 'Medium Speed Limit'
        when VSPD_LIM between 55 and 85 then 'High Speed Limit'
        else 'Unknown'
    end as SPEED_LIMIT_GROUP,

    case
        when VSURCONDNAME like '%Dry%' then 'Dry'
        when VSURCONDNAME like '%Wet%' then 'Wet'
        when VSURCONDNAME like '%Snow%'
          or VSURCONDNAME like '%Ice%'
          or VSURCONDNAME like '%Slush%' then 'Snow / Ice / Slush'
        when VSURCONDNAME like '%Sand%'
          or VSURCONDNAME like '%Mud%'
          or VSURCONDNAME like '%Dirt%'
          or VSURCONDNAME like '%Oil%' then 'Contaminated Surface'
        when VSURCONDNAME like '%Unknown%'
          or VSURCONDNAME like '%Not Reported%' then 'Unknown'
        else 'Other'
    end as SURFACE_GROUP
from dbo.vehicle_model;

select top (20) *
from risk.vw_vehicle_factors;
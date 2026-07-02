-- ============================================================
-- main crash exposure model for fatal crash exposure analysis.
-- which environmental, roadway, and human factors contribute most to fatal crash exposure in southern u.s. states?
-- combining crash, human, and vehicle factors into one crash-level

-- person and vehicle data are first summarized to the crash level as before joining back to accident data, this prevents duplicate crash
-- counts because one crash can involve multiple people and vehicles.


create or alter view risk.vw_crash_exposure_model as

with person_summary as
(
    select
        ST_CASE,

        count(*) as PERSON_COUNT,

        max(ALCOHOL_FLAG) as ALCOHOL_INVOLVED,
        max(DRUG_FLAG) as DRUG_INVOLVED,
        max(SUBSTANCE_INVOLVED) as SUBSTANCE_INVOLVED,

        sum(case when PERSON_GROUP = 'Driver' then 1 else 0 end) as DRIVER_COUNT,
        sum(case when PERSON_GROUP = 'Passenger' then 1 else 0 end) as PASSENGER_COUNT,
        sum(case when PERSON_GROUP = 'Pedestrian' then 1 else 0 end) as PEDESTRIAN_COUNT,

        sum(case when INJURY_GROUP = 'Fatal Injury' then 1 else 0 end) as PERSON_FATAL_INJURY_COUNT,
        sum(case when RESTRAINT_GROUP = 'Not Restrained' then 1 else 0 end) as NOT_RESTRAINED_COUNT

    from risk.vw_person_factors
    group by ST_CASE
),

vehicle_summary as
(
    select
        ST_CASE,

        count(*) as VEHICLE_COUNT,

        max(ROLLOVER_FLAG) as ROLLOVER_INVOLVED,
        max(FIRE_FLAG) as FIRE_INVOLVED,
        max(SPEEDING_FLAG) as SPEEDING_INVOLVED,

        sum(case when VEHICLE_TYPE_GROUP = 'Motorcycle' then 1 else 0 end) as MOTORCYCLE_COUNT,
        sum(case when VEHICLE_TYPE_GROUP = 'Truck' then 1 else 0 end) as TRUCK_COUNT,
        sum(case when VEHICLE_TYPE_GROUP = 'SUV / Utility' then 1 else 0 end) as SUV_COUNT,

        avg(cast(VEHICLE_AGE as float)) as AVG_VEHICLE_AGE,

        max(case when SPEED_LIMIT_GROUP = 'High Speed Limit' then 1 else 0 end) as HIGH_SPEED_LIMIT_INVOLVED,
        max(case when SURFACE_GROUP in ('Wet', 'Snow / Ice / Slush', 'Contaminated Surface') then 1 else 0 end) as ADVERSE_SURFACE_INVOLVED

    from risk.vw_vehicle_factors
    group by ST_CASE
)

select
    c.ST_CASE,
    c.STATE,
    c.STATENAME,
    c.COUNTYNAME,
    c.CITYNAME,

    c.YEAR,
    c.MONTH,
    c.MONTHNAME,
    c.DAY_WEEKNAME,
    c.TIME_PERIOD,
    c.IS_WEEKEND,

    c.RUR_URBNAME,
    c.IS_RURAL,
    c.FUNC_SYSNAME,
    c.ROADWAY_GROUP,

    c.LGT_CONDNAME,
    c.IS_DARK,

    c.WEATHERNAME,
    c.WEATHER_GROUP,

    c.HARM_EVNAME,
    c.FATALS,

    c.LATITUDE_CLEAN,
    c.LONGITUD_CLEAN,

    ps.PERSON_COUNT,
    ps.DRIVER_COUNT,
    ps.PASSENGER_COUNT,
    ps.PEDESTRIAN_COUNT,
    ps.PERSON_FATAL_INJURY_COUNT,
    ps.NOT_RESTRAINED_COUNT,
    ps.ALCOHOL_INVOLVED,
    ps.DRUG_INVOLVED,
    ps.SUBSTANCE_INVOLVED,

    vs.VEHICLE_COUNT,
    vs.MOTORCYCLE_COUNT,
    vs.TRUCK_COUNT,
    vs.SUV_COUNT,
    vs.AVG_VEHICLE_AGE,
    vs.ROLLOVER_INVOLVED,
    vs.FIRE_INVOLVED,
    vs.SPEEDING_INVOLVED,
    vs.HIGH_SPEED_LIMIT_INVOLVED,
    vs.ADVERSE_SURFACE_INVOLVED

from risk.vw_crash_base c

left join person_summary ps
    on c.ST_CASE = ps.ST_CASE

left join vehicle_summary vs
    on c.ST_CASE = vs.ST_CASE;
	go

select top (20) *
from risk.vw_crash_exposure_model;
go




--fatal crash insurance exposure score
--creating a crash-level risk score that translates the environmental, roadway, human, and vehicle factors into an insurance exposure tier.


create or alter view risk.vw_insurance_exposure_score as

with score_base as
(
    select
        ST_CASE,
        STATE,
        STATENAME,
        COUNTYNAME,
        CITYNAME,
        YEAR,
        MONTHNAME,
        DAY_WEEKNAME,
        TIME_PERIOD,

        RUR_URBNAME,
        IS_RURAL,
        ROADWAY_GROUP,

        LGT_CONDNAME,
        IS_DARK,

        WEATHERNAME,
        WEATHER_GROUP,

        HARM_EVNAME,
        FATALS,

        PERSON_COUNT,
        VEHICLE_COUNT,

        ALCOHOL_INVOLVED,
        DRUG_INVOLVED,
        SUBSTANCE_INVOLVED,
        NOT_RESTRAINED_COUNT,

        SPEEDING_INVOLVED,
        HIGH_SPEED_LIMIT_INVOLVED,
        ROLLOVER_INVOLVED,
        FIRE_INVOLVED,
        ADVERSE_SURFACE_INVOLVED,

        PEDESTRIAN_COUNT,
        MOTORCYCLE_COUNT,
        AVG_VEHICLE_AGE,

        LATITUDE_CLEAN,
        LONGITUD_CLEAN,

        (
            -- severity weight
            FATALS * 5

            -- human factor weights
            + case when SUBSTANCE_INVOLVED = 1 then 3 else 0 end
            + case when NOT_RESTRAINED_COUNT > 0 then 2 else 0 end
            + case when PEDESTRIAN_COUNT > 0 then 2 else 0 end

            -- roadway and environmental weights
            + case when IS_RURAL = 1 then 2 else 0 end
            + case when IS_DARK = 1 then 2 else 0 end
            + case when WEATHER_GROUP in ('Rain', 'Adverse Weather') then 1 else 0 end
            + case when ADVERSE_SURFACE_INVOLVED = 1 then 1 else 0 end
            + case when HIGH_SPEED_LIMIT_INVOLVED = 1 then 2 else 0 end

            -- vehicle and crash behavior weights
            + case when SPEEDING_INVOLVED = 1 then 3 else 0 end
            + case when ROLLOVER_INVOLVED = 1 then 3 else 0 end
            + case when FIRE_INVOLVED = 1 then 2 else 0 end
            + case when MOTORCYCLE_COUNT > 0 then 2 else 0 end
        ) as INSURANCE_EXPOSURE_SCORE

    from risk.vw_crash_exposure_model
)

select
    *,
    case
        when INSURANCE_EXPOSURE_SCORE >= 18 then 'Very High Exposure'
        when INSURANCE_EXPOSURE_SCORE >= 13 then 'High Exposure'
        when INSURANCE_EXPOSURE_SCORE >= 9 then 'Moderate Exposure'
        else 'Lower Exposure'
    end as EXPOSURE_TIER
from score_base;
go


select top (20)
    ST_CASE,
    STATENAME,
    FATALS,
    SUBSTANCE_INVOLVED,
    IS_DARK,
    IS_RURAL,
    SPEEDING_INVOLVED,
    ROLLOVER_INVOLVED,
    INSURANCE_EXPOSURE_SCORE,
    EXPOSURE_TIER
from risk.vw_insurance_exposure_score
order by INSURANCE_EXPOSURE_SCORE desc;

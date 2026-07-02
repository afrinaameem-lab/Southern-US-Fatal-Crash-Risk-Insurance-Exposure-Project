# Southern U.S. Fatal Crash Risk & Insurance Exposure Model

I wanted to build a project that felt more serious than just making a dashboard. Since I am trying to move toward data analyst / business analyst / risk analyst roles, I wanted something that showed SQL, data cleaning, business thinking, and Power BI storytelling together.

This project looks at fatal crash data across selected Southern U.S. states and asks one main question:

**Which environmental, roadway, and human factors contribute most to fatal crash exposure in Southern U.S. states?**

<br>

The idea behind this project is simple: insurance companies care about exposure. A crash is not just a crash. The risk looks different when the crash involves darkness, rural roads, speeding, substance involvement, high speed limits, rollover, motorcycles, or unrestrained occupants. So instead of only counting crashes, I created an insurance exposure score to compare how severe different crash conditions are.

<br>

## Tools Used

- SQL Server / SSMS
- Power BI
- Excel Power Query
- CSV data cleaning
- Data modeling
- DAX measures
- Dashboard design

<br>

## Data

The project uses FARS fatal crash data filtered to selected Southern U.S. states.

The main files used were:

- `accident_model.csv`
- `person_model.csv`
- `vehicle_model.csv`

I originally reviewed the weather file too, but I decided not to include it in the first version because the accident file already had `WEATHER` and `WEATHERNAME`. I wanted to keep the model clean and use the minimum number of files needed to answer the question.

<br>

## What I Did

I started by cleaning and narrowing the CSV files in Excel Power Query. The original files had a lot of columns, and not all of them were needed for this business question. I kept the columns that supported environmental, roadway, vehicle, and human risk analysis.

After cleaning, I imported the files into SQL Server and created analytical views.

Some of the SQL work included:

- Import validation
- Missing key checks
- Relationship checks between accident, person, and vehicle data
- Cleaning latitude and longitude placeholder values
- Creating crash-level summaries from person and vehicle records
- Creating analytical fields using `case when`
- Building an insurance exposure score
- Creating dashboard-ready SQL views

<br>

## SQL Logic

One important thing I learned while working on this project was that I could not just join accident, person, and vehicle data directly and call it done.

One crash can involve multiple people and multiple vehicles. If I joined everything row by row, I would accidentally duplicate crash counts.

So I summarized the person and vehicle data to the crash level first, then joined those summaries back to the accident data. That made the final model one row per crash.

<br>

## Insurance Exposure Score

I created a custom **Insurance Exposure Score** using crash severity and risk factors.

The score gives weight to things like:

- Number of fatalities
- Substance involvement
- Unrestrained occupants
- Pedestrian involvement
- Rural roads
- Darkness
- Rain or adverse weather
- Adverse road surface
- High speed limits
- Speeding involvement
- Rollover
- Fire/explosion
- Motorcycle involvement

Then I grouped the crashes into exposure tiers:

- Lower Exposure
- Moderate Exposure
- High Exposure
- Very High Exposure

This is not meant to be an official insurance pricing model. It is a portfolio model that shows how crash data can be translated into a risk-focused business view.

<br>

## Power BI Dashboard

The dashboard has three pages:

### 1. Executive Overview

This page gives the high-level picture of fatal crash exposure by state. It includes total fatal crashes, total fatalities, average exposure score, high exposure crashes, and exposure tier distribution.

### 2. Risk Factor Analysis

This page answers the main business question more directly. It compares human, roadway, environmental, and vehicle/crash factors by average exposure score, fatalities, and crash count.

### 3. Crash-Level Drilldown

This page shows high-exposure crash locations on a map and lets the user filter by state, roadway, weather, and time period. Records with missing or placeholder coordinates were excluded from the map but still included in the non-map analysis.

<br>

## Main Takeaway

The highest fatal crash exposure does not come from one single factor alone. The strongest risk patterns appear when multiple factors overlap, such as rural roads, darkness, high speed limits, speeding, substance involvement, rollover, and unrestrained occupants.

That is why I wanted this project to be more than just a count of crashes. I wanted to show how raw crash records can be cleaned, modeled, scored, and turned into business insights for risk analysis.

<br>

## Skills Shown

- SQL joins and CTEs
- SQL views
- `case when` logic
- Data validation
- Data wrangling
- Power Query cleaning
- Power BI dashboard design
- DAX measures
- Risk scoring logic
- Business analysis storytelling

<br>

## Project Files

In this repository, you will find:

- SQL scripts used for validation, analytical views, and exposure scoring
- Cleaned CSV files used for the model
- Power BI dashboard file
- Dashboard screenshots
- Project README

<br>

## Future Improvements

If I keep building on this project, I would like to add:

- More years of FARS data instead of only one year
- Identifying the car models and the type most responsible for crashes
- Separate weather table logic for crashes with multiple weather conditions
- Insurance cost or premium data for comparison
- More advanced statistical analysis in Python or R
- A more formal weighted scoring method based on actual actuarial or insurance research

<br>

Overall, this project helped me practice building a full data workflow from raw CSV files to SQL modeling to Power BI storytelling, while keeping the analysis tied to a real business question.

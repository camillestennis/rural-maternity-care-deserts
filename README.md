# Rural Maternity Care Deserts

**An analysis of rural hospital closures, county-level income, and demographics across the United States (2005–2026)**

🔗 **[View the interactive dashboard on Tableau Public](https://public.tableau.com/app/profile/camille.stennis/viz/RuralMaternityCareDeserts/RuralMaternityCareDesertsHospitalClosuresIncomeandDemographics)**

## The Problem

Since 2020, more than 100 rural hospitals have closed or converted away from labor and delivery services, and only 41% of U.S. rural hospitals still provide obstetric care. Losing a hospital doesn't just mean losing a building — it means longer drive times to give birth, more births in emergency rooms, and worse outcomes for mothers and infants in the communities left behind.

This project asks two questions:
1. **Where** are rural hospitals closing, and what does county-level income look like in those places?
2. **Who** lives in these counties — are Black, American Indian/Alaska Native, and Hispanic communities represented at notable rates?

## Data Sources

| Source | What it provides | Coverage |
|---|---|---|
| [UNC Sheps Center](https://www.shepscenter.unc.edu/programs-projects/rural-health/rural-hospital-closures/) | Rural hospital closures (complete & converted) | 2005–2026, 197 hospitals |
| [CDC WONDER](https://wonder.cdc.gov/) | Linked birth/infant death records by county | 2015–2023 |
| [U.S. Census Bureau, ACS 5-Year Estimates](https://data.census.gov/) | Median household income by county | 2019–2023 |
| [U.S. Census Bureau, ACS 5-Year Estimates](https://data.census.gov/) | Population by race/ethnicity by county | 2019–2023 |

## Methodology

All data was cleaned and joined in **SQLite** (via DB Browser for SQLite), then visualized in **Tableau Public**. Key steps:

- **Fixed leading-zero data corruption** in FIPS county codes and ZIP codes that Excel/SQLite silently stripped on import
- **Bridged inconsistent county identifiers** across sources — CDC/Census data uses 5-digit FIPS codes, while the Sheps Center data uses plain county names + state abbreviations. Built a `state_lookup` reference table and `SUBSTR`/`CASE WHEN` logic to reconcile them, including handling Louisiana parishes and Alaska boroughs, which don't follow the standard "County" naming convention
- **Diagnosed and documented a real data limitation**: CDC WONDER suppresses birth/death counts of 9 or fewer for privacy, which disproportionately removes small rural counties — exactly the counties this project is about — from the infant mortality dataset. Only ~7 of 197 closure counties could be matched to individual CDC infant mortality records for this reason; income and demographic data, which isn't subject to the same suppression, matched successfully for 195 of 197 (99%)
- Removed import artifacts (blank/footnote rows accidentally pulled in from source spreadsheets)

See [`/sql/queries.sql`](./sql/queries.sql) for the full set of queries, including the final `hospital_closures_with_income` view.

## Key Findings

- Rural hospital closures cluster heavily in the South, lower Midwest, and rural West
- Across the 197 closure counties, average county-level demographic composition is **~10.65% Black**, **~10.59% Hispanic**, and **~1.30% American Indian/Alaska Native**
- *Note: this describes who lives in affected counties, not a statistically controlled disparity claim — this dataset doesn't include a non-closure-county baseline for direct comparison.*

## Tools Used

Excel (data cleaning) · SQL / SQLite (joins, data reconciliation) · Tableau Public (visualization)

## Limitations

- Infant mortality analysis is limited to a small, non-representative subset of counties due to CDC privacy suppression (see Methodology)
- A small number of hospital records (2 of 197) could not be geographically matched due to source data inconsistencies (e.g., independent cities not associated with any county)
- This is a descriptive analysis, not a causal one — it does not establish that closures *caused* demographic or income patterns, only that they co-occur

## About

Built by [Camille Stennis](https://www.linkedin.com/in/camille-stennis) as a hands-on portfolio project while completing the Google Data Analytics Certificate.

-- ============================================================
-- Rural Maternity Care Deserts
-- Key SQL queries used to clean, join, and analyze the data
-- Database: rural_maternity_project.db (SQLite, via DB Browser)
-- ============================================================


-- ------------------------------------------------------------
-- 1. STATE ABBREVIATION LOOKUP TABLE
-- Needed because hospital_closures uses 2-letter state codes,
-- while Census data (median_income, race_population) spells
-- out the full state name in its NAME column.
-- ------------------------------------------------------------

CREATE TABLE state_lookup (
    abbreviation TEXT PRIMARY KEY,
    full_name TEXT
);

INSERT INTO state_lookup (abbreviation, full_name) VALUES
('AL','Alabama'),('AK','Alaska'),('AZ','Arizona'),('AR','Arkansas'),('CA','California'),
('CO','Colorado'),('CT','Connecticut'),('DE','Delaware'),('FL','Florida'),('GA','Georgia'),
('HI','Hawaii'),('ID','Idaho'),('IL','Illinois'),('IN','Indiana'),('IA','Iowa'),
('KS','Kansas'),('KY','Kentucky'),('LA','Louisiana'),('ME','Maine'),('MD','Maryland'),
('MA','Massachusetts'),('MI','Michigan'),('MN','Minnesota'),('MS','Mississippi'),('MO','Missouri'),
('MT','Montana'),('NE','Nebraska'),('NV','Nevada'),('NH','New Hampshire'),('NJ','New Jersey'),
('NM','New Mexico'),('NY','New York'),('NC','North Carolina'),('ND','North Dakota'),('OH','Ohio'),
('OK','Oklahoma'),('OR','Oregon'),('PA','Pennsylvania'),('RI','Rhode Island'),('SC','South Carolina'),
('SD','South Dakota'),('TN','Tennessee'),('TX','Texas'),('UT','Utah'),('VT','Vermont'),
('VA','Virginia'),('WA','Washington'),('WV','West Virginia'),('WI','Wisconsin'),('WY','Wyoming'),
('DC','District of Columbia'),('PR','Puerto Rico');


-- ------------------------------------------------------------
-- 2. DATA QUALITY FIX: remove blank/footnote rows that were
-- accidentally imported from the source Excel file (leftover
-- legend text sitting below the real data).
-- ------------------------------------------------------------

DELETE FROM hospital_closures WHERE "State" IS NULL OR "State" = '';
-- Result: 204 rows -> 197 real hospital closure records


-- ------------------------------------------------------------
-- 3. THREE-TABLE JOIN (FIPS-code based)
-- infant_deaths, median_income, and race_population all key
-- on 5-digit FIPS county codes -- but Census's GEO_ID field
-- stores it as "0500000US01073" instead of "01073", so SUBSTR
-- is used to extract just the last 5 characters for matching.
-- ------------------------------------------------------------

SELECT
    d."County",
    d."County Code" AS fips_code,
    d."Year of Death",
    d."Deaths",
    d."Births",
    d."Death Rate",
    m."Median_HH_Income",
    r."Total_Population",
    r."Pop_White_NonHispanic",
    r."Pop_Black",
    r."Pop_AIAN",
    r."Pop_Hispanic"
FROM infant_deaths d
JOIN median_income m ON d."County Code" = SUBSTR(m."GEO_ID", -5)
JOIN race_population r ON d."County Code" = SUBSTR(r."GEO_ID", -5);


-- ------------------------------------------------------------
-- 4. FINAL VIEW: hospital_closures_with_income
-- Joins hospital_closures (name-based, no FIPS code) to
-- median_income and race_population (Census NAME format:
-- "County Name County, State"). Uses CASE WHEN because
-- Louisiana ("Parish") and Alaska ("Borough"/no "County" word,
-- plus a stray trailing comma in the source data) don't follow
-- the standard naming pattern.
--
-- Match rate: 195 of 197 hospitals (99%) successfully matched.
-- The 2 unmatched are independent cities (e.g. Norton, VA) that
-- are not part of any county.
-- ------------------------------------------------------------

CREATE VIEW hospital_closures_with_income AS
SELECT
    h.*,
    sl.full_name AS state_full_name,
    m.Median_HH_Income,
    m.Median_HH_Income_MOE,
    r.Total_Population,
    r.Pop_White_NonHispanic,
    r.Pop_Black,
    r.Pop_AIAN,
    r.Pop_Hispanic
FROM hospital_closures h
JOIN state_lookup sl ON h."State" = sl.abbreviation
LEFT JOIN median_income m
    ON CASE
        WHEN h."State" = 'LA' THEN h."County/district" || ', ' || sl.full_name
        WHEN h."State" = 'AK' THEN TRIM(h."County/district", ',') || ', ' || sl.full_name
        ELSE h."County/district" || ' County, ' || sl.full_name
       END = m.NAME
LEFT JOIN race_population r
    ON CASE
        WHEN h."State" = 'LA' THEN h."County/district" || ', ' || sl.full_name
        WHEN h."State" = 'AK' THEN TRIM(h."County/district", ',') || ', ' || sl.full_name
        ELSE h."County/district" || ' County, ' || sl.full_name
       END = r.NAME;


-- ------------------------------------------------------------
-- 5. CALCULATED DEMOGRAPHIC SHARE FIELDS
-- (built as Tableau calculated fields, shown here in SQL form
-- for reference)
-- ------------------------------------------------------------

-- Pct Black    = Pop_Black / Total_Population
-- Pct AIAN     = Pop_AIAN / Total_Population
-- Pct Hispanic = Pop_Hispanic / Total_Population

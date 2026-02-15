-- 1. Infrastructure Setup
CREATE WAREHOUSE IF NOT EXISTS COMPUTE_WH
    WITH WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE;

CREATE DATABASE IF NOT EXISTS FOOD_SUPPLY_CHAIN;

-- 2. Schema Architecture (Medallion)
USE DATABASE FOOD_SUPPLY_CHAIN;

CREATE SCHEMA IF NOT EXISTS BRONZE; -- Raw ingestion
CREATE SCHEMA IF NOT EXISTS SILVER; -- Cleaned/Transformed
CREATE SCHEMA IF NOT EXISTS GOLD;   -- Business Aggregates

-- 3. Service Account for Airflow/dbt
-- Replace 'strong_password' with a secure password
CREATE USER IF NOT EXISTS SVC_DATA_ENGINEER
    PASSWORD = 'strong_password_here'
    DEFAULT_WAREHOUSE = COMPUTE_WH
    DEFAULT_ROLE = ACCOUNTADMIN; -- For development simplicity; restrict in prod

GRANT ROLE ACCOUNTADMIN TO USER SVC_DATA_ENGINEER;
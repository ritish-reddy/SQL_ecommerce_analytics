-- ============================================================
-- FILE: 01_database_creation.sql
-- PROJECT: E-Commerce Sales & Customer Analytics
-- AUTHOR: Ritish
-- DATE: 2024
-- PURPOSE: Create the database that will hold all project tables
-- ============================================================

-- ---------------------------------------------------------------
-- STEP 1: CREATE THE DATABASE
-- ---------------------------------------------------------------
-- "CREATE DATABASE" instructs MySQL to create a new empty container.
-- IF NOT EXISTS prevents errors when this script is run more than once.

CREATE DATABASE IF NOT EXISTS ecommerce_analytics;

-- ---------------------------------------------------------------
-- STEP 2: SELECT WHICH DATABASE TO USE
-- ---------------------------------------------------------------
-- Without USE, every table/query targets the default database.
-- Always write USE at the top of every SQL file in this project.

USE ecommerce_analytics;

-- ---------------------------------------------------------------
-- STEP 3: VERIFY THE DATABASE EXISTS
-- ---------------------------------------------------------------

SHOW DATABASES LIKE 'ecommerce_analytics';

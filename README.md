Job Matchmaker
=======

## Requires the following Python modules

 * bs4
 * psycopg2
 * PyYAML

## Description

Indeed multi search, allows rating of jobs, hides rated jobs by default

## Database Setup

 * su postgres -
 * psql
 * CREATE DATABASE job_matchmaker;
 * CREATE USER job_matchmaker WITH PASSWORD 'job_matchmaker';
 * GRANT ALL PRIVILEGES ON DATABASE job_matchmaker TO job_matchmaker;
 * \q
 * exit




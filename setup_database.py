#!/usr/bin/python36

#Import libraries

#Import helper library
from helper import *

try:
    #Connect to the database
    db_con = connectToDatabase()
    db_cur = db_con.cursor()

    #Drop the tables if they already exist
    #db_cur.execute("""DROP TABLE IF EXISTS job_user_ratings""")
    db_cur.execute("""DROP TABLE IF EXISTS jobs""")
    db_cur.execute("""DROP TABLE IF EXISTS search""")
    db_cur.execute("""DROP TABLE IF EXISTS search_jobs""")
    db_cur.execute("""DROP TABLE IF EXISTS user_job_ratings""")
    db_cur.execute("""DROP TABLE IF EXISTS users""")

    #Create tables
    #db_cur.execute("""CREATE TABLE job_user_ratings(job_id VARCHAR(251), user_id VARCHAR(251), rating smallint, PRIMARY KEY(job_id, user_id))""")
    db_cur.execute("""CREATE TABLE jobs(job_id VARCHAR(251), country VARCHAR(2), location VARCHAR(252), title VARCHAR(253), company VARCHAR(254), link VARCHAR(255), summary VARCHAR(512), posted timestamp, PRIMARY KEY(job_id))""")
    db_cur.execute("""CREATE TABLE search(search_id VARCHAR(248), country VARCHAR(2), location VARCHAR(252), search_string VARCHAR(253), search_time timestamp, PRIMARY KEY(search_id))""")
    db_cur.execute("""CREATE TABLE search_jobs(search_id VARCHAR(248), job_id VARCHAR(251), PRIMARY KEY(search_id, job_id))""")
    db_cur.execute("""CREATE TABLE user_job_ratings(user_id VARCHAR(251), job_id VARCHAR(251), rating real, PRIMARY KEY(user_id, job_id))""")
    db_cur.execute("""CREATE TABLE users(user_id VARCHAR(251), user_name VARCHAR(250), PRIMARY KEY(user_id))""")

    #Commit the database changes
    db_con.commit()

    #Close the database connection
    db_cur.close()
    db_con.close()

except Exception as e:
    print(e)




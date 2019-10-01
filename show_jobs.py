#!/usr/bin/python36

#Import libraries
import cgi
import json

#Debugging uncomment
#import cgitb
#cgitb.enable()

#Import helper library
from helper import *

#Get parameters
country = 'de'
location = 'Berlin'
searchString = 'experience perl'
includeOldResults = 'false'
arguments = cgi.FieldStorage()
if "Country" in arguments:
    country = arguments["Country"].value
if "Location" in arguments:
    location = arguments["Location"].value
if "SearchString" in arguments:
    searchString = arguments["SearchString"].value
if "IncludeOldResults" in arguments:
    includeOldResults = arguments["IncludeOldResults"].value

#Print a JSON header
print("Content-Type: text/json\n\n")

try:
    #Connect to the database
    db_con = connectToDatabase()
    db_cur = db_con.cursor()

    #Get the jobs and their ratings, optionally displaying jobs with ratings
    #print("Displaying jobs for " + country + location + searchString + includeOldResults)
    #TODO when multiple users this will return duplicate rows, need to add user_id to join
    jobs = []
    rows = db_cur.execute("""SELECT j.job_id, j.country, j.location, j.title, j.company, j.link, j.summary, j.posted, CASE WHEN r.rating IS NOT NULL THEN r.rating ELSE 0 END FROM jobs j INNER JOIN search_jobs sj ON j.job_id = sj.job_id INNER JOIN search s ON sj.search_id = s.search_id AND s.search_string = %s LEFT JOIN job_user_ratings r ON j.job_id = r.job_id WHERE j.country = %s AND j.location = %s ORDER BY j.posted DESC""", [searchString, country, location])
    rows = db_cur.fetchall()
    for row in rows:
        if row[8] == 0 or includeOldResults == "true":
            jobs.append([row[0], row[1], row[2], row[3], row[4], row[5], row[6], str(row[7]), row[8]])

    #Print the jobs array as JSON
    print(json.dumps(jobs, indent = 4))

    #Close the database connection
    db_cur.close()
    db_con.close()

except Exception as e:
    print(e)




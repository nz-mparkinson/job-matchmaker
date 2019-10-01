#!/usr/bin/python3

#Import libraries
import cgi
import json

#Debugging uncomment
#import cgitb
#cgitb.enable()

#Import helper library
from helper import *

#Get parameters
jobID = 'test'
rating = '3'
userID = 'me'
arguments = cgi.FieldStorage()
if "JobID" in arguments:
    jobID = arguments["JobID"].value
if "Rating" in arguments:
    rating = arguments["Rating"].value
if "UserID" in arguments:
    userID = arguments["UserID"].value

#Print a JSON header
print("Content-Type: text/json\n")

try:
    #Connect to the database
    db_con = connectToDatabase()
    db_cur = db_con.cursor()

    #Update a row for the rating
    db_cur.execute("""UPDATE job_user_ratings SET rating = %s WHERE job_id = %s AND user_id = %s""", [rating, jobID, userID]);
    #Insert a row if there was no existing rating
    if db_cur.rowcount is 0:
        db_cur.execute("""INSERT INTO job_user_ratings VALUES (%s, %s, %s)""", [jobID, userID, rating]);

    #Commit the database changes
    db_con.commit()

    #Print the arguments as JSON
    print(json.dumps([jobID, userID, rating], indent = 4))

    #Close the database connection
    db_cur.close()
    db_con.close()

except Exception as e:
    print(e)




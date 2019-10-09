#!/usr/bin/python3

#Import libraries
import os
import psycopg2
import yaml

#Declare static values
configFile = "/etc/job_matchmaker.conf"

#Declare the database connection settings with default values
databaseHost = "127.0.0.1"
databaseName = "job_matchmaker"
databaseUser = "postgres"
databasePassword = "postgres"

#Define the Job class
class Job:
    def __init__(self, jobID, country, location, title, company, link, summary):
        self.jobID = jobID
        self.country = country
        self.location = location
        self.title = title
        self.company = company
        self.link = link
        self.summary = summary
        self.posted = 0
        self.rating = 0

    #Set the Job Posted date
    def setPosted(self, posted):
        self.posted = posted

    #Set the Job Rating
    def setRating(self, rating):
        self.rating = rating

    #Get the Job as an array
    def toArray(self):
        return [self.jobID, self.country, self.location, self.title, self.company, self.link, self.summary]

#Connect to the database
def connectToDatabase():
    return psycopg2.connect(host = databaseHost, database = databaseName, user = databaseUser, password = databasePassword)



#If there is a settings file, open the file and load the settings
if os.path.exists(configFile):
    with open(configFile, 'r') as f:
        settings = yaml.load(f, Loader = yaml.FullLoader)
        databaseHost = settings["databaseHost"]
        databaseName = settings["databaseName"]
        databaseUser = settings["databaseUser"]
        databasePassword = settings["databasePassword"]




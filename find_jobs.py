#!/usr/bin/python36

#Import libraries
from bs4 import BeautifulSoup
import cgi
import json
import re
import urllib.request

#Debugging uncomment
#import cgitb
#cgitb.enable()

#TODO Indeed Python API?
#from indeed import IndeedClient
#client = IndeedClient(publisher = YOUR_PUBLISHER_NUMBER)

#Import helper library
from helper import *

#Declare search settings		#TODO move to database, create table settings
maxSearchCount = 500
minSearchTime = "30 minutes"

#Get a Job Description from its URL
def getJob(url):
    try:
        html = urllib.request.urlopen(url).read()
        soup = BeautifulSoup(html, 'html.parser')

        tags = soup.find_all('div')
        for tag in tags:
            #print("Tag ---" + str(tag))
            id = tag.get('id', None)
            className = tag.get('class', None)
            #print("ID ---" + str(id))
            #print("Class ---" + str(className))
            if id is not None and className is not None and id == "jobDescriptionText" and className == ['jobsearch-jobDescriptionText']:
                #print("Tag ---" + str(tag))
                #print("ID ---" + str(id))
                #print("Class ---" + str(className))
                print(tag)

    except Exception as e:
        print(e)
        pass

#Get a Job Company from inner HTML
def getJobCompany(innerHTML):
    #Try extract the company
    m = re.search('\n([^<]*).*$', innerHTML)
    if m:
        return m.group(1).lstrip()

    return ''

#Get a Job ID based on the url
def getJobID(url):
    #Try extract a jk number
    m = re.search('.+jk=([a-f0-9]*)\&.+', url)
    if m:
        return m.group(1)
    #Try extract a company number
    m = re.search('.+-([a-f0-9]*)\?.+', url)
    if m:
        return m.group(1)

    return ''

#Get a Job Posted date from inner HTML
def getJobPosted(innerHTML):
    #Try extract the posted date
    m = re.search('.*>(.*)<.*', innerHTML)
    if m:
        postedString = m.group(1)
        #TODO get date from string
        return postedString

    return ''

#Get a Job Summary from inner HTML
def getJobSummary(innerHTML):
    #Try remove all HTML tags
    innerHTML = innerHTML.replace("<div class=\"summary\">", "")
    innerHTML = innerHTML.replace("</div>", "")
    innerHTML = innerHTML.replace("<b>", "")
    innerHTML = innerHTML.replace("</b>", "")

    return innerHTML.lstrip()

#Get a list of Jobs from a URL
def getJobs(country, location, url):
    jobsFound = []

    #print(url)

    try:
        html = urllib.request.urlopen(url).read()
        soup = BeautifulSoup(html, 'html.parser')

        tags = soup.find_all('div')
        for tag in tags:
            #print("Tag ---" + str(tag))
            className = tag.get('class', None)
            #print("Class ---" + str(className))
            if className is not None and className == ['jobsearch-SerpJobCard', 'unifiedRow', 'row', 'result']:
                #print("Tag ---" + str(tag))
                #print("Class ---" + str(className))
                hyperLink = tag.find('a', {'class': 'jobtitle turnstileLink'})
                title = hyperLink.get('title', None)
                link = "https://de.indeed.com" + hyperLink.get('href', None)
                jobID = getJobID("https://de.indeed.com" + link)
                company = str(tag.find('span', {'class': 'company'}))
                company = getJobCompany(company)
                summary = str(tag.find('div', {'class': 'summary'}))
                summary = getJobSummary(summary)
                posted = str(tag.find('span', {'class': 'date'}))
                posted = getJobPosted(posted)

                #If the job isn't an ad
                if "pagead" not in link:
                    #print("Title: " + title)
                    #print("Company: " + company)
                    #print("Job ID: " + jobID)
                    #print("Link: " + link)
                    #print("Summary: " + summary)
                    #print("Posted: " + posted)
                    #getJob("https://de.indeed.com" + str(link))
                    jobsFound.append(Job(jobID, country, location, title, company, link, summary))

    except Exception as e:
        print(e)
        pass

    return jobsFound

#Search Indeed for Jobs
def searchJobs(db_con, db_cur, country, location, radius, searchString):
    searchJobsFound = []
    searchJobIDs = []
    searchID = country+""+location+""+searchString
    searchStringNoSpaces = searchString.replace(" ", "+")
    shouldSearch = 1

    #Get whether the should should be run based on how long its been since the last search
    rows = db_cur.execute("""SELECT CASE WHEN search_time + interval %s < current_timestamp THEN 1 ELSE 0 END FROM search WHERE search_id = %s""", [minSearchTime, searchID])
    rows = db_cur.fetchall() 
    if len(rows) > 0:
        shouldSearch = rows[0][0]

    #print([shouldSearch, minSearchTime, country, location, searchString])

    #If there was a recent search, skip the search
    #if not shouldSearch:
        #print("Search run recently, skipping")
    if shouldSearch:
        #Initial job search making sure the searchString doesn't contain spaces
        jobsFound = getJobs(country, location, "https://"+country+".indeed.com/jobs?q="+searchStringNoSpaces+"&l="+location+"&radius="+str(radius)+"&sort=date")

       #Get the old jobIDs from the searches table
        rows = db_cur.execute("""SELECT job_id FROM search_jobs WHERE search_id = %s ORDER BY 1""", [searchID])
        rows = db_cur.fetchall() 
        searchJobIDs = [row[0] for row in rows]
        #print("Old searches jobIDs:")
        #print(searchJobIDs)

        #While there are new jobs on the page and the maxSearchCount hasn't been exceeded
        added = -1
        count = 10
        while (added == -1 or added > 0) and count < maxSearchCount:
            added = 0

            #For each job, if the job ID hasn't been seen as part of a previous search with the same searchString, add the job to the jobs found as part of the search
            for job in jobsFound:
                if job.jobID not in searchJobIDs:
                    searchJobsFound.append(job)
                    searchJobIDs.append(job.jobID)
                    added += 1

            #If added is 0, break
            if added == 0:
                break

            #Try get the next page
            jobsFound = getJobs(country, location, "https://"+country+".indeed.com/jobs?q="+searchStringNoSpaces+"&l="+location+"&radius="+str(radius)+"&sort=date&start="+str(count))
            count += 10

        #print("New jobs found: " + str(len(searchJobsFound)))

        #For all the new search jobs, insert it into the searches table
        for job in searchJobsFound:
            #print(job.jobID + " - " + job.link)
            db_cur.execute("INSERT INTO search_jobs VALUES (%s, %s)", [searchID, job.jobID])

        #Update a row for the search
        db_cur.execute("""UPDATE search SET search_time = current_timestamp WHERE search_id = %s""", [searchID]);
        #Insert a row if there was no existing search
        if db_cur.rowcount is 0:
            db_cur.execute("""INSERT INTO search VALUES (%s, %s, %s, %s, current_timestamp)""", [searchID, country, location, searchString])

        #Commit the database changes
        db_con.commit()

    return searchJobsFound



#Get parameters, note: radius is always 100
country = 'de'
location = 'Berlin'
radius = 100
searchString = 'experience perl'
arguments = cgi.FieldStorage()
if "Country" in arguments:
    country = arguments["Country"].value
if "Location" in arguments:
    location = arguments["Location"].value
if "SearchString" in arguments:
    searchString = arguments["SearchString"].value

#Print a JSON header
print("Content-Type: text/json\n\n")

try:
    #Connect to the database
    db_con = connectToDatabase()
    db_cur = db_con.cursor()

    #Search for new jobs
    jobs = searchJobs(db_con, db_cur, country, location, radius, searchString)
    searchIDs = [job.jobID for job in jobs]
    #print("New jobs found: " + str(len(jobs)))

    #Get the old jobIDs
    rows = db_cur.execute("""SELECT job_id FROM jobs ORDER BY 1""")
    rows = db_cur.fetchall() 
    oldIDs = [row[0] for row in rows]
    #print("Old jobIDs:")
    #print(oldIDs)

    #For all the new jobs, if the job hasn't been seen before, insert it into the jobs table
    added = 0
    newIDs = []
    for job in jobs:
        if job.jobID not in oldIDs:
            db_cur.execute("INSERT INTO jobs VALUES (%s, %s, %s, %s, %s, %s, %s, current_timestamp)", (job.toArray()))
            newIDs.append(job.jobID)
            added += 1

    #Commit the database changes
    db_con.commit()

    #print("New jobs added: " + str(added))

    #Print the results as JSON
    print(json.dumps(["New jobs found: " + str(len(jobs)), "New jobs added: " + str(added), searchIDs, newIDs], indent = 4))

    #Close the database connection
    db_cur.close()
    db_con.close()

except Exception as e:
    print(e)




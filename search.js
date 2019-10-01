//Globals
var jobIDs = [];
var searches = 1;

//User settings
var country = '';
var includeOldResults = '';
var searchStrings = [];
var locations = [];
var radiuses = [];

//Call the function loadSettings() when the page is loaded
window.onload = loadSettings;

//Add an additional search
function addSearch(getUserSettings){
	//Get the user settings
	if(getUserSettings) getSettings();

	//If there are aren't too many searches, add another search
	if(searches < 11){
		searches += 1
		console.log("Adding search " + searches)

		//Add the row for the search
		var out = 
		`\t\t\t\t<tr id="search${searches}">\n` +
			`\t\t\t\t\t<td><input type="text" id="searchString${searches}" value="experience "></td>\n` +
			`\t\t\t\t\t<td><input type="text" id="location${searches}" value="Berlin"></td>\n` +
			`\t\t\t\t\t<td><input type="number" id="radius${searches}" value="100" max="100"></td>\n` +
			`\t\t\t\t\t<td class="found" id="found${searches}"></td>\n` +
		`\t\t\t\t</tr>\n`;
		document.getElementById("searches").innerHTML += out;

		//For all searches, restore their HTML values, note: don't need to restore values for newly created search
		for(var i = 1; i < searches; i++){
			document.getElementById("searchString" + i).value = searchStrings[i-1];
			document.getElementById("location" + i).value = locations[i-1];
			document.getElementById("radius" + i).value = radiuses[i-1];
		}
	}

	//Save the user settings
	if(getUserSettings) saveSettings();
}

//Find jobs
function findJobs(searchNumber, country, location, radius, searchStringNoSpaces, includeOldResults){
	//Create a XML web request to find_jobs.py and process the response
	var xhttp = new XMLHttpRequest();
	xhttp.onreadystatechange = function(){
		if (this.readyState == 4 && this.status == 200){
			var text = this.responseText;
			console.log(text);
			var json = JSON.parse(this.responseText);

			//Show the extra cell and set its value
			document.getElementById("found" + searchNumber).style.display = 'table-cell';
			document.getElementById("found" + searchNumber).innerHTML = json[1];

			//Display the jobs
			getJobs(country, location, radius, searchStringNoSpaces, includeOldResults);
		}
	};
	xhttp.open("GET", `python/find_jobs.py?Country=${country}&Location=${location}&Radius=${radius}&SearchString=${searchStringNoSpaces}`, true);
	xhttp.send();
}

//Get jobs
function getJobs(country, location, radius, searchStringNoSpaces, includeOldResults){
	//Create a XML web request to show_jobs.py and process the response
	var xhttp = new XMLHttpRequest();
	xhttp.onreadystatechange = function(){
		if (this.readyState == 4 && this.status == 200){
			getJobsProcessResponse(this);
		}
	};
	xhttp.open("GET", `python/show_jobs.py?Country=${country}&Location=${location}&Radius=${radius}&SearchString=${searchStringNoSpaces}&IncludeOldResults=${includeOldResults}`, true);
	xhttp.send();
}

//Process the response from getJobs, replacing the contents of the jobs table
function getJobsProcessResponse(response){
	var text = response.responseText;
	//console.log(text);
	var json = JSON.parse(response.responseText);
	
	var out = "";
	for(var i = 0; i < json.length; i++) {
		//If the jobID isn't already show, remember it and display the job
		if(!jobIDs.includes(json[i][0])){
			//Remember the jobID
			jobIDs.push(json[i][0]);

			//Add a row for the Job
			out += '\t\t\t<tr id ="' + json[i][0] + '">\n' +
			'\t\t\t\t<td><a href = "' + json[i][5] + '">'+ json[i][3] + '</a></td>\n' +
			'\t\t\t\t<td>' + json[i][4] + '</td>\n' +
			'\t\t\t\t<td>' + json[i][7] + '</td>\n' +
			'\t\t\t\t<td>' + json[i][6] + '</td>\n' +
			'\t\t\t\t<td>';
			for(var j = 1; j <= 5; j++){
				if(json[i][8] != j){
					out += `<button type="button" class="rate" onclick="rateJob('${json[i][0]}', ${j})">${j}</button>`
				}
				else{
					out += `<button type="button" class="rating">${j}</button>`
				}
			}
			out += '</td>\n' +
			'\t\t\t</tr>\n';
		}
	}
	document.getElementById("jobs").innerHTML += out;
}

//Get the user settings
function getSettings(){
	//Reset the search settings arrays
	searchStrings = [];
	locations = [];
	radiuses =[];

	//Get the country
	country = document.getElementById("country").value;
	//Get whether to include old results
	includeOldResults = document.getElementById("includeOldResults").checked;

	//For each search, get the info for the search
	for(var i = 1; i <= searches; i++){
		searchStrings[i-1] = document.getElementById("searchString" + i).value;
		locations[i-1] = document.getElementById("location" + i).value;
		radiuses[i-1] = document.getElementById("radius" + i).value;
	}

	console.log("Got settings");
}

//Load the user settings
function loadSettings(){
	//Load the user settings from the local storage
	var settings = JSON.parse(localStorage.getItem("settings"));
	
	//If there were settings to load
	if(settings !== null){
		//Load all settings
		if (typeof settings.country !== "undefined") country = settings.country;
		if (typeof settings.includeOldResults !== "undefined") includeOldResults = settings.includeOldResults;
		if (typeof settings.searchStrings !== "undefined") searchStrings = settings.searchStrings;
		if (typeof settings.locations !== "undefined") locations = settings.locations;
		if (typeof settings.radiuses !== "undefined") radiuses = settings.radiuses;

		console.log("checkbox is " + includeOldResults);
		//Update HTML values
		document.getElementById("country").value = country;
		if(includeOldResults == "true") document.getElementById("includeOldResults").checked = true;
		else document.getElementById("includeOldResults").checked = false;

		//Add required search boxes
		for(var i = searches; i < searchStrings.length; i++){
			addSearch(false);
		}

		//For all searches, update HTML values
		for(var i = 1; i <= searchStrings.length; i++){
			document.getElementById("searchString" + i).value = searchStrings[i-1];
			document.getElementById("location" + i).value = locations[i-1];
			document.getElementById("radius" + i).value = radiuses[i-1];
		}
	}

	console.log("Settings loaded");
}

//Rate a job
function rateJob(job_id, user_rating){
	//Create a XML web request to rate_job.py and process the response
	var xhttp = new XMLHttpRequest();
	xhttp.onreadystatechange = function(){
		if (this.readyState == 4 && this.status == 200){
			var text = this.responseText;
			console.log(text);
			var json = JSON.parse(this.responseText);

			//Remove the row for the job
			var element = document.getElementById(job_id);
			element.parentNode.removeChild(element);
		}
	};
	xhttp.open("GET", `python/rate_job.py?JobID=${job_id}&Rating=${user_rating}`, true);
	xhttp.send();
}

//Remove an additional search
function removeSearch(){
	//If there are additional searches to remove, remove the search
	if(searches > 1){
		console.log("Removing search " + searches)

		//Remove the row for the search
		var element = document.getElementById("search" + searches);
		element.parentNode.removeChild(element);

		searches -= 1
	}

	//Save the user settings
	saveSettings();
}

//Save the user settings
function saveSettings(){
	//Get the user settings
	getSettings();

	//Create a variable with all user settings
	var settings = {
		country: country,
		includeOldResults: String(includeOldResults),
		searchStrings: searchStrings,
		locations: locations,
		radiuses: radiuses,
	}

	//Save the user settings to the local storage
	localStorage.setItem("settings",JSON.stringify(settings));

	console.log("Settings saved");
	console.log(JSON.stringify(settings));
}

//Search
function search(){
	//Reset the jobIDs array
	jobIDs = [];

	//Reset the jobs table
	document.getElementById("jobs").innerHTML = "<td>Title</td><td>Company</td><td>Posted</td><td>Summary</td><td>Rate Job Match</td></tr>";

	//Save the user settings
	saveSettings();

	//For each search
	for(var i = 1; i <= searches; i++){
		//Hide the extra cell 
		document.getElementById("found" + i).style.display = 'none';
		document.getElementById("found" + i).innerHTML = '';

		console.log(`Searching using the following arguments: ${country} ${locations[i-1]} ${radiuses[i-1]} ${searchStrings[i-1]} ${includeOldResults}`);

		//Find the jobs
		var searchStringNoSpaces = searchStrings[i-1].trim().replace(" ", "+");
		findJobs(i, country, locations[i-1], radiuses[i-1], searchStringNoSpaces, includeOldResults);
	}
}




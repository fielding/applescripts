-- SkypeStalker - applescript stay-open application
-- Author: Fielding Johnston	
--
-- Purpose: Notifications for when a specific skype user comes online or goes offline
-- Be sure to save this as format type application and with the stay open option checked

global isRunning, isGrowlRunning, isSkypeRunning, currentlyOnline, username, contactIcon

on run
	
	-- check to see if growl is available for notifications
	tell application "System Events"
		set isGrowlRunning to (count of (every process whose name is "Growl")) > 0
		set isSkypeRunning to (count of (every process whose name is "Skype")) > 0
	end tell
	
	-- if growl is running, then register our script with it
	if isGrowlRunning then
		tell application "Growl"
			
			set the allNotificationsList to {"Alert"}
			set the enabledNotificationsList to {"Alert"}
			
			register as application "SkypeStalker" all notifications allNotificationsList Â
				default notifications enabledNotificationsList Â
				icon of application "Skype"
			
		end tell
	end if
	
	try
		contactIcon -- set if we've created the alias yet
	on error
		-- if not, create it in the error branch
		set contactIcon to (path to resource "contact.icns")
	end try
	
	try
		if username is missing value or username is "" then
			setUsername()
		else
			updateSettings()
		end if
	on error
		setUsername()
	end try
	
	-- get the current onlineStatus
	try
		set initStatus to getStatus(username)
		if initStatus is "ONLINE" or initStatus is "AWAY" or initStatus is "DND" or initStatus is "NA" then
			set currentlyOnline to true
		else
			set currentlyOnline to false
		end if
	end try
	
	-- set script running status to true
	set isRunning to true
end run

on idle
	
	set status to getStatus(username)
	
	if currentlyOnline = true then
		whileOnline(username, status)
	else if currentlyOnline = false then
		whileOffline(username, status)
	end if
	
	return 10
end idle

on reopen
	run
end reopen

on quit
	set isRunning to false
	continue quit
end quit

on getStatus(username)
	
	-- check skype for user's onlinestatus
	tell application "Skype"
		set onlineStatus to send command "GET USER " & username & " ONLINESTATUS" script name "getType"
	end tell
	
	-- Skype api reference for the ONLINESTATUS property of the USER object
	-- ONLINESTATUS - user online status, for example User username ONLINESTATUS.
	--  possible values:
	--    * UNKNOWN - unknown user
	--    * OFFLINE - user is offline (not connected). Will also be returned if current user is not authorized by other user to see his/her online status.
	--    * ONLINE - user is online.
	--    * AWAY - user is away (has been inactive for certain period).
	--    * NA - user is not available
	--    * DND - user is in "Do not disturb" mode.
	
	-- trim skype's return to just the status
	set status to word 4 of onlineStatus
	
	return status
end getStatus

on whileOffline(username, status)
	
	if status is "ONLINE" or status is "AWAY" or status is "DND" or status is "NA" then
		
		set message to username & " came online at " & (time string of (current date)) & " on " & (date string of (current date))
		growlAlert(message)
		set currentlyOnline to true
		
	else if status is "OFFLINE" then
		set currentlyOnline to false
	else
		--  takes care of UNKNOWN
		set currentlyOnline to false
	end if
	
end whileOffline

on whileOnline(username, status)
	
	if status is "ONLINE" or status is "AWAY" or status is "DND" or status is "NA" then
		set currentlyOnline to true
	else if status is "OFFLINE" then
		
		set message to username & " went offline at " & (time string of (current date)) & " on " & (date string of (current date))
		growlAlert(message)
		set currentlyOnline to false
		
	else
		--  takes care of UNKNOWN
		set currentlyOnline to false
	end if
	
end whileOnline

on growlAlert(message)
	
	if isGrowlRunning then
		tell application "Growl"
			notify with name Â
				"Alert" title Â
				"Alert" description Â
				message application name Â
				"SkypeStalker" with sticky
		end tell
	end if
	
end growlAlert

on setUsername()
	set usernameDialog to Â
		(display dialog Â
			"Enter the Skype username to watch" with title Â
			"SkypeStalker" default answer Â
			"" buttons {"Exit", "Start Stalking"} Â
			with icon contactIcon)
	
	if the button returned of usernameDialog is "Exit" then
		tell me to quit
		return
	else
		set username to the text returned of usernameDialog
		return
	end if
end setUsername

on updateSettings()
	set updateSettingsDialog to (display dialog Â
		"Currently stalking: " & username with title Â
		"SkypeStalker" buttons {"Exit", "Change Prey", "Continue Stalking"} Â
		with icon contactIcon)
	
	if the button returned of updateSettingsDialog is "Exit" then
		quit
		return
	else if the button returned of updateSettingsDialog is "Change Prey" then
		setUsername()
		return
	else if the button returned of updateSettingsDialog is "Continue Stalking" then
		return
	end if
end updateSettings

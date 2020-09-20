-- addon notifies the player when somebody enters or leaves the sector

spuck = spuck or {}

local MODE_NONE = 0
local MODE_PLAYER = 1
local MODE_ALL = 2

local mode_patterns = {}
mode_patterns[MODE_PLAYER] = "^[^*]"
mode_patterns[MODE_ALL] = ""


local SOUND_OFF = 0
local SOUND_ENTERED = 1
local SOUND_LEFT = 2
local SOUND_BOTH = 3

local alert = ""
local range = 0
enterleave = {}
enterleave.newchars = {}
enterleave.knownchars = {}
enterleave.message = {}
enterleave.soundtimer = {}
enterleave.launched = false
enterleave.version = "1.10"


-- get settings
local notify_mode = gkini.ReadInt("*enterleave", "notification_mode", MODE_PLAYER)
local notify_mode_pattern = mode_patterns[notify_mode]

local sound = gkini.ReadInt("*enterleave", "sound", SOUND_ENTERED)
local patterns = unspickle(gkini.ReadString("*enterleave", "patterns", ""))

gksound.GKLoadSound{soundname="entersector", filename="plugins/enterleave/sounds/enter sector.ogg"}
gksound.GKLoadSound{soundname="leavesector", filename="plugins/enterleave/sounds/leave sector.ogg"}
gksound.GKLoadSound{soundname="redalert", filename="plugins/enterleave/sounds/red alert.ogg"}
gksound.GKLoadSound{soundname="yellowalert", filename="plugins/enterleave/sounds/yellow alert.ogg"}
gksound.GKLoadSound{soundname="fighteralert", filename="plugins/enterleave/sounds/fighter alert.ogg"}
gksound.GKLoadSound{soundname="sonaralert", filename="plugins/enterleave/sounds/sonar alert.ogg"}

function enterleave:GetAlert(name,charid)

	local function buildalert(facnum,charid)
		alert = alert..rgbtohex(FactionColor_RGB[facnum])..FactionName[facnum].." "..rgbtohex(factionfriendlynesscolor(GetPlayerFactionStanding(facnum,charid)))..factionfriendlyness(GetPlayerFactionStanding(facnum,charid)).." "..FactionToSignedFaction(GetPlayerFactionStanding(facnum,charid)).." "
		return alert
	end

	if GetGuildTag(charid) ~= "" then
		alert = "\127ffffff ["..GetGuildTag(charid).."] "
	else alert = ""
	end

	alert = alert..rgbtohex(FactionColor_RGB[GetPlayerFaction(charid)])..name.." "

--[[unfortunately this function will only return the license level of yourself, not other players
	alert = alert.."\127ffffff"..GetLicenseLevel(1,charid).."/"..GetLicenseLevel(2,charid).."/"..GetLicenseLevel(3,charid).."/"..GetLicenseLevel(4,charid).."/"..GetLicenseLevel(5,charid).." "
]]
	if GetPlayerFactionStanding(1,charid) then
		if GetPlayerFaction(charid) == 1 then
			buildalert(1,charid) buildalert(2,charid) buildalert(3,charid)
		elseif GetPlayerFaction(charid) == 2 then
			buildalert(2,charid) buildalert(1,charid) buildalert(3,charid)
		elseif GetPlayerFaction(charid) == 3 then
			buildalert(3,charid) buildalert(1,charid) buildalert(2,charid)
		end
	end
	alert = alert.."\127ffffff "

	if GetPrimaryShipNameOfPlayer(charid) then
		alert = alert.."piloting "..GetPrimaryShipNameOfPlayer(charid)
	end

	if GetCharacterKillDeaths(charid) then
		if select(3,GetCharacterKillDeaths(charid)) == 0 then
			alert = alert.."\127ffffff"
		else alert = alert.."\127ff0000"
		end
		alert = alert.." PK's: "..select(3,GetCharacterKillDeaths(charid))
	end

	return alert
end

function enterleave.fighteralert()
	if sound == SOUND_ENTERED or sound == SOUND_BOTH then
		gksound.GKPlaySound("fighteralert")
		HUD:PrintSecondaryMissionMsg("fighteralert")
	end
end

function enterleave.yellowalert()
	if sound == SOUND_ENTERED or sound == SOUND_BOTH then
		gksound.GKPlaySound("yellowalert")
		HUD:PrintSecondaryMissionMsg("yellowalert")
	end
end

function enterleave.redalert()
	if sound == SOUND_ENTERED or sound == SOUND_BOTH then
		gksound.GKPlaySound("redalert")
		HUD:PrintSecondaryMissionMsg("redalert")
	end
end

function enterleave.sonaralert()
	if sound == SOUND_ENTERED or sound == SOUND_BOTH then
		gksound.GKPlaySound("sonaralert")
		HUD:PrintSecondaryMissionMsg("sonaralert")
	end
end

function enterleave.doalert()

	while ( #enterleave.soundtimer > 0 ) and ( not enterleave.soundtimer[1]:IsActive() ) do
		table.remove (enterleave.soundtimer, 1)
	end

	if #enterleave.message > 0 then
		if sound == SOUND_ENTERED or sound == SOUND_BOTH then gksound.GKPlaySound("entersector") end
		alert = enterleave.message[1].alert
		local charid = enterleave.message[1].charid
		local range = GetPlayerDistance(charid)
		print('range =')
		print(range)
		if GetPlayerHealth(charid) > 0 then
			alert = alert.." at "..rgbtohex(string.sub(calc_health_color(math.ceil(GetPlayerHealth(charid))/100),1,string.find(calc_health_color(math.ceil(GetPlayerHealth(charid))/100)," 255 *",1,true)-1))..math.ceil(GetPlayerHealth(charid)).."% health "
		end
		if range then
			range = math.floor(range + .5)
			if range <= GetProximityWarningDistance() then
				alert = alert.." \127ff0000"
			else
				alert = alert.." \127ffffff"
			end
			alert = alert..range.."m"
		end

		if GetPrimaryShipNameOfPlayer(charid) and tcs.mf.GetFriendlyStatus(charid) == 0 then
			if string.match(GetPrimaryShipNameOfPlayer(charid),"Valk") or
				string.match(GetPrimaryShipNameOfPlayer(charid),"Centurion") or
				string.match(GetPrimaryShipNameOfPlayer(charid),"Vult") or
				string.match(GetPrimaryShipNameOfPlayer(charid),"Wart") or
				string.match(GetPrimaryShipNameOfPlayer(charid),"Grey")
			then
				enterleave.soundtimer[#enterleave.soundtimer+1] = Timer()
				enterleave.soundtimer[#enterleave.soundtimer]:SetTimeout(1720, function() enterleave.fighteralert() end)
					if range and range <= GetProximityWarningDistance() then
						enterleave.soundtimer[#enterleave.soundtimer+1] = Timer()
						enterleave.soundtimer[#enterleave.soundtimer]:SetTimeout(2680, function() enterleave.redalert() end)
					elseif range then
						enterleave.soundtimer[#enterleave.soundtimer+1] = Timer()
						enterleave.soundtimer[#enterleave.soundtimer]:SetTimeout(2680, function() enterleave.yellowalert() end)
					end
			elseif
				string.match(GetPrimaryShipNameOfPlayer(charid),"Behe") or
				string.match(GetPrimaryShipNameOfPlayer(charid),"Atlas") or
				string.match(GetPrimaryShipNameOfPlayer(charid),"Centaur") or
				string.match(GetPrimaryShipNameOfPlayer(charid),"EC-") then
				if range and range <= GetProximityWarningDistance() then
					enterleave.soundtimer[#enterleave.soundtimer+1] = Timer()
					enterleave.soundtimer[#enterleave.soundtimer]:SetTimeout(1720, function() enterleave.sonaralert() end)
				end
			else
				if range and range <= GetProximityWarningDistance() then
					enterleave.soundtimer[#enterleave.soundtimer+1] = Timer()
					enterleave.soundtimer[#enterleave.soundtimer]:SetTimeout(1720, function() enterleave.yellowalert() end)
				end
			end
		end

		alert = alert.." \127ffffff "
		if enterleave.message[1].launched then
			alert = alert.."has undocked"
		else
			alert = alert.."has entered the sector"
		end

		print (alert)
		HUD:PrintSecondaryMissionMsg(alert)
		if enterleave.message[1].timer:IsActive() then enterleave.message[1].timer:Kill() end
		table.remove (enterleave.message, 1)
	end
end

function enterleave:EnterNotify(name,charid)
	alert = enterleave:GetAlert(name,charid)
	enterleave.message[#enterleave.message + 1] = {}
	enterleave.message[#enterleave.message].alert = alert
	enterleave.message[#enterleave.message].charid = charid
	if enterleave.launched then
		enterleave.message[#enterleave.message].launched = true
		enterleave.launched = false
	end
	enterleave.message[#enterleave.message].timer = Timer()
	enterleave.message[#enterleave.message].timer:SetTimeout(1000, function() enterleave.doalert() end)
end

function enterleave:LeaveNotify(name,charid)
	if GetPlayerFactionStanding(1,charid) then
		alert = enterleave:GetAlert(name,charid)
		alert = alert.."\127ffffff has left the sector"
		if not enterleave.launched then
			if sound == SOUND_LEFT or sound == SOUND_BOTH then gksound.GKPlaySound("leavesector") end
			print(alert)
			HUD:PrintSecondaryMissionMsg(alert)
		end
	else enterleave.launched = true
	end
end

function enterleave:OnEvent(event, data)
	local function isname(name, charid)
		return not (name == "(reading transponder "..charid..")")
	end

	local function matches_pattern(name)
		-- check if mode is valid and return true if it matches
		if notify_mode_pattern and name:match(notify_mode_pattern) then
			return true
		end
	end

	local function matches_custom_pattern(name)
		for _,pattern in ipairs(patterns) do
			if name:match(pattern) then return true end
		end
	end
----------------------------------
	if event=="PLAYER_ENTERED_GAME" then
		print("EnterLeave v"..enterleave.version.." /el")
	end

	local playername = GetPlayerName(data) or "none"
--------------------------------------
	if event == "PLAYER_ENTERED_SECTOR" then
		-- don't do anything if the char is the player or sector
		if data == GetCharacterID() or data == 0 then
			return
		end

		if self.knownchars[data] then
			return
		end
		self.knownchars[data] = true


		if isname(playername, data) then
			if matches_custom_pattern(playername) or matches_pattern(playername) then
				self:EnterNotify(playername,data)
			end
		else
			-- if this is not a name put it into newplayer table and wait for updates
			self.newchars[data] = true
		end
	end
-----------------------------------
	if event == "PLAYER_LEFT_SECTOR" then
		-- do nothing if it's the sector (not sure if this actually happens)
		if data == 0 then return end

		-- if the player still has a node id he didn't actually leave
		-- caused by spurious events when players undock and storm sector
		if GetPlayerNodeID(data) then
		print("this is where we set launched")
			return
		end
		self.knownchars[data] = nil

		if isname(playername, data) then
			-- clear temporary char list when the player leaves sector. In case some names got lost
			if data == GetCharacterID() then 
				self.newchars = {}
				self.knownchars = {}
			-- pattern matching
			elseif matches_custom_pattern(playername) or matches_pattern(playername)  then
				self:LeaveNotify(playername,data)
			end
		end

		self.newchars[data] = nil
	end
--------------------------------
	if event == "UPDATE_CHARINFO" then
		if self.newchars[data] then
			-- still don't have name so leave it in the table
			if isname(playername, data) then
				self.newchars[data] = nil

				if matches_custom_pattern(playername) or matches_pattern(playername) then
					self:EnterNotify(playername,data)
				end
			end
		end
	end
------------------------------
	if event == "SECTOR_LOADED" then
		for i in pairs(self.newchars) do
			playername = GetPlayerName(i) or "none"
			if isname(playername, i) then
				self.newchars[i] = nil

				if matches_custom_pattern(playername) or matches_pattern(playername) then
					self:EnterNotify(playername,data)
				end
			end
		end
	end
-------------------------------------
	if event == "PLAYER_STATS_UPDATED" then
		print(event)
		print(data)
	end
-----------------------------
	if event == "SHIP_SPAWNED" then
	end
end

RegisterEvent(enterleave, "PLAYER_ENTERED_GAME")
RegisterEvent(enterleave, "PLAYER_ENTERED_SECTOR")
RegisterEvent(enterleave, "PLAYER_LEFT_SECTOR")
RegisterEvent(enterleave, "UPDATE_CHARINFO")
RegisterEvent(enterleave, "SECTOR_LOADED")
RegisterEvent(enterleave, "SHIP_SPAWNED")
RegisterEvent(enterleave, "PLAYER_UPDATE_STATS")
RegisterEvent(enterleave, "PLAYER_STATS_UPDATED")
RegisterEvent(enterleave, "ENTERED_STATION")
RegisterEvent(enterleave, "HUD_SHOW")
RegisterEvent(enterleave, "PLAYER_LOGGED_OUT")
RegisterEvent(enterleave, "ENTER_ZONE_dock")


local function enterleave_func(_, args)
	print("usage:")
	print("Notifications")
	print("/elm <number> 0 = no notification 1 = only players 2 = everything")
	print("Sound")
	print("/els <number> 0 = off 1 = enter 2 = leave 3 = both")
	print("Search")
	print("/elp <string> pattern search string")
end
RegisterUserCommand("enterleave", enterleave_func)
RegisterUserCommand("el", enterleave_func)

local function notifymode_func(_, args)
	if args and args[1] then 
		local mode = tonumber(args[1]) or notify_mode
		gkini.WriteInt("*enterleave", "notification_mode", mode)
		notify_mode = mode
		notify_mode_pattern = mode_patterns[mode]
	else
		print("usage: /elm <number>\n 0 = no notification\n 1 = only players\n 2 = everything")
	end 
end
RegisterUserCommand("elm", notifymode_func)

local function pattern_func(_, args)
	if args and args[1] then 
		gkini.WriteString("*enterleave", "patterns", spickle(args))
		patterns = args
	else
		gkini.WriteString("*enterleave", "patterns", "")
		patterns = {}
	end
end
RegisterUserCommand("elp", pattern_func)

local function sound_func(_, args)
	if args and args[1] then 
		local mode = tonumber(args[1]) or sound
		gkini.WriteInt("*enterleave", "sound", mode)
		sound = mode
	else
		print("usage: /els <number>\n 0 = off\n 1 = enter\n 2 = leave\n 3 = both")
	end 
end
RegisterUserCommand("els", sound_func)

spuck.enterleave = enterleave
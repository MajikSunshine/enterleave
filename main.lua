DME = {}
DME.version = "1.2"
DMEtimer = Timer()

DMEPBH = iup.stationprogressbar{
	visible = "YES",
	active = "NO",
	minvalue = 200,
	maxvalue = 500,
	uppercolor = "0 255 0",
	lowercolor = "0 128 255",
	RASTERSIZE = "100x15",
	ORIENTATION = "VERTICAL",
	}

DMEPBL = iup.stationprogressbar{
	visible = "YES",
	active = "NO",
	minvalue = 0,
	maxvalue = 200,
	uppercolor = "0 255 0",
	lowercolor = "0 128 255",
	RASTERSIZE = "100x15",
	ORIENTATION = "VERTICAL",
	}

DMEbox = iup.hbox{
	DMEPBH,
	DMEPBL,
	MARGIN = "x60",
	}

DMEframe = 	iup.frame{
	iup.hbox{
		iup.fill{},
		DMEPBH,
		DMEPBL,
		iup.fill{},
	},
EXPAND = "YES",
TITLE = "DMEframe",
}

DMEdialog = iup.dialog{
	DMEframe,
	close,
--	FULLSCREEN = "NO",
	EXPAND = "NO",
--	RESIZE = "NO",
--	SIZE = 'QUARTERxQUARTER',
	TITLE = "DMEdialog",
	defaultesc = close,
}

function DME.cmd ()
	DMEupdate()
	print ("Welcome to DME")
	if DMEdialog.visible == "YES" then
		HideDialog(DMEdialog)
	else iup.Show(DMEdialog, iup.CENTER, iup.CENTER)
	end
end

RegisterUserCommand('dme', DME.cmd)

function DME:OnEvent(event, data)
	if event == "PLAYER_ENTERED_GAME" then
		print ("DME v"..DME.version)
		iup.Append(HUD.distancebar, DMEbox)
		DMEupdate()
	end
	if event == "PLAYER_LOGGED_OUT" then
		DMEtimer:Kill()
		DMEPBH.lowercolor = "0 128 255"
		DMEPBL.lowercolor = "0 128 255"
		iup.Refresh(HUD.distancebar)
	end
	
	if event == "TARGET_CHANGED" or "TERMINATE" then
		DMEupdate()	
	end
	
	if event == "TARGET_HEALTH_UPDATE" then
		print("TARGET_HEALTH_UPDATE event encountered")
		print(GetTargetDistance())
	end
end

RegisterEvent(DME, "PLAYER_ENTERED_GAME")
RegisterEvent(DME, "PLAYER_LOGGED_OUT")
RegisterEvent(DME, "TARGET_CHANGED")
RegisterEvent(DME, "TERMINATE")

function DMEupdate()
	if GetTargetDistance() then
		DMEPBH.lowercolor = "255 0 0"
		DMEPBH.uppercolor = "0 255 0"
		DMEPBH.value = GetTargetDistance()
		DMEPBL.lowercolor = "0 255 0"
		DMEPBL.uppercolor = "255 0 0"
		DMEPBL.value = GetTargetDistance()
		DMEtimer:SetTimeout(20, function() DMEupdate() end)
	else
		if DMEtimer:IsActive() then DMEtimer:Kill() end
		DMEPBH.uppercolor = "0 128 255"
		DMEPBH.value = 0
		DMEPBL.lowercolor = "0 128 255"
		DMEPBL.value = 200
	end
	iup.Refresh(HUD.distancebar)
end




function carexplosion()
toggleVehicleRespawn (source, false)
setTimer(destroyElement, 5000, 1, source)
end
addEventHandler ("onVehicleExplode", getResourceRootElement(getThisResource()), carexplosion)
local g_PlayerData = {}
local g_VehicleData = {}
local chatTime = {}
local lastChatMessage = {}

g_ArmedVehicles = {
	[425] = true,
	[447] = true,
	[520] = true,
	[430] = true,
	[464] = true,
	[432] = true
}
g_Trailers = {
	[606] = true,
	[607] = true,
	[610] = true,
	[590] = true,
	[569] = true,
	[611] = true,
	[584] = true,
	[608] = true,
	[435] = true,
	[450] = true,
	[591] = true
}

g_RPCFunctions = {
	addPedClothes = { option = 'clothes', descr = 'Modifying clothes' },
	addVehicleUpgrade = { option = 'upgrades', descr = 'Adding/removing upgrades' },
	fadeVehiclePassengersCamera = true,
	fixVehicle = { option = 'repair', descr = 'Repairing vehicles' },
	giveMeVehicles = { option = 'createvehicle', descr = 'Creating vehicles' },
	giveMeWeapon = { option = 'weapons.enabled', descr = 'Getting weapons' },
	givePedJetPack = { option = 'jetpack', descr = 'Getting a jetpack' },
	removePedClothes = { option = 'clothes', descr = 'Modifying clothes' },
	removePedFromVehicle = true,
	removePedJetPack = { option = 'jetpack', descr = 'Removing a jetpack' },
	removeVehicleUpgrade = { option = 'upgrades', descr = 'Adding/removing upgrades' },
	setElementAlpha = { option = 'alpha', descr = 'Changing your alpha' },
	setElementInterior = true,
	setMySkin = { option = 'setskin', descr = 'Setting skin' },
	setPedAnimation = { option = 'anim', descr = 'Setting an animation' },
	setPedWalkingStyle = { option = 'walkstyle', descr = 'Setting walking style' },
	setPedFightingStyle = { option = 'setstyle', descr = 'Setting fighting style' },
	setPedGravity = { option = 'gravity.enabled', descr = 'Setting gravity' },
	setPedStat = { option = 'stats', descr = 'Changing stats' },
	setVehicleColor = true,
	setVehicleHeadLightColor = true,
	setVehicleOverrideLights = { option = 'lights', descr = 'Forcing lights' },
	setVehiclePaintjob = { option = 'paintjob', descr = 'Applying paintjobs' },
	spawnMe = true,
	warpMe = { option = 'warp', descr = 'Warping' },
	setMyPos = true
}

g_OptionDefaults = {
	alpha = true,
	anim = true,
	clothes = true,
	createvehicle = true,
	gamespeed = {
		enabled = true,
		min = 0.0,
		max = 3
	},
	gravity = {
		enabled = true,
		min = 0,
		max = 0.1
	},
	jetpack = true,
	kill = true,
	lights = true,
	paintjob = true,
	repair = true,
	setskin = true,
	walkstyle= true,
	setstyle = true,
	spawnmaponstart = true,
	spawnmapondeath = true,
	stats = true,
	time = {
		set = true,
		freeze = true
	},
	upgrades = true,
	warp = true,
	weapons = {
		enabled = true,
		vehiclesenabled = true,
		disallowed = {},
		kniferestrictions = true
	},
	weather = true,
	welcometextonstart = true,
	vehicles = {
		maxidletime = 60000,
		idleexplode = true,
		maxperplayer = 2,
		disallowed = {}
	}
}

function getOption(optionName)
	local option = get(optionName:gsub('%.', '/'))
	if option then
		if option == 'true' then
			option = true
		elseif option == 'false' then
			option = false
		end
		return option
	end
	option = g_OptionDefaults
	for i,part in ipairs(optionName:split('.')) do
		option = option[part]
	end
	return option
end

addEventHandler('onResourceStart', resourceRoot,
	function()
		table.each(getElementsByType('player'), joinHandler)
	end
)

function onLocalSettingChange(setting,value)

	if client ~= source then return end
	g_PlayerData[client].settings[setting] = value
	triggerClientEvent("onClientFreeroamLocalSettingChange",client,setting,value)

end

function joinHandler(player)
	if not player then
		player = source
	end
	local r, g, b = math.random(50, 255), math.random(50, 255), math.random(50, 255)
	setPlayerNametagColor(player, r, g, b)
	g_PlayerData[player] = { vehicles = {}, settings={} }
	g_PlayerData[player].blip = createBlipAttachedTo(player, 0, 2, r, g, b)
	addEventHandler("onFreeroamLocalSettingChange",player,onLocalSettingChange)
	if getOption('welcometextonstart') then
		--outputChatBox('DogukanSkill F1 panel Başlatıldı', player, 255,255,225, true)
      	end
end
addEventHandler('onPlayerJoin', root, joinHandler)

local settingsToSend =
{
	["command_spam_protection"] = true,
	["tries_required_to_trigger"] = true,
	["tries_required_to_trigger_low_priority"] = true,
	["command_spam_ban_duration"] = true,
	["command_exception_commands"] = true,
	["removeHex"] = true,
	["spawnmapondeath"] = true,
	["weapons/kniferestrictions"] = true,
	["kill"] = true,
	["warp"] = true,
	["gamespeed/enabled"] = true,
	["gamespeed/min"] = true,
	["gamespeed/max"] = true,
	["gui/antiram"] = true,
	["gui/disablewarp"] = true,
	["gui/disableknife"] = true,
}

local function updateSettings()

	local settings = {}
	for setting,_ in pairs(settingsToSend) do settings[setting] = getOption(setting) end
	return settings

end

local function sendSettings(player,settingPlayer,settings)

	for setting,value in pairs(settings) do
		triggerClientEvent(player,"onClientFreeroamLocalSettingChange",settingPlayer,setting,value)
	end

end

addEvent('onLoadedAtClient', true)
addEventHandler('onLoadedAtClient', resourceRoot,
	function()
		local settings = updateSettings()
		clientCall(client, 'freeroamSettings', settings)
		for player,data in pairs(g_PlayerData) do
			if player ~= client then
				local settings = data.settings
				setTimer(sendSettings,1500,1,client,player,settings)
			end
		end
	end,
	false
)

function onSettingChange(key,_,new)

	if not settingsToSend[gettok(key,#split(key,"."),".")] then return end
	local settings = updateSettings()
	for index,player in ipairs(getElementsByType("player")) do
		clientCall(player, 'freeroamSettings', settings)
	end

end

addEventHandler("onSettingChange",root,onSettingChange)

function showMap(player)

	if isPedDead(player) then
		clientCall(player, "showMap")
	end

end

addEvent('onClothesInit', true)
addEventHandler('onClothesInit', resourceRoot,
	function()
		local result = {}
		local texture, model
		-- get all clothes
		result.allClothes = {}
		local typeGroup, index
		for type=0,17 do
			typeGroup = {'group', type = type, name = getClothesTypeName(type), children = {}}
			table.insert(result.allClothes, typeGroup)
			index = 0
			texture, model = getClothesByTypeIndex(type, index)
			while texture do
				table.insert(typeGroup.children, {id = index, texture = texture, model = model})
				index = index + 1
				texture, model = getClothesByTypeIndex(type, index)
			end
		end
		-- get current player clothes { type = {texture=texture, model=model} }
		result.playerClothes = {}
		for type=0,17 do
			texture, model = getPedClothes(client, type)
			if texture then
				result.playerClothes[type] = {texture = texture, model = model}
			end
		end
		triggerClientEvent(client, 'onClientClothesInit', resourceRoot, result)
	end
)

function warpMe(targetPlayer)
	if isPedDead(source) then
		spawnMe()
	end

	local vehicle = getPedOccupiedVehicle(targetPlayer)
	local interior = getElementInterior(targetPlayer)
	if not vehicle then
		-- target player is not in a vehicle - just warp next to him
		local x, y, z = getElementPosition(targetPlayer)
		clientCall(source, 'setPlayerPosition', x + 2, y, z)
		setElementInterior(source, interior)
		setCameraInterior(source, interior)
	else
		-- target player is in a vehicle - warp into it if there's space left
		if getPedOccupiedVehicle(source) then
			--removePlayerFromVehicle(source)
			outputChatBox('Aractan inmelisin.', source)
			return
		end
		local numseats = getVehicleMaxPassengers(vehicle)
		for i=0,numseats do
			if not getVehicleOccupant(vehicle, i) then
				if isPedDead(source) then
					local x, y, z = getElementPosition(vehicle)
					spawnMe(x + 4, y, z + 1)
				end
				setElementInterior(source, interior)
				setCameraInterior(source, interior)
				warpPedIntoVehicle(source, vehicle, i)
				return
			end
		end
	end
end

addEvent('onPlayerGravInit', true)
addEventHandler('onPlayerGravInit', root,
	function()
		if client ~= source then return end
		triggerClientEvent(client, 'onClientPlayerGravInit', client, getPedGravity(client))
	end
)

function setMySkin(skinid)
	if getElementModel(source) == skinid then return end
	if isPedDead(source) then
		local x, y, z = getElementPosition(source)
		if isPedTerminated(source) then
			x = 0
			y = 0
			z = 3
		end
		local r = getPedRotation(source)
		local interior = getElementInterior(source)
		spawnPlayer(source, x, y, z, r, skinid)
		setElementInterior(source, interior)
		setCameraInterior(source, interior)
	else
		setElementModel(source, skinid)
	end
	setCameraTarget(source, source)
	setCameraInterior(source, getElementInterior(source))
end

function spawnMe(x, y, z)
	if not x then
		x, y, z = getElementPosition(source)
	end
	if isPedTerminated(source) then
		repeat until spawnPlayer(source, x, y, z, 0, math.random(9, 288))
	else
		spawnPlayer(source, x, y, z, 0, getPedSkin(source))
	end

	setCameraTarget(source, source)
	setCameraInterior(source, getElementInterior(source))
end

addCommandHandler("isinlanma",function(thePlayer)
    local WarpDurum = getElementData(thePlayer,"Warp")
    if not WarpDurum then
	    setElementData(thePlayer,"Warp",true)
		outputChatBox("#f7941eIşınlanma #FF0000Kapalı.", thePlayer, 255, 0, 0, true)
	else
	    setElementData(thePlayer,"Warp",false)
		outputChatBox("#f7941eIşınlanma #33FF00Aktif.", thePlayer, 0, 255, 0, true)		
	end
end)

function warpMeIntoVehicle(vehicle)

	if not isElement(vehicle) then return end

	if isPedDead(source) then
		spawnMe()
	end

	if getPedOccupiedVehicle(source) then
		outputChatBox('Get out of your vehicle first.', source, 255,0,0)
		return
	end
	local interior = getElementInterior(vehicle)
	local numseats = getVehicleMaxPassengers(vehicle)
	local driver = getVehicleController(vehicle)
	for i=0,numseats do
		if not getVehicleOccupant(vehicle, i) then
			if isPedDead(source) then
				local x, y, z = getElementPosition(vehicle)
				spawnMe(x + 4, y, z + 1)
			end
			setElementInterior(source, interior)
			setCameraInterior(source, interior)
			warpPedIntoVehicle(source, vehicle, i)
			return
		end
	end
	if isElement(driver) then
		outputChatBox('No free seats left in ' .. getPlayerName(driver) .. '\'s vehicle.', source, 255, 0, 0)
	end

end

local sawnoffAntiAbuse = {}
function giveMeWeapon(weapon, amount)
	if table.find(getOption('weapons.disallowed'), weapon) then
		errMsg((getWeaponNameFromID(weapon) or tostring(weapon)) .. 's are not allowed', source)
	else
		giveWeapon(source, weapon, amount, true)
		if weapon == 26 then
			if not sawnoffAntiAbuse[source] then
				setControlState (source, "aim_weapon", false)
				setControlState (source, "fire", false)
				toggleControl (source, "fire", false)
				reloadPedWeapon (source)
				sawnoffAntiAbuse[source] = setTimer (function(source)
					if not source then return end
					toggleControl (source, "fire", true)
					sawnoffAntiAbuse[source] = nil
				end, 3000, 1, source)
			end
        end
	end
end

function giveMeVehicles(vehicles)
	if type(vehicles) == 'number' then
		vehicles = { vehicles }
	end

	local px, py, pz, prot
	local radius = 3
	local playerVehicle = getPedOccupiedVehicle(source)
	if playerVehicle and isElement(playerVehicle) then
		px, py, pz = getElementPosition(playerVehicle)
		prot, prot, prot = getVehicleRotation(playerVehicle)
	else
		px, py, pz = getElementPosition(source)
		prot = getPedRotation(source)
	end
	local offsetRot = math.rad(prot)
	local vx = px + radius * math.cos(offsetRot)
	local vy = py + radius * math.sin(offsetRot)
	local vz = pz + 2
	local vrot = prot

	local vehicleList = g_PlayerData[source].vehicles
	local vehicle
	if ( not vehicles ) then return end
	for i,vehID in ipairs(vehicles) do
		if i > getOption('vehicles.maxperplayer') then
			break
		end
		if vehID < 400 or vehID > 611 then
			errMsg(vehID ..' is incorrect vehicle model', source)
		elseif not table.find(getOption('vehicles.disallowed'), vehID) then
			if #vehicleList >= getOption('vehicles.maxperplayer') then
				unloadVehicle(vehicleList[1])
			end
			vehicle = createVehicle(vehID, vx, vy, vz, 0, 0, vrot)
			setElementData(vehicle,"Plaka","FREE")
			if (not isElement(vehicle)) then return end
			setElementInterior(vehicle, getElementInterior(source))
			setElementDimension(vehicle, getElementDimension(source))
			table.insert(vehicleList, vehicle)
			g_VehicleData[vehicle] = { creator = source, timers = {} }
			if vehID == 464 then
				warpPedIntoVehicle(source, vehicle)
			elseif not g_Trailers[vehID] then
				if getOption('vehicles.idleexplode') then
					g_VehicleData[vehicle].timers.fire = setTimer(commitArsonOnVehicle, getOption('vehicles.maxidletime'), 1, vehicle)
				end
				g_VehicleData[vehicle].timers.destroy = setTimer(unloadVehicle, getOption('vehicles.maxidletime') + (getOption('vehicles.idleexplode') and 10000 or 0), 1, vehicle)
			end
			vx = vx + 4
			vz = vz + 4
		else
			errMsg(getVehicleNameFromModel(vehID):gsub('y$', 'ie') .. 's are not allowed', source)
		end
	end
end

_setPlayerGravity = setPedGravity
function setPedGravity(player, grav)
	if grav < getOption('gravity.min') then
		errMsg(('Minimum allowed gravity is %.5f'):format(getOption('gravity.min')), player)
	elseif grav > getOption('gravity.max') then
		errMsg(('Maximum allowed gravity is %.5f'):format(getOption('gravity.max')), player)
	else
		_setPlayerGravity(player, grav)
	end
end

function fadeVehiclePassengersCamera(toggle)
	local vehicle = getPedOccupiedVehicle(source)
	if not vehicle then
		return
	end
	local player
	for i=0,getVehicleMaxPassengers(vehicle) do
		player = getVehicleOccupant(vehicle, i)
		if player then
			fadeCamera(player, toggle)
		end
	end
end

addEventHandler('onPlayerChat', root,
	function(msg, type)
		if type == 0 then
			cancelEvent()
			if chatTime[source] and chatTime[source] + tonumber(get("*chat/mainChatDelay")) > getTickCount() then
				--outputChatBox("Stop spamming main chat!", source, 255, 0, 0)
				return
			else
				chatTime[source] = getTickCount()
			end
			if get("*chat/blockRepeatMessages") == "true" and lastChatMessage[source] and lastChatMessage[source] == msg then
				--outputChatBox("Stop repeating yourself!", source, 255, 0, 0)
				return
			else
				lastChatMessage[source] = msg
			end
			local r, g, b = getPlayerNametagColor(source)
			--outputChatBox(getPlayerName(source) .. ': #FFFFFF' .. msg:gsub('#%x%x%x%x%x%x', ''), root, r, g, b, true)
			--outputServerLog( "CHAT: " .. getPlayerName(source) .. ": " .. msg )
		end
	end
)

addEventHandler('onVehicleEnter', root,
	function(player, seat)
		if not g_VehicleData[source] then
			return
		end
		if g_VehicleData[source].timers.fire then
			killTimer(g_VehicleData[source].timers.fire)
			g_VehicleData[source].timers.fire = nil
		end
		if g_VehicleData[source].timers.destroy then
			killTimer(g_VehicleData[source].timers.destroy)
			g_VehicleData[source].timers.destroy = nil
		end
		if not getOption('weapons.vehiclesenabled') and g_ArmedVehicles[getElementModel(source)] then
			toggleControl(player, 'vehicle_fire', false)
			toggleControl(player, 'vehicle_secondary_fire', false)
		end
		-- Fast Hunter/Hydra on custom gravity fix
		if getElementModel(source) == 425 or getElementModel(source) == 520 then
			if getPedGravity(player) ~= 0.008 then
				g_PlayerData[player].previousGravity = getPedGravity(player)
				setPedGravity(player, 0.008)
			end
		end
	end
)

addEventHandler('onVehicleExit', root,
	function(player, seat)
		if not g_VehicleData[source] then
			return
		end
		if not g_VehicleData[source].timers.fire then
			for i=0,getVehicleMaxPassengers(source) or 1 do
				if getVehicleOccupant(source, i) then
					return
				end
			end
			if getOption('vehicles.idleexplode') then
				g_VehicleData[source].timers.fire = setTimer(commitArsonOnVehicle, getOption('vehicles.maxidletime'), 1, source)
			end
			g_VehicleData[source].timers.destroy = setTimer(unloadVehicle, getOption('vehicles.maxidletime') + (getOption('vehicles.idleexplode') and 10000 or 0), 1, source)
		end
		if g_ArmedVehicles[getElementModel(source)] then
			toggleControl(player, 'vehicle_fire', true)
			toggleControl(player, 'vehicle_secondary_fire', true)
		end

		if g_PlayerData[player].previousGravity then
			setPedGravity(player, g_PlayerData[player].previousGravity)
			g_PlayerData[player].previousGravity = nil
		end
	end
)

function commitArsonOnVehicle(vehicle)
	g_VehicleData[vehicle].timers.fire = nil
	setElementHealth(vehicle, 0)
end

addEventHandler('onVehicleExplode', root,
	function()
		if not g_VehicleData[source] then
			return
		end
		if g_VehicleData[source].timers.fire then
			killTimer(g_VehicleData[source].timers.fire)
			g_VehicleData[source].timers.fire = nil
		end
		if not g_VehicleData[source].timers.destroy then
			g_VehicleData[source].timers.destroy = setTimer(unloadVehicle, 5000, 1, source)
		end
		if getVehicleController(source) then
			if g_PlayerData[getVehicleController(source)].previousGravity then
				setPedGravity(getVehicleController(source), g_PlayerData[getVehicleController(source)].previousGravity)
				g_PlayerData[getVehicleController(source)].previousGravity = nil
			end
		end
	end
)

function unloadVehicle(vehicle)
	if not g_VehicleData[vehicle] then
		return
	end
	for name,timer in pairs(g_VehicleData[vehicle].timers) do
		if isTimer(timer) then
			killTimer(timer)
		end
		g_VehicleData[vehicle].timers[name] = nil
	end
	local creator = g_VehicleData[vehicle].creator
	if g_PlayerData[creator] then
		table.removevalue(g_PlayerData[creator].vehicles, vehicle)
	end
	g_VehicleData[vehicle] = nil
	if isElement(vehicle) then
		aracsahibi = getElementData(vehicle,"kilit_araba")
        if aracsahibi then
            removeElementData (aracsahibi,"kilit_arabasahibi")
            removeElementData (vehicle,"kilit_araba")
        end	
		destroyElement(vehicle)
	end
end

function quitHandler(player)
	if g_PlayerData[source].blip and isElement(g_PlayerData[source].blip) then
		destroyElement(g_PlayerData[source].blip)
	end
	if sawnoffAntiAbuse[source] and isTimer (sawnoffAntiAbuse[source]) then
		killTimer (sawnoffAntiAbuse[source])
		sawnoffAntiAbuse[source] = nil
	end
	table.each(g_PlayerData[source].vehicles, unloadVehicle)
	removeEventHandler("onFreeroamLocalSettingChange",source,onLocalSettingChange)
	g_PlayerData[source] = nil
	chatTime[source] = nil
	lastChatMessage[source] = nil
end
addEventHandler('onPlayerQuit', root, quitHandler)

addEvent('onServerCall', true)
addEventHandler('onServerCall', resourceRoot,
	function(fnName, ...)
		source = client		-- Some called functions require 'source' to be set to the triggering client
		local fnInfo = g_RPCFunctions[fnName]

		-- Custom check made to intercept the jetpack on custom gravity
		if fnInfo and type(fnInfo) ~= "boolean" and tostring(fnInfo.option) == "jetpack" then
			if tonumber(("%.3f"):format(getPedGravity(source))) ~= 0.008 then
				errMsg("* You may use jetpack only if the gravity is set to 0.008", source)
				return
			end
		end

		if fnInfo and ((type(fnInfo) == 'boolean' and fnInfo) or (type(fnInfo) == 'table' and getOption(fnInfo.option))) then
			local fn = _G
			for i,pathpart in ipairs(fnName:split('.')) do
				fn = fn[pathpart]
			end
			fn(...)
		elseif type(fnInfo) == 'table' then
			errMsg(fnInfo.descr .. ' is not allowed', source)
		end
	end
)

function clientCall(player, fnName, ...)
	triggerClientEvent(player, 'onClientCall', resourceRoot, fnName, ...)
end

function getPlayerName(player)
	return getOption("removeHex") and player.name:gsub("#%x%x%x%x%x%x","") or player.name
end

addEvent("onFreeroamLocalSettingChange",true)
loadstring(exports["MahLib"].getFunctions())()

local commands = {}
local customSpawnTable = false
local allowedStyles =
{
	[4] = true,
	[5] = true,
	[6] = true,
	[7] = true,
	[15] = true,
	[16] = true,
}
local internallyBannedWeapons = -- Fix for some debug warnings
{
	[19] = true,
	[20] = true,
	[21] = true,
}
local server = setmetatable(
		{},
		{
			__index = function(t, k)
				t[k] = function(...) triggerServerEvent('onServerCall', resourceRoot, k, ...) end
				return t[k]
			end
		}
	)
guiSetInputMode("no_binds_when_editing")
setCameraClip(true, false)

local antiCommandSpam = {} -- Place to store the ticks for anti spam:
local playerGravity = getGravity() -- Player's current gravity set by gravity window --
local knifeRestrictionsOn = false

-- Local settings received from server
local g_settings = {}
local _addCommandHandler = addCommandHandler
local _setElementPosition = setElementPosition

if not (g_PlayerData) then
    g_PlayerData = {}
end

-- Settings are stored in meta.xml
function freeroamSettings(settings)
	if settings then
		g_settings = settings
		for _,gui in ipairs(disableBySetting) do
			guiSetEnabled(getControl(gui.parent,gui.id),g_settings["gui/"..gui.id])
		end
	end
end

-- Store the tries for forced global cooldown
local global_cooldown = 0
function isFunctionOnCD(func, exception)
	local tick = getTickCount()
	-- check if a global cd is active
	if g_settings.command_spam_protection and global_cooldown ~= 0 then
		if tick - global_cooldown <= g_settings.command_spam_ban_duration then
			local duration = math.ceil((g_settings.command_spam_ban_duration-tick+global_cooldown)/1000)
			errMsg("Komut kullanımın " .. duration .." saniye yasaklandı")
			return true
		end
	end

	if not g_settings.command_spam_protection then
		return false
	end

	if not antiCommandSpam[func] then
		antiCommandSpam[func] = {time = tick, tries = 1}
		return false
	end

	local oldTime = antiCommandSpam[func].time
	if (tick-oldTime) > 2000 then
		antiCommandSpam[func].time = tick
		antiCommandSpam[func].tries = 1
		return false
	end

	antiCommandSpam[func].tries = antiCommandSpam[func].tries + 1

	if exception and (antiCommandSpam[func].tries < g_settings.g_settings.tries_required_to_trigger_low_priority) then
		return false
	end

	if (exception == nil) and (antiCommandSpam[func].tries < g_settings.tries_required_to_trigger) then
		return false
	end

	-- activate a global command cooldown
	global_cooldown = tick
	antiCommandSpam[func].tries = 0
	--errMsg("Failed, do not spam the commands!")
	return true
end

local function executeCommand(cmd,...)

	local func = commands[cmd]
	cmd = string.lower(cmd)
	if not commands[cmd] then return end
	if table.find(g_settings["command_exception_commands"],cmd) then
		func(cmd,...)
		return
	end
	if isFunctionOnCD(func) then return end
	func(cmd,...)

end

local function addCommandHandler(cmd,func)

	commands[cmd] = func
	_addCommandHandler(cmd,executeCommand,false)

end

local function cancelKnifeEvent(target)

	if knifingDisabled then
		cancelEvent()
		--errMsg("Knife restrictions are in place")
	end

	if g_PlayerData[localPlayer].knifing or g_PlayerData[target].knifing then
		cancelEvent()
	end

end

local function resetKnifing()

	knifeRestrictionsOn = false

end

local function setElementPosition(element,x,y,z)

	if g_settings["weapons/kniferestrictions"] and not knifeRestrictionsOn then
		knifeRestrictionsOn = true
		setTimer(resetKnifing,5000,1)
	end

	_setElementPosition(element,x,y,z)

end


---------------------------
-- Question window
---------------------------
function showReply(leaf)
local leaf = getSelectedGridListLeaf(wndQuestion, 'question')
	if leaf.name and leaf.desc then
		setControlNumber(wndQuestion, 'replylbl', leaf.desc)
	end
end


wndQuestion = {
	'wnd',
	text = 'Sıkça Sorulan Sorular',
	width = 450,
	controls = {
		{
			'lst',
			id='question',
			width=430,
			height=150,
			columns={
				{text='Sorular', attr='name'}
			},
			rows={xml='data/question.xml', attrs={'name', 'desc'}},
			onitemclick=showReply,
		},
		{'lbl', id='replylbl', align='left', text='                                                      ', height=125},
		{'btn', text='Kapat', closeswindow=true, x=140, width=150}
	}
}


---------------------------
-- Set skin window
---------------------------
function skinInit()
	setControlNumber(wndSkin, 'skinid', getElementModel(localPlayer))
end

function showSkinID(leaf)
	if leaf.id then
		setControlNumber(wndSkin, 'skinid', leaf.id)
	end
end

function applySkin()
	local skinID = getControlNumber(wndSkin, 'skinid')
	if skinID then
		server.setMySkin(skinID)
		fadeCamera(true)
	end
end

wndSkin = {
	'wnd',
	text = 'Karakterler',
	width = 250,
	x = -20,
	y = 0.3,
	controls = {
		{
			'lst',
			id='skinlist',
			width=230,
			height=290,
			columns={
				{text='Skin', attr='name'}
			},
			rows={xml='data/skins.xml', attrs={'id', 'name'}},
			onitemclick=showSkinID,
			onitemdoubleclick=applySkin,
			DoubleClickSpamProtected=true,
		},
		{'txt', id='skinid', text='', width=50},
		{'btn', id='Seç', onclick=applySkin, ClickSpamProtected = true,width=70 },
		{'btn', id='Kapat', closeswindow=true,width=70 },
	},
	oncreate = skinInit
}

function setSkinCommand(cmd, skin)
	skin = skin and tonumber(skin)
	if skin then
		server.setMySkin(skin)
		fadeCamera(true)
		closeWindow(wndSpawnMap)
		closeWindow(wndSetPos)
	end
end
addCommandHandler('setskin', setSkinCommand)
addCommandHandler('ss', setSkinCommand)

---------------------------
--- Set animation window
---------------------------

function applyAnimation(leaf)
	if getElementData(localPlayer,"eventsystem:paintballspawn") == true then  return false end
if getElementData(localPlayer,"işlemyapıor") == true then return end
	if type(leaf) ~= 'table' then
		leaf = getSelectedGridListLeaf(wndAnim, 'animlist')
		if not leaf then
			return
		end
	end
	server.setPedAnimation(localPlayer, leaf.parent.name, leaf.name, true, true)
end

function stopAnimation()
	if getElementData(localPlayer,"eventsystem:paintballspawn") == true then  return false end
	if getElementData(localPlayer,"işlemyapıor") == true then return end
	server.setPedAnimation(localPlayer, false)
end
addCommandHandler("stopanim", stopAnimation)
bindKey("lshift", "down", stopAnimation)

wndAnim = {
	'wnd',
	text = 'Animasyonlar',
	width = 250,
	x = -20,
	y = 0.3,
	controls = {
		{
			'lst',
			id='animlist',
			width=230,
			height=290,
			columns={
				{text='Animasyonlar', attr='name'}
			},
			rows={xml='data/animations.xml', attrs={'name'}},
			expandlastlevel=false,
			onitemdoubleclick=applyAnimation,
			DoubleClickSpamProtected=true,
		},
		{'btn', id='Başlat', onclick=applyAnimation, ClickSpamProtected=true, width=70},
		{'btn', id='Durdur', onclick=stopAnimation, width=70},
		{'btn', id='Kapat', closeswindow=true, width=70}
	}
}

addCommandHandler('anim',
	function(command, lib, name)
	if getElementData(localPlayer, 'Turf') == true then return false end
	if getElementData(localPlayer,"eventsystem:paintballspawn") == true then  return false end
	if getElementData(localPlayer,"işlemyapıor") == true then return end
		if lib and name and (
			(lib:lower() == "finale" and name:lower() == "fin_jump_on") or
			(lib:lower() == "finale2" and name:lower() == "fin_cop1_climbout")
		) then
			errMsg('This animation may not be set by command.')
			return
		end
		server.setPedAnimation(localPlayer, lib, name, true, true)
	end
)

function oturCommand()
if getElementData(localPlayer,"işlemyapıor") == true then return end
server.setPedAnimation(localPlayer,"ped","SEAT_idle",-1,true,false,false)
end
addCommandHandler("otur", oturCommand)

--------------------------
--- Sex
--------------------------

function engel()
	if ( guiCheckBoxGetSelected( getControl( wndSex, 'engel' ) ) == true ) then
		setElementData(localPlayer,"SexEngel",true)
    outputChatBox("[✘] #ffffffSize artık sex isteği atamıcaklar.",255,0,0,true)
	else
		setElementData(localPlayer,"SexEngel",nil)
	outputChatBox("[✘] #ffffffSize artık sex isteği atabilecekler.",0,255,0,true)
	end
end

function istekGonder(leaf)	
	local oyuncu = seciliSexOyuncu()
	if not oyuncu then outputChatBox("#0066ff[✘] #ffffffLütfen bir oyuncu seç!",255,0,0, true) return end
	
	-- if oyuncu == localPlayer then return outputChatBox("#0066ff[ⓘ] #ffffffKendinle ilişkiye giremezsin",255,0,0, true) end
	
	if getElementData(oyuncu,"SexEngel") == true then 
        outputChatBox('#0066ff[✘] #ffffffBu oyuncu gelen sex isteklerini kabul etmiyor [#0066ffEngellemiş#ffffff]',255,0,0, true)   
		return 
	end
    if getElementData(oyuncu,"Sex") == true then
	    outputChatBox('#0066ff[✘] #ffffffİstek atdın oyuncu şuanda sexte lütfen bekleyiniz!',255,0,0, true) 
		return
	end
	if getElementDimension(oyuncu) ~= getElementDimension(localPlayer) then 
	    outputChatBox('Bu oyuncu şu başka bir boyutta !')
		return
	end	
	
	if isElement(oyuncu) then
		local istek = getSeciliSexPoz()
        if istek then	
			triggerServerEvent("FreeroamSex:ServerIstek", resourceRoot, oyuncu, istek)
			closeWindow(wndSex)
		else	
			outputChatBox('#0066ff[✘] #ffffffLütfen bir seks pozisyonu seç!',255,0,0, true) 
		end	
	end
end

radlar = {
	['sakso']="Sakso",
	['normal']="Normal",
}
function getSeciliSexPoz()
	for i,v in pairs(radlar) do
		if guiRadioButtonGetSelected(getControl(wndSex,i)) then
			return v
		end	
	end	
	return false
end
function seciliSexOyuncu()
	local liste = getControl(wndSex, 'playerlist')
	local row = guiGridListGetSelectedItem(liste)
	if row ~= -1  then
		return guiGridListGetItemData(liste, row, 1)
	else
		return false
	end
end

function oyunculariEkle()	
	local liste = getControl(wndSex, 'playerlist')
	guiGridListClear(liste)
	local x,y,z = getElementPosition(localPlayer)
	for i,oyuncu in pairs(getElementsByType("player")) do
		if not getElementData(oyuncu, "SexEngel") and oyuncu ~= localPlayer  then
			local px,py,pz = getElementPosition(oyuncu)
			if getDistanceBetweenPoints3D(x,y,z,px,py,pz) < 50 then
				local row = guiGridListAddRow(liste)
				guiGridListSetItemText ( liste, row, 1, getPlayerName(oyuncu):gsub("#%x%x%x%x%x%x",""), false, false )
				guiGridListSetItemData(liste, row, 1, oyuncu)
				guiGridListSetItemColor(liste, row, 1, r, g, b)
			end
		end
	end
end

addEventHandler("onClientGUIDoubleClick", resourceRoot, function()
	if source == getControl(wndSex, 'playerlist') then
		istekGonder()
	end
end)


wndSex = {
	'wnd',
	text = 'Sex  Sistemi',
	width = 340,
	controls = {
		{
			'lst',
			id='playerlist',
			width=200,
			height=200,
			columns={
				{text='Oyuncu', attr='name'}
			},
			--onitemdoubleclick=istekGonder
		},
		{'rad', id='sakso',  text="Sakso", x=280, y=35},
		{'rad', id='normal',  text="Normal", x=215, y=35},
		{'chk', id='engel',  text="İstekleri Engelle", onclick=engel, x=10, y=240},
		{'btn', id='İstek Atın', onclick=istekGonder, x=215, y=140},
		{'btn', id='Paneli Kapat', closeswindow=true, x=215, y=170},
	},
	oncreate = oyunculariEkle
}
---------------------------
-- Weapon window
---------------------------

function addWeapon(leaf, amount)
	if type(leaf) ~= 'table' then
		leaf = getSelectedGridListLeaf(wndWeapon, 'weaplist')
		amount = getControlNumber(wndWeapon, 'amount')
		if not amount or not leaf or not leaf.id then
			return
		end
	end
	if amount < 1 then
		errMsg("Invalid amount")
		return
	end
	server.giveMeWeapon(leaf.id, amount)
end

wndWeapon = {
	'wnd',
	text = 'Temel Eşyalar',
	width = 250,
	controls = {
		{
			'lst',
			id='weaplist',
			width=230,
			height=280,
			columns={
				{text='Temel Eşyalar', attr='name'}
			},
			rows={xml='data/weapons.xml', attrs={'id', 'name'}},
			onitemdoubleclick=function(leaf) addWeapon(leaf, 1500) end,
			DoubleClickSpamProtected=true
		},
		{'br'},
		{'txt', id='amount', text='1500', width=60},
		{'btn', id='Al', onclick=addWeapon, ClickSpamProtected=true, width=70},
		{'btn', id='Kapat', closeswindow=true, width=70}
	}
}

---------------------------
-- Walk style
--------------------------- 
function applyWalkStyle( leaf )
    if type( leaf ) ~= 'table' then
        leaf = getSelectedGridListLeaf( wndWalking, 'walkStyle' )
        if not leaf then
            return
        end
    end
    server.setPedWalkingStyle(localPlayer, leaf.id)
end
 
function stopWalkStyle()
    server.setPedWalkingStyle(localPlayer, 0)
end
 
wndWalking = {
    'wnd',
    text = 'Yürüyüş Stilleri',
    width = 250,
    controls = {
        {
            'lst',
            id = 'walkStyle',
            width = 230,
            height = 290,
            columns = {
                { text = 'Stiller', attr = 'name' }
            },
            rows = { xml = 'data/walk.xml', attrs = { 'id', 'name' } },
            onitemdoubleclick = applyWalkStyle
        },
        { 'btn', id = 'Kullan', onclick = applyWalkStyle, width=70 },
        { 'btn', id = 'Kaldır', onclick = stopWalkStyle, width=70 },
        { 'btn', id = 'Kapat', closeswindow = true, width=70 }
    }
}


---------------------------
-- Görevler
--------------------------- 
function applyWalkStyle( leaf )
    if type( leaf ) ~= 'table' then
        leaf = getSelectedGridListLeaf( wndWalking, 'walkStyle' )
        if not leaf then
            return
        end
    end
    server.setPedWalkingStyle(localPlayer, leaf.id)
end
 
function stopWalkStyle()
    server.setPedWalkingStyle(localPlayer, 0)
end
 
wndWalking = {
    'wnd',
    text = 'Görevler',
    width = 250,
    controls = {
        {
            'lst',
            id = 'walkStyle',
            width = 230,
            height = 290,
            columns = {
                { text = 'Stiller', attr = 'name' }
            },
            rows = { xml = 'data/walk.xml', attrs = { 'id', 'name' } },
            onitemdoubleclick = applyWalkStyle
        },     
		{ 'btn', id = 'Kapat', closeswindow = true, width=70 }
    }
}

---------------------------
-- Fighting style
---------------------------

function applyFightStyle( leaf )
    if type( leaf ) ~= 'table' then
        leaf = getSelectedGridListLeaf( wndFighting, 'fightStyle' )
        if not leaf then
            return
        end
    end
    server.setPedFightingStyle( localPlayer, leaf.id )
end
 
function stopFightStyle()
    server.setPedFightingStyle( localPlayer, 0 )
end
 
wndFighting = {
    'wnd',
    text = 'Dövüs Stilleri',
    width = 250,
    controls = {
        {
            'lst',
            id = 'fightStyle',
            width = 230,
            height = 290,
            columns = {
                { text = 'Stiller', attr = 'name' }
            },
            rows = { xml = 'data/fight.xml', attrs = { 'id', 'name' } },
            onitemdoubleclick = applyFightStyle
        },
        { 'btn', id = 'Ayarla', onclick = applyFightStyle, width=70 },
        { 'btn', id = 'Durdur', onclick = stopFightStyle, width=70 },
        { 'btn', id = 'Kapat', closeswindow = true, width=70 }
    }
}

addCommandHandler('setstyle',
	function(cmd, style)
		style = style and tonumber(style) or 7
		if allowedStyles[style] then
			server.setPedFightingStyle(localPlayer, style)
		end
	end
)

---------------------------
-- Clothes window
---------------------------
function clothesInit()
	if getElementModel(localPlayer) ~= 0 then
		errMsg('CJ (Carl Johnson) olmalısın.')
		closeWindow(wndClothes)
		return
	end
	if not g_Clothes then
		triggerServerEvent('onClothesInit', resourceRoot)
	end
end

addEvent('onClientClothesInit', true)
addEventHandler('onClientClothesInit', resourceRoot,
	function(clothes)
		g_Clothes = clothes.allClothes
		for i,typeGroup in ipairs(g_Clothes) do
			for j,cloth in ipairs(typeGroup.children) do
				if not cloth.name then
					cloth.name = cloth.model .. ' - ' .. cloth.texture
				end
				cloth.wearing =
					clothes.playerClothes[typeGroup.type] and
					clothes.playerClothes[typeGroup.type].texture == cloth.texture and
					clothes.playerClothes[typeGroup.type].model == cloth.model
					or false
			end
			table.sort(typeGroup.children, function(a, b) return a.name < b.name end)
		end
		bindGridListToTable(wndClothes, 'clothes', g_Clothes, false)
	end
)

function clothListClick(cloth)
	setControlText(wndClothes, 'addremove', cloth.wearing and 'Çıkar' or 'Giy')
end

function applyClothes(cloth)
	if not cloth then
		cloth = getSelectedGridListLeaf(wndClothes, 'clothes')
		if not cloth then
			return
		end
	end
	if cloth.wearing then
		cloth.wearing = false
		setControlText(wndClothes, 'addremove', 'Giy')
		server.removePedClothes(localPlayer, cloth.parent.type)
	else
		local prevClothIndex = table.find(cloth.siblings, 'wearing', true)
		if prevClothIndex then
			cloth.siblings[prevClothIndex].wearing = false
		end
		cloth.wearing = true
		setControlText(wndClothes, 'addremove', 'Çıkar')
		server.addPedClothes(localPlayer, cloth.texture, cloth.model, cloth.parent.type)
	end
end

wndClothes = {
	'wnd',
	text = 'Kıyafet',
	x = -20,
	y = 0.3,
	width = 350,
	controls = {
		{
			'lst',
			id='clothes',
			width=330,
			height=390,
			columns={
				{text='Kıyafet', attr='name', width=0.6},
				{text='Üzerindekiler', attr='wearing', enablemodify=true, width=0.3}
			},
			rows={
				{name='Giysi Listesi Alınıyor...'}
			},
			onitemclick=clothListClick,
			onitemdoubleclick=applyClothes,
			DoubleClickSpamProtected=true,
		},
		{'br'},
		{'btn', text='Giy/Çıkar', id='addremove', width=60, onclick=applyClothes, ClickSpamProtected=true},
		{'btn', id='Kapat', closeswindow=true}
	},
	oncreate = clothesInit
}

function addClothesCommand(cmd, type, model, texture)
	type = type and tonumber(type)
	if type and model and texture then
		server.addPedClothes(localPlayer, texture, model, type)
	end
end
addCommandHandler('addclothes', addClothesCommand)
addCommandHandler('ac', addClothesCommand)

function removeClothesCommand(cmd, type)
	type = type and tonumber(type)
	if type then
		server.removePedClothes(localPlayer, type)
	end
end
addCommandHandler('removeclothes', removeClothesCommand)
addCommandHandler('rc', removeClothesCommand)

---------------------------
-- Player gravity window
---------------------------
function playerGravInit()
	triggerServerEvent('onPlayerGravInit',localPlayer)
end

addEvent('onClientPlayerGravInit', true)
addEventHandler('onClientPlayerGravInit', resourceRoot,
	function(curgravity)
		setControlText(wndGravity, 'gravval', string.sub(tostring(curgravity), 1, 6))
	end
)

function selectPlayerGrav(leaf)
	setControlNumber(wndGravity, 'gravval', leaf.value)
end

function applyPlayerGrav()
	local grav = getControlNumber(wndGravity, 'gravval')
	if grav then
		playerGravity = grav
		server.setPedGravity(localPlayer, grav)
	end
	closeWindow(wndGravity)
end

function setGravityCommand(cmd, grav)
	local grav = grav and tonumber(grav)
	if grav then
		playerGravity = grav
		server.setPedGravity(localPlayer, tonumber(grav))
	end
end
--addCommandHandler('setgravity', setGravityCommand)
--addCommandHandler('grav', setGravityCommand)

wndGravity = {
	'wnd',
	text = 'Set gravity',
	width = 300,
	controls = {
		{
			'lst',
			id='gravlist',
			width=280,
			height=200,
			columns={
				{text='Gravity', attr='name'}
			},
			rows={
				{name='Space', value=0},
				{name='Moon', value=0.001},
				{name='Normal', value=0.008},
				{name='Strong', value=0.015}
			},
			onitemclick=selectPlayerGrav,
			onitemdoubleclick=applyPlayerGrav,
			DoubleClickSpamProtected=true,
		},
		{'lbl', text='Exact value: '},
		{'txt', id='gravval', text='', width=80},
		{'br'},
		{'btn', id='ok', onclick=applyPlayerGrav,ClickSpamProtected=true},
		{'btn', id='cancel', closeswindow=true}
	},
	oncreate = playerGravInit
}

---------------------------
-- Warp to player window
---------------------------

local function warpMe(targetPlayer)

	if not g_settings["warp"] then
		errMsg("Işınlanma server tarafından kapatıldı!")
		return
	end

	if targetPlayer == localPlayer then
		errMsg("Kendine ışınlanamazsın!")
		return
	end

	if g_PlayerData[targetPlayer].warping then
		errMsg("Işınlanmak istediğin oyuncuya ışınlanamazsın!")
		return
	end

	local vehicle = getPedOccupiedVehicle(targetPlayer)
	local interior = getElementInterior(targetPlayer)
	if not vehicle then
		-- target player is not in a vehicle - just warp next to him
		local vec = targetPlayer.position + targetPlayer.matrix.right*2
		local x, y, z = vec.x,vec.y,vec.z
		if localPlayer.interior ~= interior then
			fadeCamera(false,1)
			setTimer(setPlayerInterior,1000,1,x,y,z,interior)
		else
			setPlayerPosition(x,y,z)
		end
	else
		-- target player is in a vehicle - warp into it if there's space left
		server.warpMeIntoVehicle(vehicle)
	end

end

function warpInit()
	setControlText(wndWarp, 'search', '')
	warpUpdate()
end

function warpTo(leaf)
	if not leaf then
		leaf = getSelectedGridListLeaf(wndWarp, 'playerlist')
		if not leaf then
			return
		end
	end
	if isElement(leaf.player) then
		warpMe(leaf.player)
	end
	closeWindow(wndWarp)
end

function warpUpdate()
	local function getPlayersByPartName(text)
		if not text or text == '' then
			return getElementsByType("player")
		else
			local players = {}
			for _, player in ipairs(getElementsByType("player")) do
				if string.find(getPlayerName(player):gsub("#%x%x%x%x%x%x", ""):upper(), text:upper(), 1, true) then
					table.insert(players, player)
				end
			end
			return players
		end
	end
	
	local text = getControlText(wndWarp, 'search')
	local players = table.map(getPlayersByPartName(text), 
		function(p) 
			local pName = getPlayerName(p)
			if g_settings["hidecolortext"] then
				pName = pName:gsub("#%x%x%x%x%x%x", "")
			end
			return { player = p, name = pName } 
		end)
	table.sort(players, function(a, b) return a.name < b.name end)
	bindGridListToTable(wndWarp, 'playerlist', players, true)
end

wndWarp = {
	'wnd',
	text = 'Oyuncuya Işınlan',
	width = 300,
	controls = {
		{'txt', id='search', text='', width = 280, onchanged=warpUpdate},
		{
			'lst',
			id='playerlist',
			width=280,
			height=330,
			columns={
				{text='Player', attr='name'}
			},
			onitemdoubleclick=warpTo,
			DoubleClickSpamProtected=true,
		},
		{'btn', id='Işınlan', onclick=warpTo, ClickSpamProtected=true},
		{'btn', id='Kapat', closeswindow=true}
	},
	oncreate = warpInit
}
---------------------------
-- Jetpack toggle
---------------------------
noktalar = {
	{ 1496.52759, -1833.08374, 2516.02661 },
	--{ 1493.3000488281, -1829.8000488281, 2516 },
	--{ 1509.1999511719, -1827.3000488281, 2516 },
}

addCommandHandler("devmode", function()
        setDevelopmentMode(true)
    end
)

function alanagirdi(giren)
	if ( giren == localPlayer ) then
		triggerServerEvent("zafer:jetpacksil",localPlayer)
		--setElementPosition(localPlayer,1508.46606, -1827.74304, 2516.02661)
	--	for _,vehicle in ipairs(getElementsByType("player")) do
	--		destroyElement(vehicle)
	---	end
	end
end

for i,v in pairs(noktalar) do
   drop_konum = createColSphere(v[1], v[2], v[3], 44)
   addEventHandler("onClientColShapeHit",drop_konum,alanagirdi)
end

function toggleJetPack()
if  isElementWithinColShape(localPlayer,drop_konum) then outputChatBox("#0066ff[✘] #ffffffDropta iken jetpack kullanamazsınız.",255,0,0,true) return end
if getElementData(localPlayer,"eventsystem:paintballspawn") == true then  return false end
if getElementData(localPlayer,"ayarlarmenu") == true then outputChatBox("#0066ff[✘] #ffffffNargile alanında iken jetpack kullanamazsınız.",255,0,0,true) return false end
if getElementData(localPlayer,"işlemyapıor") == true then outputChatBox("#0066ff[✘] #ffffffSex yaparken jetpack kullanamazsınız.",255,0,0,true) return false end
if getElementData(localPlayer, 'Turf') == true then return false end
	if not doesPedHaveJetPack(localPlayer) then
		server.givePedJetPack(localPlayer)
		guiCheckBoxSetSelected(getControl(wndMain, 'jetpack'), true)
	else
		server.removePedJetPack(localPlayer)
		guiCheckBoxSetSelected(getControl(wndMain, 'jetpack'), false)
	end
end

bindKey('j', 'down', toggleJetPack)

addCommandHandler('jetpack', toggleJetPack)
addCommandHandler('jp', toggleJetPack)

---------------------------
-- Gorevler
---------------------------

yerler = {
	["Uçak"] = {
					["Los Santos"] = "1996.22,-2403.38,13.54",
					["San Fierro"] = "1996.22,-2403.38,13.54",
					["Las Venturas"] = "1996.22,-2403.38,13.54",
				},
	["Silah"] = {
					["Los Santos"] = "-2136.67,-129.88,35.32",
					["San Fierro"] = "-2136.67,-129.88,35.32",
					["Las Venturas"] = "-2136.67,-129.88,35.32",
				},
	["Uyuşturucu"] = {
					["Los Santos"] = "-2485.44,777.50,34.5",
					["San Fierro"] = "-2485.44,777.50,34.5",
					["Las Venturas"] = "-2485.44,777.50,34.5",	
				},	
	["Taksi"] = {
					["Los Santos"] = "1728.75,-1865.21,13.6",
					["San Fierro"] = "1728.75,-1865.21,13.6",
					["Las Venturas"] = "1728.75,-1865.21,13.6",
				},	
	["Petrol"] = {
					["Los Santos"] = "-1831.13,119.09,15.11",
					["San Fierro"] = "-1831.13,119.09,15.11",
					["Las Venturas"] = "-1831.13,119.09,15.11",
				},
	["Ambulans"] = {
					["Los Santos"] = "2041.29,-1415.11,17.17",
					["San Fierro"] = "2041.29,-1415.11,17.17",
					["Las Venturas"] = "2041.29,-1415.11,17.17",
				},
				
	["Kamyon"] = {
					["Los Santos"] = "2768.0388183594,-2423.7619628906,13.651894569397",
					["San Fierro"] = "2768.0388183594,-2423.7619628906,13.651894569397",
					["Las Venturas"] = "2768.0388183594,-2423.7619628906,13.651894569397",
				},
				
	["Denizcilik"] = {
					["Los Santos"] = "-2333.486328125,2294.3901367188,4.984375",
					["San Fierro"] = "-2333.486328125,2294.3901367188,4.984375",
					["Las Venturas"] = "-2333.486328125,2294.3901367188,4.984375",
				},
}

function getCityZoneFromXYZ(x, y, z)
	local theZone = getZoneName(x, y, z, true)
	if (theZone) then
		if (theZone == "Las Venturas") then
			return "Las Venturas"
		elseif (theZone == "Los Santos") then
			return "Los Santos"
		elseif (theZone == "San Fierro") then
			return "San Fierro"
		elseif (theZone == "Red County") then
			return "Los Santos"
		elseif (theZone == "Flint County") then
			return "San Fierro"
		elseif (theZone == "Whetstone") then
			return "San Fierro"
		elseif (theZone == "Bone County") then
			return "Las Venturas"
		elseif (theZone == "Tierra Robada") then
			return "Las Venturas"
		else
			return "San Fierro"
		end
	end
	return false
end	
	
function bilgigoster(leaf)
	setControlText(wndGorevler, 'bilgi', leaf.desc)
end

function gorevegit(leaf)
	local elem = getPedOccupiedVehicle(localPlayer)
if elem and getElementData(elem,"Satilik") then exports.Duyuru:sendClientMessage('Işınlanma Sistemi: Satılık araçta iken görevler paneline erişemezsin!') return end
	if not leaf then
		leaf = getSelectedGridListLeaf(wndGorevler, 'gorevlist')
		if not leaf then
			return
		end
	end
	if leaf.pos then
		pos = split(leaf.pos, ",")
		setPlayerPosition(pos[1], pos[2], pos[3] + 1)
	end	
	if yerler[leaf.name] then
		local x,y,z = getElementPosition(localPlayer)
		local yer = getCityZoneFromXYZ(x, y, z)
		pos = split(yerler[leaf.name][yer], ",")
	end	
	closeWindow(wndGorevler)
	if leaf.id==1 then
	   triggerServerEvent("GTImining.gorevgir",localPlayer,localPlayer)
	end
end

wndGorevler = {
	'wnd',
	text = 'Görevler',
	width = 270,
	controls = {
		{
			'lst',
			id='gorevlist',
			width=250,
			height=200,
			columns={
				{text='Görevler', attr='name'}
			},
			rows={xml='data/gorevler.xml', attrs={'id', 'name', 'pos','desc'}},
			onitemdoubleclick = gorevegit
		},
		{'lbl', id='bilgi', text="",width = 100, height=10, align="left"},
		{'br'},
		{'br'},
		{'btn', id='Göreve Git', onclick=gorevegit},
		{'btn', id='Kapat', closeswindow=true},
	},
}

---------------------------
-- Fall off bike toggle
---------------------------
function toggleFallOffBike()
	if getElementData(localPlayer, 'Turf') == true then return false end
	setPedCanBeKnockedOffBike(localPlayer, guiCheckBoxGetSelected(getControl(wndMain, 'falloff')))
end

---------------------------
-- Set position window
---------------------------
do
	local screenWidth, screenHeight = guiGetScreenSize()
	g_MapSide = (screenHeight * 0.85)
end

function setPosInit()
	local x, y, z = getElementPosition(localPlayer)
	setControlNumbers(wndSetPos, { x = x, y = y, z = z })

	addEventHandler('onClientRender', root, updatePlayerBlips)
end

function fillInPosition(relX, relY, btn)
	if (btn == 'right') then
		closeWindow (wndSetPos)
		return
	end

	local x = relX*6000 - 3000
	local y = 3000 - relY*6000
	local hit, hitX, hitY, hitZ
	hit, hitX, hitY, hitZ = processLineOfSight(x, y, 3000, x, y, -3000)
	setControlNumbers(wndSetPos, { x = x, y = y, z = hitZ or 0 })
end

function setPosClick()
	if setPlayerPosition(getControlNumbers(wndSetPos, {'x', 'y', 'z'})) ~= false then
		if getElementInterior(localPlayer) ~= 0 then
			local vehicle = localPlayer.vehicle
			if vehicle and vehicle.interior ~= 0 then
				server.setElementInterior(getPedOccupiedVehicle(localPlayer), 0)
				local occupants = vehicle.occupants
				for seat,occupant in pairs(occupants) do
					if occupant.interior ~= 0 then
						server.setElementInterior(occupant,0)
					end
				end
			end
			if localPlayer.interior ~= 0 then
				server.setElementInterior(localPlayer,0)
			end
		end
		closeWindow(wndSetPos)
	end
end

local function forceFade()

	fadeCamera(false,0)

end

local function calmVehicle(veh)

	if not isElement(veh) then return end
	local z = veh.rotation.z
	veh.velocity = Vector3(0,0,0)
	veh.turnVelocity = Vector3(0,0,0)
	veh.rotation = Vector3(0,0,z)
	if not (localPlayer.inVehicle and localPlayer.vehicle) then
		server.warpMeIntoVehicle(veh)
	end

end

local function retryTeleport(elem,x,y,z,isVehicle,distanceToGround)

	local hit, groundX, groundY, groundZ = processLineOfSight(x, y, 3000, x, y, -3000)
	if hit then
		local waterZ = getWaterLevel(x, y, 100)
		z = (waterZ and math.max(groundZ, waterZ) or groundZ) + distanceToGround
		setElementPosition(elem,x, y, z + distanceToGround)
		setCameraPlayerMode()
		setGravity(grav)
		if isVehicle then
			server.fadeVehiclePassengersCamera(true)
			setTimer(calmVehicle,100,1,elem)
		else
			fadeCamera(true)
		end
		killTimer(g_TeleportTimer)
		g_TeleportTimer = nil
		grav = nil
	end

end

function setPlayerPosition(x, y, z)
	local elem = getPedOccupiedVehicle(localPlayer)
	local distanceToGround
	local isVehicle
	if elem then
		if getPlayerOccupiedSeat(localPlayer) ~= 0 then
			errMsg('Sadece Araç Koltuğundakiler Bu Komutu Kullanabilir.')
			return
		end
		distanceToGround = getElementDistanceFromCentreOfMassToBaseOfModel(elem) + 3
		isVehicle = true
	else
		elem = localPlayer
		distanceToGround = 0.4
		isVehicle = false
	end
	local hit, hitX, hitY, hitZ = processLineOfSight(x, y, 3000, x, y, -3000)
	if not hit then
		if isVehicle then
			server.fadeVehiclePassengersCamera(false)
		else
			fadeCamera(false)
		end
		if isTimer(g_TeleportMatrixTimer) then killTimer(g_TeleportMatrixTimer) end
		g_TeleportMatrixTimer = setTimer(setCameraMatrix, 1000, 1, x, y, z)
		if not grav then
			grav = getGravity()
			setGravity(0.001)
		end
		if isTimer(g_TeleportTimer) then killTimer(g_TeleportTimer) end
		g_TeleportTimer = setTimer(
			function()
				local hit, groundX, groundY, groundZ = processLineOfSight(x, y, 3000, x, y, -3000)
				if hit then
					local waterZ = getWaterLevel(x, y, 100)
					z = (waterZ and math.max(groundZ, waterZ) or groundZ) + distanceToGround
					if isPedDead(localPlayer) then
						server.spawnMe(x, y, z)
					else
						setElementPosition(elem, x, y, z)
					end
					setCameraPlayerMode()
					setGravity(grav)
					if isVehicle then
						server.fadeVehiclePassengersCamera(true)
					else
						fadeCamera(true)
					end
					killTimer(g_TeleportTimer)
					g_TeleportTimer = nil
					grav = nil
				end
			end,
			500,
			0
		)
	else
		if isPedDead(localPlayer) then
			server.spawnMe(x, y, z + distanceToGround)
		else
			setElementPosition(elem, x, y, z + distanceToGround)
			if isVehicle then
				setTimer(setElementVelocity, 100, 1, elem, 0, 0, 0)
				setTimer(setVehicleTurnVelocity, 100, 1, elem, 0, 0, 0)
			end
		end
	end
end

local blipPlayers = {}

local function destroyBlip()

	blipPlayers[source] = nil

end

local function warpToBlip()

	local wnd = isWindowOpen(wndSpawnMap) and wndSpawnMap or wndSetPos
	local elem = blipPlayers[source]

	if isElement(elem) then
		warpMe(elem)
		closeWindow(wnd)
	end

end

function updatePlayerBlips()
	if not g_PlayerData then
		return
	end
	local wnd = isWindowOpen(wndSpawnMap) and wndSpawnMap or wndSetPos
	local mapControl = getControl(wnd, 'map')
	for elem,player in pairs(g_PlayerData) do
		if not player.gui.mapBlip then
			local playerName = player.name
			if g_settings["hidecolortext"] then
				playerName = playerName:gsub("#%x%x%x%x%x%x", "")
			end
			player.gui.mapBlip = guiCreateStaticImage(0, 0, 9, 9, elem == localPlayer and 'localplayerblip.png' or 'playerblip.png', false, mapControl)
			player.gui.mapLabelShadow = guiCreateLabel(0, 0, 100, 14, playerName, false, mapControl)
			local labelWidth = guiLabelGetTextExtent(player.gui.mapLabelShadow)
			guiSetSize(player.gui.mapLabelShadow, labelWidth, 14, false)
			guiSetFont(player.gui.mapLabelShadow, 'default-bold-small')
			guiLabelSetColor(player.gui.mapLabelShadow, 255, 255, 255)
			player.gui.mapLabel = guiCreateLabel(0, 0, labelWidth, 14, playerName, false, mapControl)
			guiSetFont(player.gui.mapLabel, 'default-bold-small')
			guiLabelSetColor(player.gui.mapLabel, 0, 0, 0)
			for i,name in ipairs({'mapBlip', 'mapLabelShadow'}) do
				blipPlayers[player.gui[name]] = elem
				addEventHandler('onClientGUIDoubleClick', player.gui[name],warpToBlip,false)
				addEventHandler("onClientElementDestroy", player.gui[name],destroyBlip)
			end
		end
		local yazi = guiGetText(getControl(wndSetPos, 'playerSearch'))
		local x, y = getElementPosition(elem)
		local visible = (localPlayer.interior == elem.interior and localPlayer.dimension == elem.dimension)
		x = math.floor((x + 3000) * g_MapSide / 6000) - 4
		y = math.floor((3000 - y) * g_MapSide / 6000) - 4
		guiSetPosition(player.gui.mapBlip, x, y, false)
		guiSetPosition(player.gui.mapLabelShadow, x + 14, y - 4, false)
		guiSetPosition(player.gui.mapLabel, x + 13, y - 5, false)
		if yazi ~= "Oyuncu Ara..." then
			local playerName = player.name
			if g_settings["hidecolortext"] then
				playerName = playerName:gsub("#%x%x%x%x%x%x", "")
			end
			local yazi = guiGetText(getControl(wndSetPos, 'playerSearch')):lower()
			visible = (localPlayer.interior== elem.interior and (localPlayer.dimension == elem.dimension) and (type(playerName:find(yazi,1,true)) == "number") ) 
		end
		guiSetVisible(player.gui.mapBlip,visible)
		guiSetVisible(player.gui.mapLabelShadow,visible)
		guiSetVisible(player.gui.mapLabel,visible)
	end
end

function updateName(oldNick, newNick)
	if (not g_PlayerData) then return end
	local source = getElementType(source) == "player" and source or oldNick
	local player = g_PlayerData[source]
	player.name = newNick
	if player.gui.mapLabel then
		guiSetText(player.gui.mapLabelShadow, newNick)
		guiSetText(player.gui.mapLabel, newNick)
		local labelWidth = guiLabelGetTextExtent(player.gui.mapLabelShadow)
		guiSetSize(player.gui.mapLabelShadow, labelWidth, 14, false)
		guiSetSize(player.gui.mapLabel, labelWidth, 14, false)
	end
end

addEventHandler('onClientPlayerChangeNick', root,updateName)

function closePositionWindow()
	removeEventHandler('onClientRender', root, updatePlayerBlips)
end

wndSetPos = {
	'wnd',
	text = 'Harita',
	width = g_MapSide + 20,
	controls = {
		{'img', id='map', src='map.jpg', width=g_MapSide, height=g_MapSide, onclick=fillInPosition, ondoubleclick=setPosClick, DoubleClickSpamProtected=true},
		{'txt', id='x', text='', width=60},
		{'txt', id='y', text='', width=60},
		{'txt', id='z', text='', width=60},
		{'txt', id='playerSearch', text='Oyuncu Ara...', width=90, onclick=setSearchClick},
		{'btn', id='Işınlan', onclick=setPosClick, ClickSpamProtected=true},
		{'btn', id='Kapat', closeswindow=true}
	},
	oncreate = setPosInit,
	onclose = closePositionWindow
}

function getPosCommand(cmd, playerName)
	if getElementData(localPlayer, 'Turf') == true then return false end
	local player, sentenceStart

	if playerName then
		player = getPlayerFromName(playerName)
		if not player then
			errMsg('There is no player named "' .. playerName .. '".')
			return
		end
		playerName = getPlayerName(player)		-- make sure case is correct
		sentenceStart = playerName .. ' is '
	else
		player = localPlayer
		sentenceStart = 'You are '
	end

	local px, py, pz = getElementPosition(player)
	local vehicle = getPedOccupiedVehicle(player)
	if vehicle then
		outputChatBox(sentenceStart .. 'in a ' .. getVehicleName(vehicle), 0, 255, 0)
	else
		outputChatBox(sentenceStart .. 'on foot', 0, 255, 0)
	end
	outputChatBox(sentenceStart .. 'at {' .. string.format("%.5f", px) .. ', ' .. string.format("%.5f", py) .. ', ' .. string.format("%.5f", pz) .. '}', 0, 255, 0)
end
addCommandHandler('getpos', getPosCommand)
addCommandHandler('gp', getPosCommand)

function setPosCommand(cmd, x, y, z, r)
	if getElementData(localPlayer, 'ArabaEtkinlik') == true then return false end
	if getElementData(localPlayer, 'Dust2Etkinlik') == true then return false end
	-- Handle setpos if used like: x, y, z, r or x,y,z,r
	local x, y, z, r = string.gsub(x or "", ",", " "), string.gsub(y or "", ",", " "), string.gsub(z or "", ",", " "), string.gsub(r or "", ",", " ")
	-- Extra handling for x,y,z,r
	if (x and y == "" and not tonumber(x)) then
		x, y, z, r = unpack(split(x, " "))
	end
	
	local px, py, pz = getElementPosition(localPlayer)
	local pr = getPedRotation(localPlayer)
	
	local message = ""
	if (not tonumber(x)) then
		message = "X "
	end
	if (not tonumber(y)) then
		message = message.."Y "
	end
	if (not tonumber(z)) then
		message = message.."Z "
	end
	if (message ~= "") then
	end
	
	setPlayerPosition(tonumber(x) or px, tonumber(y) or py, tonumber(z) or pz)
	if (isPedInVehicle(localPlayer)) then
		local vehicle = getPedOccupiedVehicle(localPlayer)
		if (vehicle and isElement(vehicle) and getVehicleController(vehicle) == localPlayer) then
			setElementRotation(vehicle, 0, 0, tonumber(r) or pr)
		end
	else
		setPedRotation(localPlayer, tonumber(r) or pr)
	end
end
addCommandHandler('setpos', setPosCommand)
addCommandHandler('sp', setPosCommand)

---------------------------
-- Spawn map window
---------------------------
function warpMapInit()
	addEventHandler('onClientRender', root, updatePlayerBlips)
end

function spawnMapDoubleClick(relX, relY)
	setPlayerPosition(relX*6000 - 3000, 3000 - relY*6000, 0)
	closeWindow(wndSpawnMap)
end

function closeSpawnMap()
	showCursor(false)
	removeEventHandler('onClientRender', root, updatePlayerBlips)
	for elem,data in pairs(g_PlayerData) do
		for i,name in ipairs({'mapBlip', 'mapLabelShadow', 'mapLabel'}) do
			if data.gui[name] then
				destroyElement(data.gui[name])
				data.gui[name] = nil
			end
		end
	end
end

wndSpawnMap = {
	'wnd',
	text = 'Select spawn position',
	width = g_MapSide + 20,
	controls = {
		{'img', id='map', src='map.jpg', width=g_MapSide, height=g_MapSide, ondoubleclick=spawnMapDoubleClick},
		{'lbl', text='Welcome to freeroam. Double click a location on the map to spawn.', width=g_MapSide-60, align='center'},
		{'btn', id='close', closeswindow=true}
	},
	oncreate = warpMapInit,
	onclose = closeSpawnMap
}

---------------------------
-- Create vehicle window
---------------------------
function createSelectedVehicle(leaf)
	if not leaf then
		leaf = getSelectedGridListLeaf(wndCreateVehicle, 'vehicles')
		if not leaf then
			return
		end
	end
	server.giveMeVehicles(leaf.id)
end

wndCreateVehicle = {
	'wnd',
	text = 'Araba Oluştur',
	width = 300,
	controls = {
		{
			'lst',
			id='vehicles',
			width=280,
			height=340,
			columns={
				{text='Araba', attr='name'}
			},
			rows={xml='data/vehicles.xml', attrs={'id', 'name'}},
			onitemdoubleclick=createSelectedVehicle,
			DoubleClickSpamProtected=true,
		},
		{'btn', id='Oluştur', onclick=createSelectedVehicle, ClickSpamProtected=true, width=135},
		{'btn', id='Kapat', closeswindow=true, width=135}
	}
}

---------------------------
-- Repair vehicle
---------------------------
function repairVehicle()
if getElementData(localPlayer, 'Turf') == true then return false end
	local vehicle = getPedOccupiedVehicle(localPlayer)
	if vehicle then
		server.fixVehicle(vehicle)
	end
end

addCommandHandler('repair', repairVehicle)
addCommandHandler('rp', repairVehicle)

---------------------------
-- Flip vehicle
---------------------------
function flipVehicle()
if getElementData(localPlayer, 'Turf') == true then return false end
	local vehicle = getPedOccupiedVehicle(localPlayer)
	if vehicle then
		local rX, rY, rZ = getElementRotation(vehicle)
		setElementRotation(vehicle, 0, 0, (rX > 90 and rX < 270) and (rZ + 180) or rZ)
	end
end

addCommandHandler('flip', flipVehicle)
addCommandHandler('f', flipVehicle)

---------------------------
-- Vehicle upgrades
---------------------------
function upgradesInit()
	local vehicle = getPedOccupiedVehicle(localPlayer)
	if not vehicle then
		errMsg('Modifiye etmek için araç almanız gerek.')
		closeWindow(wndUpgrades)
		return
	end
	local installedUpgrades = getVehicleUpgrades(vehicle)
	local compatibleUpgrades = {}
	local slotName, group
	for i,upgrade in ipairs(getVehicleCompatibleUpgrades(vehicle)) do
		slotName = getVehicleUpgradeSlotName(upgrade)
		group = table.find(compatibleUpgrades, 'name', slotName)
		if not group then
			group = { 'group', name = slotName, children = {} }
			table.insert(compatibleUpgrades, group)
		else
			group = compatibleUpgrades[group]
		end
		table.insert(group.children, { id = upgrade, installed = table.find(installedUpgrades, upgrade) ~= false })
	end
	table.sort(compatibleUpgrades, function(a, b) return a.name < b.name end)
	bindGridListToTable(wndUpgrades, 'upgradelist', compatibleUpgrades, true)
end

function selectUpgrade(leaf)
	setControlText(wndUpgrades, 'addremove', leaf.installed and 'Kaldır' or 'Ekle')
end

function addRemoveUpgrade(selUpgrade)
	-- Add or remove selected upgrade
	local vehicle = getPedOccupiedVehicle(localPlayer)
	if not vehicle then
		return
	end

	if not selUpgrade then
		selUpgrade = getSelectedGridListLeaf(wndUpgrades, 'upgradelist')
		if not selUpgrade then
			return
		end
	end

	if selUpgrade.installed then
		-- remove upgrade
		selUpgrade.installed = false
		setControlText(wndUpgrades, 'addremove', 'Ekle')
		server.removeVehicleUpgrade(vehicle, selUpgrade.id)
	else
		-- add upgrade
		local prevUpgradeIndex = table.find(selUpgrade.siblings, 'installed', true)
		if prevUpgradeIndex then
			selUpgrade.siblings[prevUpgradeIndex].installed = false
		end
		selUpgrade.installed = true
		setControlText(wndUpgrades, 'addremove', 'Kaldır')
		server.addVehicleUpgrade(vehicle, selUpgrade.id)
	end
end

wndUpgrades = {
	'wnd',
	text = 'Modifiye',
	width = 300,
	x = -20,
	y = 0.3,
	controls = {
		{
			'lst',
			id='upgradelist',
			width=280,
			height=340,
			columns={
				{text='Ekle', attr='id', width=0.6},
				{text='Eklimi', attr='installed', width=0.3, enablemodify=true}
			},
			onitemclick=selectUpgrade,
			onitemdoubleclick=addRemoveUpgrade,
			DoubleClickSpamProtected=true
		},
		{'btn', id='addremove', text='Ekle', width=135, onclick=addRemoveUpgrade,ClickSpamProtected=true},
		{'btn', id='Kapat', closeswindow=true, width=135}
	},
	oncreate = upgradesInit
}

function addUpgradeCommand(cmd, upgrade)
	local vehicle = getPedOccupiedVehicle(localPlayer)
	if vehicle and upgrade then
		server.addVehicleUpgrade(vehicle, tonumber(upgrade) or 0)
	end
end
addCommandHandler('addupgrade', addUpgradeCommand)
addCommandHandler('au', addUpgradeCommand)

function removeUpgradeCommand(cmd, upgrade)
	local vehicle = getPedOccupiedVehicle(localPlayer)
	if vehicle and upgrade then
		server.removeVehicleUpgrade(vehicle, tonumber(upgrade) or 0)
	end
end
addCommandHandler('removeupgrade', removeUpgradeCommand)
addCommandHandler('ru', removeUpgradeCommand)

---------------------------
-- Toggle lights
---------------------------
function forceLightsOn()
	local vehicle = getPedOccupiedVehicle(localPlayer)
	if not vehicle then
		return
	end
	if guiCheckBoxGetSelected(getControl(wndMain, 'lightson')) then
		server.setVehicleOverrideLights(vehicle, 2)
		guiCheckBoxSetSelected(getControl(wndMain, 'lightsoff'), false)
	else
		server.setVehicleOverrideLights(vehicle, 0)
	end
end

function forceLightsOff()
	local vehicle = getPedOccupiedVehicle(localPlayer)
	if not vehicle then
		return
	end
	if guiCheckBoxGetSelected(getControl(wndMain, 'lightsoff')) then
		server.setVehicleOverrideLights(vehicle, 1)
		guiCheckBoxSetSelected(getControl(wndMain, 'lightson'), false)
	else
		server.setVehicleOverrideLights(vehicle, 0)
	end
end


---------------------------
-- Color
---------------------------

function setColorCommand(cmd, ...)
	local vehicle = getPedOccupiedVehicle(localPlayer)
	if not vehicle then
		return
	end
	local colors = { getVehicleColor(vehicle) }
	local args = { ... }
	for i=1,12 do
		colors[i] = args[i] and tonumber(args[i]) or colors[i]
	end
	server.setVehicleColor(vehicle, unpack(colors))
end
addCommandHandler('color', setColorCommand)
addCommandHandler('cl', setColorCommand)

function openColorPicker()
	editingVehicle = getPedOccupiedVehicle(localPlayer)
	if (editingVehicle) then
		colorPicker.openSelect(colors)
	end
end

function closedColorPicker()
	local r1, g1, b1, r2, g2, b2, r3, g3, b3, r4, g4, b4 = getVehicleColor(editingVehicle, true)
	server.setVehicleColor(editingVehicle, r1, g1, b1, r2, g2, b2, r3, g3, b3, r4, g4, b4)
	local r, g, b = getVehicleHeadLightColor(editingVehicle)
	server.setVehicleHeadLightColor(editingVehicle, r, g, b)
	editingVehicle = nil
end

local r6,g6,b6,r7,g7,b7
function updateColor()
	if (not colorPicker.isSelectOpen) then return end
	local r, g, b = colorPicker.updateTempColors()
	if (editingVehicle and isElement(editingVehicle)) then
		local r1, g1, b1, r2, g2, b2, r3, g3, b3, r4, g4, b4  = getVehicleColor(editingVehicle, true)
		if (guiCheckBoxGetSelected(checkColor1)) then
			r1, g1, b1 = r, g, b
		end
		if (guiCheckBoxGetSelected(checkColor2)) then
			r2, g2, b2 = r, g, b
		end
		if (guiCheckBoxGetSelected(checkColor3)) then
			r3, g3, b3 = r, g, b
		end
		if (guiCheckBoxGetSelected(checkColor4)) then
			r4, g4, b4 = r, g, b
		end
		if (guiCheckBoxGetSelected(checkColor5)) then
			setVehicleHeadLightColor(editingVehicle, r, g, b)
		end
		if (guiCheckBoxGetSelected(checkColor6)) then
			if (r6 ~= r) or (g6 ~= g) or (b6 ~= b) then
				r6,g6,b6 = r, g, b
				setElementData(editingVehicle,"WheelsColorF",{r/255,g/255,b/255})
				setElementData(editingVehicle,"WheelsColorR",{r/255,g/255,b/255})
			end	
		end
		setVehicleColor(editingVehicle, r1, g1, b1, r2, g2, b2, r3, g3, b3, r4, g4, b4)
	end
end
addEventHandler("onClientRender", root, updateColor)

---------------------------
-- Paintjob
---------------------------

function paintjobInit()
	local vehicle = getPedOccupiedVehicle(localPlayer)
	if not vehicle then
		errMsg('You need to be in a car to change its paintjob.')
		closeWindow(wndPaintjob)
		return
	end
	local paint = getVehiclePaintjob(vehicle)
	if paint then
		guiGridListSetSelectedItem(getControl(wndPaintjob, 'paintjoblist'), paint+1, 1)
	end
end

function applyPaintjob(paint)
	server.setVehiclePaintjob(getPedOccupiedVehicle(localPlayer), paint.id)
end

wndPaintjob = {
	'wnd',
	text = 'Car paintjob',
	width = 220,
	x = -20,
	y = 0.3,
	controls = {
		{
			'lst',
			id='paintjoblist',
			width=200,
			height=130,
			columns={
				{text='Paintjob ID', attr='id'}
			},
			rows={
				{id=0},
				{id=1},
				{id=2},
				{id=3}
			},
			onitemclick=applyPaintjob,
			ClickSpamProtected=true,
			ondoubleclick=function() closeWindow(wndPaintjob) end
		},
		{'btn', id='close', closeswindow=true},
	},
	oncreate = paintjobInit
}

function setPaintjobCommand(cmd, paint)
	local vehicle = getPedOccupiedVehicle(localPlayer)
	paint = paint and tonumber(paint)
	if not paint or not vehicle then
		return
	end
	server.setVehiclePaintjob(vehicle, paint)
end
addCommandHandler('paintjob', setPaintjobCommand)
addCommandHandler('pj', setPaintjobCommand)

---------------------------
-- Time
---------------------------
function timeInit()
	local hours, minutes = getTime()
	setControlNumbers(wndTime, { hours = hours, minutes = minutes })
end

function selectTime(leaf)
	setControlNumbers(wndTime, { hours = leaf.h, minutes = leaf.m })
end

function applyTime()
	local hours, minutes = getControlNumbers(wndTime, { 'hours', 'minutes' })
	setTime(hours, minutes)
	closeWindow(wndTime)
end

wndTime = {
	'wnd',
	text = 'Set time',
	width = 220,
	controls = {
		{
			'lst',
			id='timelist',
			width=200,
			height=150,
			columns={
				{text='Time', attr='name'}
			},
			rows={
				{name='Midnight',  h=0, m=0},
				{name='Dawn',      h=5, m=0},
				{name='Morning',   h=9, m=0},
				{name='Noon',      h=12, m=0},
				{name='Afternoon', h=15, m=0},
				{name='Evening',   h=20, m=0},
				{name='Night',     h=22, m=0}
			},
			onitemclick=selectTime,
			ondoubleclick=applyTime
		},
		{'txt', id='hours', text='', width=40},
		{'lbl', text=':'},
		{'txt', id='minutes', text='', width=40},
		{'btn', id='ok', onclick=applyTime},
		{'btn', id='cancel', closeswindow=true}
	},
	oncreate = timeInit
}

function setTimeCommand(cmd, hours, minutes)
	if not hours then
		return
	end
	local curHours, curMinutes = getTime()
	hours = tonumber(hours) or curHours
	minutes = minutes and tonumber(minutes) or curMinutes
	setTime(hours, minutes)
end
addCommandHandler('saat', setTimeCommand)
addCommandHandler('st', setTimeCommand)

function toggleFreezeTime()
	local state = guiCheckBoxGetSelected(getControl(wndMain, 'freezetime'))
	guiCheckBoxSetSelected(getControl(wndMain, 'freezetime'), not state)
	setTimeFrozen(state)
end

function setTimeFrozen(state, h, m, w)
	guiCheckBoxSetSelected(getControl(wndMain, 'freezetime'), state)
	if state then
		if not g_TimeFreezeTimer then
			g_TimeFreezeTimer = setTimer(function() setTime(h, m) setWeather(w) end, 5000, 0)
			setMinuteDuration(9001)
		end
	else
		if g_TimeFreezeTimer then
			killTimer(g_TimeFreezeTimer)
			g_TimeFreezeTimer = nil
		end
		setMinuteDuration(1000)
	end
end

---------------------------
-- Weather
---------------------------
function applyWeather(leaf)
	if not leaf then
		leaf = getSelectedGridListLeaf(wndWeather, 'weatherlist')
		if not leaf then
			return
		end
	end
	setWeather(leaf.id)
	closeWindow(wndWeather)
end

wndWeather = {
	'wnd',
	text = 'Set weather',
	width = 250,
	controls = {
		{
			'lst',
			id='weatherlist',
			width=230,
			height=290,
			columns = {
				{text='Weather type', attr='name'}
			},
			rows={xml='data/weather.xml', attrs={'id', 'name'}},
			onitemdoubleclick=applyWeather
		},
		{'btn', id='ok', onclick=applyWeather},
		{'btn', id='cancel', closeswindow=true}
	}
}

function setWeatherCommand(cmd, weather)
	weather = weather and tonumber(weather)
	if weather then
		setWeather(weather)
	end
end
addCommandHandler('setweather', setWeatherCommand)
addCommandHandler('sw', setWeatherCommand)

---------------------------
-- Game speed
---------------------------

function setMyGameSpeed(speed)

	speed = speed and tonumber(speed) or 1

	if g_settings["gamespeed/enabled"] then
		if speed > g_settings["gamespeed/max"] then
			errMsg(('Maximum allowed gamespeed is %.5f'):format(g_settings['gamespeed/max']))
		elseif speed < g_settings["gamespeed/min"] then
			errMsg(('Minimum allowed gamespeed is %.5f'):format(g_settings['gamespeed/min']))
		else
			setGameSpeed(speed)
		end
	else
		errMsg("Setting game speed is disallowed!")
	end

end

function gameSpeedInit()
	setControlNumber(wndGameSpeed, 'speed', getGameSpeed())
end

function selectGameSpeed(leaf)
	setControlNumber(wndGameSpeed, 'speed', leaf.id)
end

function applyGameSpeed()
	speed = getControlNumber(wndGameSpeed, 'speed')
	if speed then
		setMyGameSpeed(speed)
	end
	closeWindow(wndGameSpeed)
end

wndGameSpeed = {
	'wnd',
	text = 'Set game speed',
	width = 220,
	controls = {
		{
			'lst',
			id='speedlist',
			width=200,
			height=150,
			columns={
				{text='Speed', attr='name'}
			},
			rows={
				{id=3, name='3x'},
				{id=2, name='2x'},
				{id=1, name='1x'},
				{id=0.5, name='0.5x'}
			},
			onitemclick=selectGameSpeed,
			ondoubleclick=applyGameSpeed
		},
		{'txt', id='speed', text='', width=40},
		{'btn', id='ok', onclick=applyGameSpeed},
		{'btn', id='cancel', closeswindow=true}
	},
	oncreate = gameSpeedInit
}

---------------------------
-- Chat Gizle
---------------------------

local isChatVisible = true
   function chat()
  if isChatVisible then
    showChat(false)
    isChatVisible = false
  else
    showChat(true)
    isChatVisible = true
  end
end
---------------------------
-- Main window
---------------------------

function toggleWarping()

	local state = guiCheckBoxGetSelected( getControl(wndMain, 'disablewarp') )
	triggerServerEvent("onFreeroamLocalSettingChange",localPlayer,"warping",state)
	outputChatBox("Artık diğer oyuncular yanına "..(state and "ışınlanamaz" or "ışınlanabilir"),0,102,255)

end

function toggleKnifing()

	local state = guiCheckBoxGetSelected( getControl(wndMain, 'disableknife') )
	triggerServerEvent("onFreeroamLocalSettingChange",localPlayer,"knifing",state)
	outputChatBox("Ölümsüzlük Koruması "..(state and "Aktif" or "Kapalı"),0,102,255)

end

function toggleGhostmode()

	local state = guiCheckBoxGetSelected( getControl(wndMain, 'antiram') )
	triggerServerEvent("onFreeroamLocalSettingChange",localPlayer,"ghostmode",state)
	outputChatBox("Araç Hayalet Modu "..(state and "Aktif" or "Kapalı"),0,102,255)


end

function updateGUI(updateVehicle)
	-- update position
	local x, y, z = getElementPosition(localPlayer)
	setControlNumbers(wndMain, {xpos=math.ceil(x), ypos=math.ceil(y), zpos=math.ceil(z)})

	-- update jetpack toggle
	guiCheckBoxSetSelected( getControl(wndMain, 'jetpack'), doesPedHaveJetPack(localPlayer) )
end

function mainWndShow()
	if not getPedOccupiedVehicle(localPlayer) then
		hideControls(wndMain, 'repair', 'flip', 'upgrades', 'color', 'paintjob', 'lightson', 'lightsoff')
	end
	updateTimer = updateTimer or setTimer(updateGUI, 2000, 0)
	updateGUI(true)
end

function mainWndClose()
	killTimer(updateTimer)
	updateTimer = nil
	colorPicker.closeSelect()
end

function hasDriverGhost(vehicle)

	if not g_PlayerData then return end
	if not isElement(vehicle) then return end
	if getElementType(vehicle) ~= "vehicle" then return end

	local driver = getVehicleController(vehicle)
	if g_PlayerData[driver] and g_PlayerData[driver].ghostmode then return true end
	return false

end

function onEnterVehicle(vehicle,seat)
	if source == localPlayer then
		showControls(wndMain, 'repair', 'flip', 'upgrades', 'color', 'paintjob', 'lightson', 'lightsoff')
		guiCheckBoxSetSelected(getControl(wndMain, 'lightson'), getVehicleOverrideLights(vehicle) == 2)
		guiCheckBoxSetSelected(getControl(wndMain, 'lightsoff'), getVehicleOverrideLights(vehicle) == 1)
	end
	if seat == 0 and g_PlayerData[source] then
		setVehicleGhost(vehicle,hasDriverGhost(vehicle))
	end
end

function onExitVehicle(vehicle,seat)
	if (eventName == "onClientPlayerVehicleExit" and source == localPlayer) or (eventName == "onClientElementDestroy" and getElementType(source) == "vehicle" and getPedOccupiedVehicle(localPlayer) == source) then
		hideControls(wndMain, 'repair', 'flip', 'upgrades', 'color', 'paintjob', 'lightson', 'lightsoff')
		closeWindow(wndUpgrades)
		closeWindow(wndColor)
	elseif vehicle and seat == 0 then
		if source and g_PlayerData[source] then
			setVehicleGhost(vehicle,hasDriverGhost(vehicle))
		end
	end
end

function killLocalPlayer()
if getElementData(localPlayer,"eventsystem:paintballspawn") == true then  return false end
if getElementData(localPlayer,"işlemyapıor") == true then return end
	if g_settings["kill"] then
		setElementHealth(localPlayer,0)
	else
		errMsg("Killing yourself is disallowed!")
	end
end
addCommandHandler('kill', killLocalPlayer)

function kamberPanel()
	triggerEvent("JantOzellestirme:KamberPanel",resourceRoot)
end

function kaplamapaneli()
	triggerEvent("arackaplama.panelac",resourceRoot)
end

function maskepaneli()
maskescpanel()
showCursor(true)
end

function kornapaneli()
	exports["korna"]:sistem4ackapat()
end

function modlarpaneli()
	exports["[AF]modloader"]:sistem5ackapat()
end

function modlarpaneli2()
	exports["[AF]tuning"]:sistem6ackapat()
end
function aracKontrol()
	triggerEvent("AracKontrol:Panel",resourceRoot)

end
function modmanegeac()
	exports["ModKapatma"]:sistem4ackapat()
end

wndMain = {
	'wnd',
	text = 'Oyuncu Paneli',
	x = 10,
	y = 190,
	width = 277,
	controls = {
		{'btn', id='kill', text='Öldür', onclick=killLocalPlayer, width = 125, height = 19},
		{'btn', id='anim', text='Animasyonlar', window=wndAnim, width = 125, height = 19},
		
		{'btn', id='skin', text='Karakterler', window=wndSkin, width = 125, height = 19},
		{'btn', id='clothes', text='Kıyafetler', window=wndClothes, width = 125, height = 19},
		{'btn', id='question', text='Sunucu Hakkında', window=wndQuestion, width = 255, height = 19},
		{'btn', id='gorevlist', text='Görevler', window=wndGorevler, width = 255, height = 19},
		
		{'btn', id='setWalking', text='Yürüyüş Stilleri', window=wndWalking, width = 255, height = 19},		
		{'chk', id='disableknife', text='Dokunulmazlık', onclick=toggleKnifing, width = 120, height = 19},
		{'chk', id='antiram', text='Araba Koruma', onclick=toggleGhostmode, width = 125,x = 165},
		{'btn', id='setpos', text='Harita', window=wndSetPos, width = 255, height = 30, height = 19},	
		{'btn', id='playerlist', text='S*x Sistemi', window=wndSex, width = 255, height = 19},	
		
		{'btn', id='createvehicle', text='Araba Oluştur', window=wndCreateVehicle, width = 255, height = 19},
		{'btn', id='repair', text='Tamir', onclick=repairVehicle, width = 125, height = 19},
		{'btn', id='flip', text='Çevir', onclick=flipVehicle, width = 125, height = 19},
		{'br'}, 
		{'btn', id='upgrades', text='Modifiye', window=wndUpgrades, width = 125, height = 19},
		{'btn', id='color', text='Renk', onclick=openColorPicker, width = 125, height = 19},
		{'chk', id='lightson', text='Farı Aç', onclick=forceLightsOn, width = 105,x = 10},
		{'chk', id='lightsoff', text='Farı Kapat', onclick=forceLightsOff, width = 105,x = 185},
		
		
		
	},
	onclose = mainWndClose
}

disableBySetting =
{
	{parent=wndMain, id="antiram"},
	{parent=wndMain, id="disablewarp"},
	{parent=wndMain, id="disableknife"},
}

function errMsg(msg)
	outputChatBox(msg,0,102,255)
end


addEventHandler('onClientResourceStart', resourceRoot,
	function()
		fadeCamera(true)
		getPlayers()
		setJetpackMaxHeight ( 9001 )
		triggerServerEvent('onLoadedAtClient', resourceRoot)
		createWindow(wndMain)
		hideAllWindows()
		bindKey('f1', 'down', toggleFRWindow)
		guiCheckBoxSetSelected(getControl(wndMain, 'jetpack'), doesPedHaveJetPack(localPlayer))
		guiCheckBoxSetSelected(getControl(wndMain, 'falloff'), canPedBeKnockedOffBike(localPlayer))
	end
)

function showWelcomeMap()
	--createWindow(wndSpawnMap)
	--showCursor(true)
end

function showMap()
	createWindow(wndSetPos)
	showCursor(true)
end

function toggleFRWindow()
if getElementData(localPlayer,"Turf") then return false
end
	if isWindowOpen(wndMain) then
		showCursor(false)
		hideAllWindows()
		colorPicker.closeSelect()
		triggerEvent("wheelSystem:setWindowState",root,false)
		triggerEvent("sexsistemi:paneldurum",root,false)
		triggerEvent("kornasistemi:paneldurum",root,false)
		triggerEvent("modsistem:paneldurum",root,false)
		triggerEvent("arackaplamasistemi:paneldurum",root,false)
		triggerEvent("plakasistemi:servertrigeryolla",root,false)
	else
		if guiGetInputMode() ~= "no_binds_when_editing" then
			guiSetInputMode("no_binds_when_editing")
		end
		showCursor(true)
		showAllWindows()
	end
end

addCommandHandler('fr', toggleFRWindow)

function getPlayers()
	g_PlayerData = {}
	table.each(getElementsByType('player'), joinHandler)
end

function joinHandler(player)
	if (not g_PlayerData) then return end
	g_PlayerData[player or source] = { name = getPlayerName(player or source), gui = {} }
end

function quitHandler()
	if (not g_PlayerData) then return end
	local veh = getPedOccupiedVehicle(source)
	local seat = (veh and getVehicleController(veh) == localPlayer) and 0 or 1
	if seat == 0 then
		onExitVehicle(veh,0)
	end
	table.each(g_PlayerData[source].gui, destroyElement)
	g_PlayerData[source] = nil
end

function wastedHandler()
	if source == localPlayer then
		onExitVehicle()
		if g_settings["spawnmapondeath"] then
			setTimer(showMap,2000,1)
		end
	else
		local veh = getPedOccupiedVehicle(source)
		local seat = (veh and getVehicleController(veh) == localPlayer) and 0 or 1
		if seat == 0 then
			onExitVehicle(veh,0)
		end
	end
end

local function removeForcedFade()
	removeEventHandler("onClientPreRender",root,forceFade)
	fadeCamera(true)
end

local function checkCustomSpawn()

	if type(customSpawnTable) == "table" then
		local x,y,z = unpack(customSpawnTable)
		setPlayerPosition(x,y,z,true)
		customSpawnTable = false
		setTimer(removeForcedFade,100,1)
	end

end

addEventHandler('onClientPlayerJoin', root, joinHandler)
addEventHandler('onClientPlayerQuit', root, quitHandler)
addEventHandler('onClientPlayerWasted', root, wastedHandler)
addEventHandler('onClientPlayerVehicleEnter', root, onEnterVehicle)
addEventHandler('onClientPlayerVehicleExit', root, onExitVehicle)
addEventHandler("onClientElementDestroy", root, onExitVehicle)
addEventHandler("onClientPlayerSpawn", localPlayer, checkCustomSpawn)

function getPlayerName(player)
	return g_settings["removeHex"] and player.name:gsub("#%x%x%x%x%x%x","") or player.name
end

addEventHandler('onClientResourceStop', resourceRoot,
	function()
		showCursor(false)
		setPedAnimation(localPlayer, false)
	end
)

function setVehicleGhost(sourceVehicle,value)

	  local vehicles = getElementsByType("vehicle")
	  for _,vehicle in ipairs(vehicles) do
		local vehicleGhost = hasDriverGhost(vehicle)
		if isElement(sourceVehicle) and isElement(vehicle) then
		   setElementCollidableWith(sourceVehicle,vehicle,not value)
		   setElementCollidableWith(vehicle,sourceVehicle,not value)
		end
		if value == false and vehicleGhost == true and isElement(sourceVehicle) and isElement(vehicle) then
			setElementCollidableWith(sourceVehicle,vehicle,not vehicleGhost)
			setElementCollidableWith(vehicle,sourceVehicle,not vehicleGhost)
		end
	end

end

local function onStreamIn()

	if source.type ~= "vehicle" then return end
	setVehicleGhost(source,hasDriverGhost(source))

end

local function onLocalSettingChange(key,value)

	g_PlayerData[source][key] = value

	if key == "ghostmode" then
		local sourceVehicle = getPedOccupiedVehicle(source)
		if sourceVehicle then
			setVehicleGhost(sourceVehicle,hasDriverGhost(sourceVehicle))
		end
	end

end

local function renderKnifingTag()
	if not g_PlayerData then return end
	for _,p in ipairs (getElementsByType ("player", root, true)) do
		if g_PlayerData[p] and g_PlayerData[p].knifing then
			local px,py,pz = getElementPosition(p)
			local x,y,d = getScreenFromWorldPosition (px, py, pz+1.3)
			if x and y and d < 20 then
				--dxDrawText ("Disabled Knifing", x+1, y+1, x, y, tocolor (0, 0, 0), 0.5, "bankgothic", "center")
				--dxDrawText ("Disabled Knifing", x, y, x, y, tocolor (220, 220, 0), 0.5, "bankgothic", "center")
			end
		end
    end
end

addEventHandler ("onClientRender", root, renderKnifingTag)

addEvent("onClientFreeroamLocalSettingChange",true)
addEventHandler("onClientFreeroamLocalSettingChange",root,onLocalSettingChange)
addEventHandler("onClientPlayerStealthKill",localPlayer,cancelKnifeEvent)
addEventHandler("onClientElementStreamIn",root,onStreamIn)

function windowf1_closeserius()
	showCursor(false)
	hideAllWindows()
	guiSetVisible(OyuncuKontrolleri, false)
end
-- Your Date and Time
---------------------->>
local game_time	= ""	-- Game Date and Time
local date_ = ""		-- Client Date and Time
local uptime = getRealTime().timestamp

function getMonthName(month, digits)
	if month < 10 then month = "0"..month end
	return month
end

function totime(timestamp)
	local timestamp = timestamp - (math.floor(timestamp/86400) * 86400)
	local hours = math.floor(timestamp/3600)
	timestamp = timestamp - (math.floor(timestamp/3600) * 3600)
	local mins = math.floor(timestamp/60)
	local secs = timestamp - (math.floor(timestamp/60) * 60)
	return hours, mins, secs
end

function updateDateAndTime()
	local t = getRealTime()
	local day = t.monthday
	if (day < 10) then day = "0"..day end
	local hr = t.hour
	if (hr < 10) then hr = "0"..hr end
	local mins = t.minute
	if (mins < 10) then mins = "0"..mins end
	local sec = t.second
	if (sec < 10) then sec = "0"..sec end
	
	local uptime_ = t.timestamp - uptime
	local hrs_, mins_, secs_ = totime(uptime_)
	if (hrs_ < 10) then hrs_ = "0"..hrs_ end
	if (mins_ < 10) then mins_ = "0"..mins_ end
	if (secs_ < 10) then secs_ = "0"..secs_ end
	-- date_ = day.."/"..getMonthName(t.month+1).."/"..(t.year+1900).." — "..hr..":"..mins..":"..sec.." (Online: "..hrs_..":"..mins_..":"..secs_..")"
	date_ = day.."/"..getMonthName(t.month+1).."/"..(t.year+1900)
end

addEventHandler("onClientRender", root, renderGTIVersion)











local havingSex = {}
local istekler = {}
local bilgi = {}

function funTime(gonderilen, gonderen, cx, cy, cz, sx, sy, sz,dim,int, istek)
	if (gonderilen and gonderen) then
		removePedFromVehicle(gonderilen)
		removePedFromVehicle(gonderen)
		setPedAnimation(gonderilen)
		setPedAnimation(gonderen)
		randDim = math.random(100,6553)
		if (istek ==  "Sakso") then
			setElementInterior(gonderilen, 2)
			setElementInterior(gonderen, 2)
			setPedRotation(gonderilen, 149)
			setPedRotation(gonderen, 333)
			setInitialAnimation(gonderilen, gonderen, 1)
			setTimer(setInitialAnimation, 250, 3, gonderilen, gonderen, 1)
		elseif (istek ==  "Normal") then
			setElementInterior(gonderilen, 3)
			setElementInterior(gonderen, 3)
			setPedRotation(gonderilen, 0)
			setPedRotation(gonderen, 180)
			setInitialAnimation(gonderilen, gonderen, 2)
			setTimer(setInitialAnimation, 250, 3, gonderilen, gonderen, 5)	
		end
		setElementDimension(gonderilen, randDim)
		setElementDimension(gonderen, randDim)
		setElementData(gonderilen,"Durum","Sexde")
		setElementData(gonderen,"Durum","Sexde")
		setTimer(fadeCamera, 26000, 1, gonderilen, false, 4)
		setTimer(fadeCamera, 26000, 1, gonderen, false, 4)
		setTimer(endSex, 30000, 1, gonderilen, gonderen, cx, cy, cz, sx, sy, sz,dim,int)
		fadeCamera(gonderilen, true, 4)
		fadeCamera(gonderen, true, 4)
	end
end

function setInitialAnimation(client,slut,id)
	if id == 1 then
		setElementPosition(slut,1203.87415, 16.05066, 1000.92188)
		setPedAnimation(slut,"BLOWJOBZ","BJ_COUCH_LOOP_W",-1, true, false, false)
		setElementPosition(client,1204.21277, 16.89031, 1000.92188)
		setPedAnimation(client,"BLOWJOBZ","BJ_COUCH_LOOP_P",-1, true, false, false)
	elseif id == 5 then
		setElementPosition(slut,952.493, -43.5, 1001)
		setPedAnimation(slut,"sex","sex_1_cum_w",-1, true, false, false)
		setElementPosition(client,952.493, -44.5, 1001)
		setPedAnimation(client,"sex","sex_1_cum_p",-1, true, false, false)
	end
end

function endSex(client, slut, cx, cy, cz, sx, sy, sz,dim,int)
	havingSex[client] = nil
	havingSex[slut] = nil
	if istekler[slut] then istekler[slut] = nil end				
    if istekler[client] then istekler[client] = nil end	
	if (isElement(client)) then
		triggerClientEvent(client,"FreeroamSex:SexBitti",client)
		toggleAllControls(client, true, true, false)
		setPedAnimation(client)
		setCameraTarget(client)
		setElementPosition(client, cx, cy, cz)
		setElementInterior(client, int)
		fadeCamera(client, true, 4)
		setElementFrozen(client, false)
		setElementDimension(client, dim)
		setElementData(client, "Sex", nil)
		showCursor(client, false)
		setCameraTarget(client)
		setElementData(client,"Durum","Oynuyor")
	end
	if (isElement(slut)) then
		triggerClientEvent(slut,"FreeroamSex:SexBitti",slut)
		toggleAllControls(slut, true, true, false)
		setPedAnimation(slut)
		setCameraTarget(slut)
		setElementPosition(slut, sx, sy, sz)
		setElementInterior(slut, int)
		fadeCamera(slut, true, 4)
		setElementFrozen(slut, false)
		setElementDimension(slut, dim)
		setElementData(slut, "Sex", nil)
		showCursor(slut, false)
		setCameraTarget(slut)
		setElementData(slut,"Durum","Oynuyor")
	end
end


addEvent("CevapOnay", true)
function OnayCevap(gonderen, cevap, istek)
    if cevap == "Evet" then
		if (istekler[client] and istekler[gonderen]) then
			if (havingSex[source]) then return end
			local cx,cy,cz = getElementPosition(client)
			local sx,sy,sz = getElementPosition(gonderen)
			local dim,int = getElementDimension(client),getElementInterior(gonderen)
			setTimer(funTime, 2000, 1, client, gonderen, cx, cy, cz, sx, sy, sz,dim,int, istek)
			outputChatBox("Eğer GTA SA 1.00 versiyonunu kullanmıyosan sex animasyonlarını göremezsin.",gonderen, 153, 0, 51)
			outputChatBox( "Eğer GTA SA 1.00 versiyonunu kullanmıyosan sex animasyonlarını göremezsin.",client, 153, 0, 51)
			fadeCamera(client, false, 2)
			fadeCamera(gonderen, false, 2)
			toggleAllControls(client, false, true, false)
			toggleAllControls(gonderen, false, true, false)
			havingSex[client] = true
			havingSex[gonderen] = true
			setElementData(client, "Sex", true)
			setElementData(gonderen, "Sex", true)
			-- setTimer(showCursor, 4000,1, client, true)
			-- setTimer(showCursor, 4000,1, gonderen, true)
			if istekler[gonderen] then istekler[gonderen] = nil end				
			if istekler[client] then istekler[client] = nil end
			triggerClientEvent(gonderen,"FreeroamSex:SexBasladi",gonderen)
		end
	elseif cevap == "Hayır" then
		if istekler[gonderen] then istekler[gonderen] = nil end				
        if istekler[client] then istekler[client] = nil end
	end
end
addEventHandler("CevapOnay", root, OnayCevap)


addEvent("FreeroamSex:ServerIstek", true)
addEventHandler("FreeroamSex:ServerIstek", root, function(gonderilen, istek)
	if (istekler[gonderilen]) then return outputChatBox("#990033[✘] #ffffffBu oyuncunun zaten bir isteği var.",client, 255, 0, 255, true) end
	if (istekler[client]) then return outputChatBox("#990033[✘] #ffffffZaten başka birisine istek göndermişsin!.",client, 255, 0, 255, true) end
	istekler[gonderilen] = client
	istekler[client] = gonderilen
	triggerClientEvent(gonderilen, "FreeroamSex:ClientGoster", gonderilen, client, istek)
end)


addEventHandler("onPlayerQuit", root, function()
	local istek = istekler[source]
	if istek then
		istekler[istek] = nil
		istekler[source] = nil
	end
end)

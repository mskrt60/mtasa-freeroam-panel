---------------------------
-- Sex
---------------------------
local sx, sy = guiGetScreenSize()
local pg, pu = 290,100
local x,y = (sx-pg), (sy-pu)-10
local sureTimer,sexistek,sexgonderen = nil,nil,nil
aSpectator = { Offset = 5, AngleX = 0, AngleZ = 30, Spectating = nil }


local arkaplan = guiCreateWindow(x,y, pg, pu, "Gelen Sex İsteği", false)
guiSetVisible(arkaplan, false)
local evet = guiCreateButton(10, 69, pg/2-20, 25, "Evet", false, arkaplan)
local hayir = guiCreateButton(150, 69, pg/2-20, 25, "Hayır", false, arkaplan)

local plrisim = guiCreateLabel(71, 20, 135, 15, "", false, arkaplan)
guiLabelSetColor(plrisim, 83, 168, 48)
guiLabelSetHorizontalAlign(plrisim, "center", false)

local istekyazi = guiCreateLabel(8, 38, 272, 21, "(4km ötede) sana sikiş isteği gönderdi", false, arkaplan)
guiLabelSetColor(istekyazi, 153, 0, 51)
guiLabelSetHorizontalAlign(istekyazi, "center", false)

local sure = guiCreateLabel(1, 1, 19, 14, "", false, arkaplan)
guiLabelSetColor(sure, 153, 0, 51)	

addEventHandler("onClientGUIClick", resourceRoot, function() 
	if source == evet then
		triggerServerEvent("CevapOnay", resourceRoot, sexgonderen, "Evet", sexistek) 
		guiSetVisible(arkaplan, false)
		if isTimer(sureTimer) then killTimer(sureTimer) end	
		aSpectator.Spectating = localPlayer
		aSpectator.Initialize()
	elseif source == hayir then
		triggerServerEvent("CevapOnay", resourceRoot, sexgonderen, "Hayır", sexistek) 
		guiSetVisible(arkaplan, false)
		if isTimer(sureTimer) then killTimer(sureTimer) end	
	end
end)

addEvent("FreeroamSex:ClientGoster", true)
function istekGoster(gonderen, istek)
	guiSetVisible(arkaplan, true)
	local countdown = 15
	guiSetText(sure,tostring(countdown)) guiSetText(plrisim, getPlayerName(gonderen))
	guiSetText(istekyazi, "(4km ötede) sana sikiş("..istek..") isteği gönderdi")	
	sexistek,sexgonderen = istek,gonderen
	
	if isTimer(sureTimer) then killTimer(sureTimer) end
	sureTimer = setTimer(function() 
		if guiGetVisible(arkaplan) == true then	
			countdown = countdown - 1 
			if countdown >= 0 then 
				guiSetText(sure, tostring(countdown)) 
			else 
				guiSetVisible(arkaplan, false)
				if isTimer(sureTimer) then killTimer(sureTimer) end
				triggerServerEvent("CevapOnay", resourceRoot, gonderen, "Hayır") 							
			end
		end	
	end, 1000, 0) 
end
addEventHandler("FreeroamSex:ClientGoster", root, istekGoster)

addEvent("FreeroamSex:SexBitti",true)
addEventHandler("FreeroamSex:SexBitti",root, function()
	aSpectator.Close()
end)
addEvent("FreeroamSex:SexBasladi",true)
addEventHandler("FreeroamSex:SexBasladi",root, function()
	aSpectator.Spectating = localPlayer
	aSpectator.Initialize()
end)

function aSpectator.Initialize()
	bindKey ( "mouse_wheel_up", "down", aSpectator.MoveOffset, -1 )
	bindKey ( "mouse_wheel_down", "down", aSpectator.MoveOffset, 1 )
	bindKey ( "mouse2", "both", aSpectator.Cursor )
    toggleControl ( "fire", false )
    toggleControl ( "aim_weapon", false )
	addEventHandler ( "onClientPlayerWasted", localPlayer, aSpectator.PlayerCheck )
	addEventHandler ( "onClientCursorMove", root, aSpectator.CursorMove )
	addEventHandler ( "onClientPreRender", root, aSpectator.Render )
end
function aSpectator.Close()
	unbindKey ( "mouse_wheel_up", "down", aSpectator.MoveOffset, -1 )
	unbindKey ( "mouse_wheel_down", "down", aSpectator.MoveOffset, 1 )
	unbindKey ( "mouse2", "both", aSpectator.Cursor )
	toggleControl ( "fire", true )
	toggleControl ( "aim_weapon", true )
	removeEventHandler ( "onClientPlayerWasted", localPlayer, aSpectator.PlayerCheck )
	removeEventHandler ( "onClientMouseMove", root, aSpectator.CursorMove )
	removeEventHandler ( "onClientPreRender", root, aSpectator.Render )
	aSpectator.Spectating = nil
end

function aSpectator.PlayerCheck ()
	if ( source == aSpectator.Spectating ) then
		aSpectator.Close()
	end
end

function aSpectator.Cursor ( key, state )
	if state == "down" then
		showCursor(true)
	else
		showCursor(false)
	end
end	
function aSpectator.CursorMove ( rx, ry, x, y )
	if ( not isCursorShowing() ) then
		local sx, sy = guiGetScreenSize ()
		aSpectator.AngleX = ( aSpectator.AngleX + ( x - sx / 2 ) / 10 ) % 360
		aSpectator.AngleZ = ( aSpectator.AngleZ + ( y - sy / 2 ) / 10 ) % 360
		if ( aSpectator.AngleZ > 180 ) then
			if ( aSpectator.AngleZ < 315 ) then aSpectator.AngleZ = 315 end
		else
			if ( aSpectator.AngleZ > 45 ) then aSpectator.AngleZ = 45 end
		end
	end
end
function aSpectator.Render ()
	local sx, sy = guiGetScreenSize ()
	if ( not aSpectator.Spectating ) then
		dxDrawText ( "Nobody to spectate", sx - 170, 200, sx - 170, 200, tocolor ( 255, 0, 0, 255 ), 1 )
		return
	end

	local x, y, z = getElementPosition ( aSpectator.Spectating )

	if ( not x ) then
		dxDrawText ( "Error recieving coordinates", sx - 170, 200, sx - 170, 200, tocolor ( 255, 0, 0, 255 ), 1 )
		return
	end

	local ox, oy, oz
	ox = x - math.sin ( math.rad ( aSpectator.AngleX ) ) * aSpectator.Offset
	oy = y - math.cos ( math.rad ( aSpectator.AngleX ) ) * aSpectator.Offset
	oz = z + math.tan ( math.rad ( aSpectator.AngleZ ) ) * aSpectator.Offset
	setCameraMatrix ( ox, oy, oz, x, y, z )

	local sx, sy = guiGetScreenSize ()
	-- dxDrawText ( "Spectating: "..getPlayerName ( aSpectator.Spectating ), sx - 170, 200, sx - 170, 200, tocolor ( 255, 255, 255, 255 ), 1 )
	-- if ( _DEBUG ) then
		-- dxDrawText ( "DEBUG:\nAngleX: "..aSpectator.AngleX.."\nAngleZ: "..aSpectator.AngleZ.."\n\nOffset: "..aSpectator.Offset.."\nX: "..ox.."\nY: "..oy.."\nZ: "..oz.."\nDist: "..getDistanceBetweenPoints3D ( x, y, z, ox, oy, oz ), sx - 170, sy - 180, sx - 170, sy - 180, tocolor ( 255, 255, 255, 255 ), 1 )
	-- else
		if ( isCursorShowing () ) then
			dxDrawText ( "Tip: mouse2 - serbest kamera modu", 20, sy - 50, 20, sy - 50, tocolor ( 255, 255, 255, 255 ), 1 )
		else
			dxDrawText ( "Tip: yakınlaştırmak/uzaklaştırmak için mouse tekerini kullan", 20, sy - 50, 20, sy - 50, tocolor ( 255, 255, 255, 255 ), 1 )
		end
	-- end
end

function aSpectator.MoveOffset ( key, state, inc )
	if ( not isCursorShowing() ) then
		aSpectator.Offset = aSpectator.Offset + tonumber ( inc )
		if ( aSpectator.Offset > 70 ) then aSpectator.Offset = 70
		elseif ( aSpectator.Offset < 2 ) then aSpectator.Offset = 2 end
	end
end

include("shared.lua")
include("player_class/player_scb.lua")

--[--------------------------------------Localize----------------------------------------]
local rollang = 0
local switch = false
local Inventory = {}
local lPly = LocalPlayer()
local m_bBleed = LocalPlayer():GetNWBool("bleeding")
local m_fBldMult = LocalPlayer():GetNWFloat("bleedmult")
local bAlpha = 0
local m_bBlind = false
local menucl = false
local lCmd = "nil"
local m_iBTimer = 8
local bMax = 8
local m_bLDuck = false
local m_sBlind = false
local sPitch, sYaw = 0, 0
local sJump = false
local leftdown = false
local m_iSprint = 8
local sMult = 1
local resize = (ScrW()/1980)
local ypos = 0
local cpos = 0
local spos = 0
local lLight = 0
local HUDMsg = ""
local HMsgT = 0
local HMsgA = 0
local sanicT = -1


surface.CreateFont("HUDText2", {
        font = "Console",
        size = 15,
        weight = 600,
        shadow = true,
        antialias = false,
        outline = false
});

if InvMenu ~= nil then
	print("InvMenu found deleting...")
	InvMenu:SetDeleteOnClose( true )
	InvMenu:Close()
end
local InvMenu = InvMenu || nil

local hide = {
	CHudHealth = true,
	CHudBattery = true,
	CHudAmmo = true,
	CHudWeaponSelection = true,
}

local bMove = {
	IN_ATTACK,
	IN_JUMP,
	IN_DUCK,
	IN_USE,
	IN_CANCEL,
	IN_ATTACK2,
	IN_RUN,
	IN_RELOAD,
	IN_ALT1,
	IN_ALT2,
	IN_SCORE,
	IN_SPEED,
	IN_WALK,
	IN_ZOOM,
	IN_WEAPON1,
	IN_WEAPON2,
	IN_BULLRUSH,
	IN_GRENADE1,
	IN_GRENADE2,
}


--[END-----------------------------------Localize-------------------------------------END]


--[--------------------------------------Functions---------------------------------------]
local function MouseInArea(minx, miny, maxx, maxy)
    local mousex, mousey = gui.MousePos();
    return(mousex < maxx && mousex > minx && mousey < maxy && mousey > miny);
end

local function hPercent(n, t)
	if n then
		return ((100 - LocalPlayer():Health())/100) *t
	else
		return (LocalPlayer():Health()/100) *t
	end
end

local function checkbuttons(ucmd, force)
	local inputs = 0
	if !force || #force == 0 then return 0 end
	for i = 1, #bMove do
		local newMove = bMove[i]
		if table.HasValue(force,newMove) || ucmd:KeyDown(newMove) then
			inputs = inputs + newMove
		end
	end
	ucmd:SetButtons(inputs)
end

local function Blink(ucmd)
	if ucmd:CommandNumber() ~= 0 then
		m_iBTimer = math.Clamp(m_iBTimer - engine.TickInterval(),0, 10)

		if LocalPlayer():Alive() then
			if sJump|| m_sBlind || bAlpha ~= 255 && m_iBTimer == 0 then
				if bAlpha == 255 then
					m_sBlind = false
				elseif bAlpha == 0 then
					m_sBlind =true
				end
				bAlpha = math.Clamp(bAlpha+ 75, 0, 255)
				if !m_bBlind then
					net.Start("scb_blind")
					net.WriteBool(true)
					net.SendToServer()
					m_bBlind = true
				end
			else
				bAlpha = math.Clamp(bAlpha- 75, 0, 255)
				m_sBlind = false
				if m_bBlind then
					net.Start("scb_blind")
					net.WriteBool(false)
					net.SendToServer()
					m_bBlind = false
				end
			end
		else
			bAlpha = math.Clamp(bAlpha+1, 0, 255)
		end
		if bAlpha == 255 then
			m_iBTimer = bMax
		end
	end
end

local function Sprint(ucmd)
	if LocalPlayer():Crouching() then
		sMult = 1.10
	elseif LocalPlayer():GetVelocity():Length2D() <= 15 then
		sMult = 1.5
	else
		sMult = 1
	end
	if ucmd:CommandNumber() ~= 0 then
		if ucmd:KeyDown(IN_SPEED) && !LocalPlayer():Crouching() && LocalPlayer():GetVelocity():Length2D() > 20 then
			m_iSprint = math.Clamp(m_iSprint- (engine.TickInterval() * (1.3)), 0, 8)
		else
			m_iSprint = math.Clamp(m_iSprint+ (engine.TickInterval()* sMult), 0, 8)
		end
	end
	if m_iSprint == 0 then
		ucmd:RemoveKey(IN_SPEED)
	end
end

local function VisualBlink()
	surface.SetDrawColor(0,0,0,bAlpha)
	surface.DrawRect(-2, -2,ScrW()+5,ScrH()+5)
end

local function VisualHUD()
	local icon = 50 * resize
	surface.SetDrawColor(175,175,175)
	surface.DrawRect(5,ScrH()-((icon+5)*2), icon,icon)
	surface.DrawOutlinedRect(5+icon+ 5,ScrH()-((icon+5)*2), 450* resize,icon)
	surface.DrawOutlinedRect(5+icon+ 6,ScrH()-((icon+5)*2)+1, 450* resize-2,icon-2)
	size = ((450*resize)-14)/(bMax*2)
	if bAlpha ~= 255 then
		surface.SetMaterial(Material( "material/BlinkMeter.jpg" ) )

		btimer = (math.Round((m_iBTimer*2),0))
		for i = 0, btimer-1 do
			surface.DrawTexturedRect(icon+15 + ((size-(1*resize))*(i)),ScrH()-((icon+5)*2)+5, size -4,icon-10)
		end
	end
	surface.SetDrawColor(color_white)
	surface.DrawRect(7,ScrH()-(icon+5+icon+3), icon-4,icon-4)
	surface.SetMaterial(Material( "material/BlinkIcon.png" ) )
	surface.DrawTexturedRect( 7,ScrH()-(icon+5+icon+3), icon-4,icon-4 )

	surface.SetDrawColor(175,175,175)
	surface.DrawRect(5,ScrH()-(icon+5), icon,icon)
	surface.DrawOutlinedRect(5+icon+ 5,ScrH()-( icon+5), 450* resize,icon)
	surface.DrawOutlinedRect(5+icon+ 6,ScrH()-( icon+4), 450* resize-2,icon-2)
	surface.SetMaterial(Material( "material/StaminaMeter.jpg" ) )
	surface.SetDrawColor(color_white)
	stimer = (math.Round(((m_iSprint-((bMax-m_iSprint)/8))*2),0))
	for i = 0, stimer do
		surface.DrawTexturedRect(icon+15 + ((size-(1*resize))*(i)),ScrH()-((icon+5))+5, size -4,icon-10)
	end
	surface.SetDrawColor(color_white)
	surface.SetMaterial(Material( "material/sprinticon.png" ) )
	if LocalPlayer():Crouching() then
		surface.SetMaterial(Material( "material/sneakicon.png" ) )
	end
	surface.DrawTexturedRect(7,ScrH()-(icon+3), icon-4,icon-4)
end

local function DClientText()
	draw.SimpleText( "Player: "..LocalPlayer():Nick(), "BudgetLabel", 5, 5+cpos, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP ); cpos = cpos + 12
	draw.SimpleText( "Health: "..LocalPlayer():Health(), "BudgetLabel", 5, 5+cpos, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP ); cpos = cpos + 12
	if bAlpha == 255 then
		draw.SimpleText( "Blink: "..math.Round(((bAlpha/255)*100), 0).."%", "BudgetLabel", 5, 5+cpos, Color(0,255,0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP ); cpos = cpos + 12
	else
		draw.SimpleText( "Blink: "..math.Round(((bAlpha/255)*100), 0).."%", "BudgetLabel", 5, 5+cpos, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP ); cpos = cpos + 12
	end
	draw.SimpleText( "lClick: "..tostring(leftdown), "BudgetLabel", 5, 5+cpos, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP ); cpos = cpos + 12
	draw.SimpleText( "m_lBlind: "..tostring(m_bBlind), "BudgetLabel", 5, 5+cpos, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP ); cpos = cpos + 12
	draw.SimpleText( "m_iBTimer: "..math.Round(m_iBTimer,2), "BudgetLabel", 5, 5+cpos, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP ); cpos = cpos + 12
	draw.SimpleText( "CurTime: "..math.Round(CurTime(),2), "BudgetLabel", 5, 5+cpos, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP ); cpos = cpos + 12
	draw.SimpleText( "Sway: "..tostring(Angle(math.sin(sPitch)*(hPercent(0, 2)),math.sin(sYaw)*(hPercent(0, 2)),rollang)), "BudgetLabel", 5, 5+cpos, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP ); cpos = cpos + 12
	draw.SimpleText( "b_nButtons: "..tostring(trHit), "BudgetLabel", 5, 5+cpos, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP ); cpos = cpos + 12
	draw.SimpleText( "m_iSPrint: "..m_iSprint, "BudgetLabel", 5, 5+cpos, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP ); cpos = cpos + 12
	draw.SimpleText( "Sprt Mult: "..sMult, "BudgetLabel", 5, 5+cpos, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP ); cpos = cpos + 12
	draw.SimpleText( "lgt Exp: "..tostring(render.GetLightColor(LocalPlayer():GetPos())), "BudgetLabel", 5, 5+cpos, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP ); cpos = cpos + 12
	draw.SimpleText( "HUDTxt: "..HUDMsg, "BudgetLabel", 5, 5+cpos, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP ); cpos = cpos + 12
	draw.SimpleText( "HUDTimer: "..HMsgT, "BudgetLabel", 5, 5+cpos, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP ); cpos = cpos + 12
	draw.SimpleText( "HUDAlpha: "..HMsgA, "BudgetLabel", 5, 5+cpos, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP ); cpos = cpos + 12
end

local function DServerText()
	draw.SimpleText( "n_Bleed: "..tostring(LocalPlayer():GetNWBool("bleeding")), "BudgetLabel", 5+ypos, 5+spos, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP ); spos = spos + 12
	draw.SimpleText( "Bleed Mult: "..tostring(LocalPlayer():GetNWFloat("bleedmult")), "BudgetLabel", 5+ypos, 5+spos, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP ); spos = spos + 12
	if LocalPlayer():GetNWBool("blind") then
		draw.SimpleText( "n_Blind: "..tostring(LocalPlayer():GetNWBool("blind")), "BudgetLabel", 5+ypos, 5+spos, Color(255,255,0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP ); spos = spos + 12
	else
		draw.SimpleText( "n_Blind: "..tostring(LocalPlayer():GetNWBool("blind")), "BudgetLabel", 5+ypos, 5+spos, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP ); spos = spos + 12
	end
	draw.SimpleText( "n_bDuck: "..tostring(LocalPlayer():GetNWBool("m_bDuck")), "BudgetLabel", 5+ypos, 5+spos, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP ); spos = spos + 12
	draw.SimpleText( "n_sDMsg: "..LocalPlayer():GetNWString("m_sDMsg"), "BudgetLabel", 5+ypos, 5+spos, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP ); spos = spos + 12
	draw.SimpleText( "dev_cmd: "..LocalPlayer():GetNWString("dvp"), "BudgetLabel", 5+ypos, 5+spos, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP ); spos = spos + 12
end

local function DebugText()
	
	cpos = 0
	spos = 0
	ypos = 0
	if GetConVarNumber("scb_debug") > 0 || GetConVarString("scb_debug") ~= ""  then
		if GetConVarNumber("scb_debugadmin") == 1  && LocalPlayer():IsAdmin() || GetConVarNumber("scb_debugadmin") == 0 then
			if GetConVarNumber("scb_debug") == 1 || string.lower(GetConVarString("scb_debug")) == "client" then
				draw.SimpleText( "Client", "BudgetLabel", 5, 5+cpos, Color(255,0,0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP ); cpos = cpos + 24;
				DClientText()
			elseif GetConVarNumber("scb_debug") == 2 || string.lower(GetConVarString("scb_debug")) == "server" then
				draw.SimpleText( "Server", "BudgetLabel", 5, 5+spos, Color(0,0,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP ); spos = spos + 24
				DServerText()
			elseif GetConVarNumber("scb_debug") == 3 || string.lower(GetConVarString("scb_debug")) == "both" then
				draw.SimpleText( "Client", "BudgetLabel", 5, 5+cpos, Color(255,0,0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP ); cpos = cpos + 24;ypos = 350
				draw.SimpleText( "Server", "BudgetLabel", 5+ypos, 5+spos, Color(0,0,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP ); spos = spos + 24;
				DClientText()
				DServerText()
			end
		end
	end
end

local function SetHUDText(msg)
	HUDMsg = msg
	HMsgT = 5
	HMsgA = 255
end

local function HUDPrintText()
	if HUDMsg ~= "" then 
		surface.SetFont( "HUDText2" )
		surface.SetTextColor( 200, 200, 200, HMsgA )
		local tw, th = surface.GetTextSize(HUDMsg)
		surface.SetTextPos( (ScrW()-tw)/2, ScrH()-(ScrH()/5) )
		if HMsgA ~= 0 then
			surface.DrawText( HUDMsg )
		end
	end
end
--[END-----------------------------------Functions------------------------------------END]

--[--------------------------------------Networks----------------------------------------]
net.Receive("scb_bleed",function( len, pl)
	local nBleed = net.ReadBool()
	m_bBleed = nBleed
end)

net.Receive("scb_sendmsg",function( len, pl)
	local  msg = net.ReadString()
	SetHUDText(msg)
end)
--[END-----------------------------------Networks-------------------------------------END]

concommand.Add("__sanic",function(ply, cmd, args)
	if sanicT == -1 && LocalPlayer():Alive() then
	print("GOTTA GO FAST!!!")
	net.Start("scb_develope")
	net.WriteString("sanic")
	net.SendToServer()
	SetHUDText("GOTTA GO FAST!")
	sanicT = 30
	end
end, nil,nil,0)

concommand.Add("__suicide",function(ply, cmd, args)
	---print("GOTTA GO FAST!!!")
	net.Start("scb_develope")
	net.WriteString("suicide")
	net.SendToServer()
	SetHUDText("You just couldn't take the pressure.")
end, nil,nil,0)


function GM:SetupSkyboxFog()
	render.FogMode( 1 )
	if LocalPlayer():GetMoveType() == MOVETYPE_NOCLIP then
		render.FogMode( 0 )
	end
	render.FogStart(0)
	render.FogEnd(550)
	render.FogMaxDensity(1)
	return true
end

function GM:SetupWorldFog()
	render.FogMode( 1 )
	if LocalPlayer():GetMoveType() == MOVETYPE_NOCLIP then
		render.FogMode( 0 )
	end
	render.FogStart(0)
	render.FogEnd(550)
	render.FogMaxDensity(1)
	return true
end





function GM:RenderScreenspaceEffects()
		--if !lPly:Alive() then
			DrawMotionBlur( math.Clamp(LocalPlayer():Health()/100, 0.02, 1), math.Clamp((100-LocalPlayer():Health())/100, 0, 0.99), 0.01 )
		--end
end

function GM:OnSpawnMenuOpen()
	print("Inventory opened...")
	if !InvMenu then
		print("creating InvMenu")
		InvMenu = vgui.Create( "DFrame" )
		InvMenu:MakePopup()
		InvMenu:SetDeleteOnClose(true)
		InvMenu:SetSize( 500 + (5*7) + 2, 200 +(5*3)+2 )
		InvMenu:SetDraggable(false)
		InvMenu:Center()
		InvMenu:SetTitle("")
		InvMenu:ShowCloseButton(false)
		InvMenu.OnClose = function(self)
			InvMenu = nil
		end
	else
		InvMenu.OnClose = function(self)
			InvMenu = nil
		end
		InvMenu:Close()
	end
end


function GM:HUDShouldDraw(name)
	if ( hide[ name ] ) then
		return false
	else
		return true
	end
end

function GM:Think()
	local dlight = DynamicLight( LocalPlayer():EntIndex() )
	if render.GetLightColor(LocalPlayer():GetPos()):Length() < 0.00001 && LocalPlayer():Alive() then
		lLight = math.Clamp(lLight + 0.001, 0, 0.25)
	else
		lLight = math.Clamp(lLight - 0.001, 0, 0.25)
	end
	if ( dlight ) then
		dlight.pos = LocalPlayer():GetShootPos()
		dlight.r = 255
		dlight.g = 255
		dlight.b = 255
		dlight.brightness = 0.1
		dlight.Decay = 1000
		dlight.Size = (600*2) * lLight
		dlight.DieTime = CurTime() + 2
	end
end

function GM:HUDDrawTargetID()

end

function GM:PlayerBindPress( ply, bind, pressed )
	if ( string.find( bind, "jump" ) ) then sJump = pressed return true end
	if ( string.find( bind, "impulse 100" ) ) then return true end
end
function GM:ShouldDrawLocalPlayer( ply )
	return true
end

function GM:CreateMove(ucmd)
	if ucmd:CommandNumber() ~= 0 then
		HMsgT = math.Clamp(HMsgT - engine.TickInterval(), 0, 5)
		if HMsgT == 0 then
			HMsgA = math.Clamp(HMsgA - 1, 0, 255)
		end
		if HMsgA == 0 then
			HUDMsg = ""
		end

		if LocalPlayer():GetNWString("dvp") == "sanic" then
			if LocalPlayer():Alive() then
				if sanicT == 0 then
					LocalPlayer():ConCommand("kill")
					sanicT = -1
				elseif sanicT > 0 then
					sanicT = math.Clamp(sanicT - engine.TickInterval(), 0, 30)
				end
			else
				sanicT = -1
			end
		end
	end
	ucmd:RemoveKey(IN_JUMP)
	trHit = ucmd:GetButtons()
	if LocalPlayer():Health() < 25 && LocalPlayer():Alive() then

		checkbuttons(ucmd, {IN_DUCK})
		m_LDuck = true
	elseif LocalPlayer():Health() >= 25 && m_LDuck then
		--ucmd:RemoveKey(IN_DUCK)
		m_LDuck = false
	end
	if ucmd:CommandNumber() ~= 0 then
		sPitch = sPitch + (engine.TickInterval() + math.Rand(0.01, 0.045))/2
		sYaw = sYaw + (engine.TickInterval() + math.Rand(0.05, 0.03))/2
	end
	Blink(ucmd) --Blinking mechanism
	Sprint(ucmd) --limited sprint mechanism

	--[[
		0.405029296875
		0.405029296875
		0.405029296875
		0.405029296875
		0.405029296875
		0.405029296875
		0.40478515625
		0.405029296875
		0.405029296875
		0.405029296875
		0.405029296875
		0.719970703125
		0.405029296875
		0.360107421875
		0.35986328125
		0.360107421875
		0.35986328125
		0.360107421875

	]]
	rollmult = math.Clamp( LocalPlayer():GetVelocity():Length2D()/100, 0.75, 1.50)
	if ucmd:CommandNumber() ~= 0 then
		if  !game.SinglePlayer() && LocalPlayer():GetMoveType() ~= MOVETYPE_NOCLIP && LocalPlayer():IsOnGround() && LocalPlayer():GetVelocity():Length2D() > 10 && (ucmd:KeyDown(IN_FORWARD) || ucmd:KeyDown(IN_BACK) || ucmd:KeyDown(IN_MOVELEFT) || ucmd:KeyDown(IN_MOVERIGHT)) then
			if math.abs(rollang) > (2.5 * math.Clamp((((100-LocalPlayer():Health())/100)*5), 1, 10)) - 1 then
				if switch && rollang >= 0 then
					switch = false
				elseif !switch && rollang <= 0 then
					switch = true
				end
			end

			if switch then
				rollang = rollang + ((engine.TickInterval() * rollmult)* math.Clamp((((100-LocalPlayer():Health())/100)*3), 1, 10)*GetConVarNumber("host_timescale") )
			else
				rollang = rollang - ((engine.TickInterval() * rollmult)* math.Clamp((((100-LocalPlayer():Health())/100)*3), 1, 10)*GetConVarNumber("host_timescale") )
			end
		else
			if !game.SinglePlayer() then
				rollang = Lerp( 0.05, rollang, 0 )
			end
		end
	end
end



function GM:PostDrawHUD()
	resize = (ScrW()/1980)
	if  LocalPlayer():Alive() && IsValid(LocalPlayer():GetActiveWeapon()) && LocalPlayer():GetActiveWeapon() ~= nil then
		if input.IsMouseDown(MOUSE_LEFT) && !leftdown then
			if LocalPlayer():GetActiveWeapon():GetClass() == "weapon_citizenpackage" then
				print("medkit :D")
				net.Start("scb_medkit")
				net.SendToServer()
			end
			leftdown = true
		elseif !input.IsMouseDown(MOUSE_LEFT) then
			leftdown = false
		end
	end
	VisualBlink()
	eyes = LocalPlayer():LookupAttachment("eyes")
	eyes = LocalPlayer():GetAttachment(eyes)
	if eyes then
		local tr = util.TraceHull({
			start = eyes.Pos,
			endpos = eyes.Pos,
			mins = Vector(-3,-3,-3),
			maxs = Vector(3,3,3),
			filter = LocalPlayer(),
			})

		if tr.Hit then
			if LocalPlayer():GetMoveType() ~= MOVETYPE_NOCLIP then
				surface.SetDrawColor(color_black)
				surface.DrawRect(-2,-2,ScrW()+5,ScrH()+5)
			end
		end
	end

	VisualHUD()
	HUDPrintText()
		local mousx, mousy = gui.MousePos();
		if InvMenu then
			if !input.IsKeyDown(KEY_Q) then
				menucl = true
			end
			if !MouseInArea((ScrW()/2)-250, (ScrH()/2)-100, (ScrW()/2)+250,(ScrH()/2)+100) || input.IsKeyDown(KEY_Q) && menucl then
				draw.SimpleText( "Out of bounds.", "BudgetLabel", 5, ScrH()/2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
				if input.IsMouseDown(MOUSE_LEFT) || input.IsKeyDown(KEY_Q) then
				InvMenu.OnClose = function(self)
					InvMenu = nil
				end
				menucl = false
				InvMenu:Close()
				end
			end
		end
	DebugText()
end

function GM:CalcView( ply, origin, ang, fov, znear, zfar )

	local view = {}
	local eyes = ply:LookupAttachment("eyes")
	eyes = ply:GetAttachment(eyes)
	rollmult = math.Clamp( ply:GetVelocity():Length2D()/100, 0.75, 1.50)
	ply:ManipulateBoneScale( ply:LookupBone("ValveBiped.Bip01_Head1"), Vector(0,0,0) )
	if ply:GetMoveType() ~= MOVETYPE_NOCLIP && ply:IsOnGround() && ply:GetVelocity():Length2D() > 10 && (input.IsKeyDown(KEY_W) || input.IsKeyDown(KEY_A) || input.IsKeyDown(KEY_S) || input.IsKeyDown(KEY_D)) then
		if math.abs(rollang) > (2.5 * math.Clamp((((100-ply:Health())/100)*5), 1, 10)) - 1 then
			if switch && rollang >= 0 then
				switch = false
			elseif !switch && rollang <= 0 then
				switch = true
			end
		end

		if switch then
			rollang = rollang + ((0.04 * rollmult)* math.Clamp((((100-ply:Health())/100)*3), 1, 10)*GetConVarNumber("host_timescale") )
		else
			rollang = rollang - ((0.04 * rollmult)* math.Clamp((((100-ply:Health())/100)*3), 1, 10)*GetConVarNumber("host_timescale") )
		end
	else
		rollang = Lerp( 0.05, rollang, 0 )
	end

	if eyes then
		view.origin = eyes.Pos --ang:Forward() * 100
		view.angles = ang + Angle(math.sin(sPitch)*(hPercent(0, 5)),math.sin(sYaw)*(hPercent(0, 5)),rollang)
		newAng =  (ang+Angle(0,0,0)):Forward()
	end
	view.fov = fov
	tgt = LocalPlayer():GetRagdollEntity()
	if IsValid(LocalPlayer():GetNWEntity("ragdoll")) && IsEntity(LocalPlayer():GetNWEntity("ragdoll")) then
		tgt = LocalPlayer():GetNWEntity("ragdoll")
	end
	if IsEntity(tgt) then

		eyes = tgt:LookupAttachment("eyes")
		eyes = tgt:GetAttachment(eyes)
		tgt:ManipulateBoneScale( tgt:LookupBone("ValveBiped.Bip01_Head1"), Vector(0,0,0) )
		if eyes then
			view.origin = tgt:GetBonePosition(tgt:LookupBone("ValveBiped.Bip01_Head1") )
			view.angles = eyes.Ang
		end
	end
		view.drawviewer = true
		return view

end
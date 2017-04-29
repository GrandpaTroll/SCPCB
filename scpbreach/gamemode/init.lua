AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile( "editor_player.lua" )
AddCSLuaFile( "cl_search_models.lua" )
AddCSLuaFile( "player_class/player_scb.lua" )
DEFINE_BASECLASS( "gamemode_base" )
include("shared.lua")
include("commands.lua")
util.AddNetworkString("scb_bleed")
util.AddNetworkString("scb_recoverall")
util.AddNetworkString("scb_medkit")
util.AddNetworkString("scb_blind")
util.AddNetworkString("scb_develope")
util.AddNetworkString("scb_sendmsg")
resource.AddFile("sound/snap.wav")
resource.AddFile("material/BlinkIcon.png")
resource.AddFile("material/sprinticon.png")
resource.AddFile("material/sneakicon.png")
resource.AddFile("material/sneakicon.png")
resource.AddFile("material/BlinkMeter.jpg")
resource.AddFile("material/StaminaMeter.jpg")
resource.AddWorkshop("845068904")

team.SetUp( 0, "Spectators", Color( 255, 255, 0 ) )

team.SetUp( 1, "Class D personnels", Color( 255, 123, 0 ) )

team.SetUp( 2, "NTF", Color( 0, 0, 255 ) )


function GM:PlayerDeathSound()
	return true
end
game.CleanUpMap()
local bRefresh = 0
local vRefresh = 0
local scbplayers = {}

net.Receive("scb_recoverall",function( len, pl)
	print("got this :D")
	bleed = net.ReadBool()
	bleedm = net.ReadFloat()
	pl:SetNWBool( "bleeding", bleed )
	pl:SetNWFloat( "bleedmult", bleedm )
	pl:SetNWString("m_sDMsg", "bleedforce")
end)
net.Receive("scb_medkit",function( len, pl)
	pl:SetNWBool( "bleeding", false)
	pl:SetHealth(math.Clamp(pl:Health()+50,0,100))
	pl:SetWalkSpeed(GetConVarNumber("sv_scbwalkspeed")*math.Clamp((pl:Health()/100),0.5, 1))
	pl:SetRunSpeed(GetConVarNumber("sv_scbrunspeed")*math.Clamp((pl:Health()/100),0.5, 1) )
	pl:SetNWFloat("bleedmult", math.Round(pl:GetNWFloat("bleedmult")/2, 2))
	pl:StripWeapon("weapon_citizenpackage")
	PrintMessage( HUD_PRINTTALK, pl:GetName().." used a medkit.")
end)
net.Receive("scb_blind",function( len, pl)
	blind = net.ReadBool()
	pl:SetNWBool( "blind", blind )
end)

net.Receive("scb_develope",function( len, pl)
	cmd = net.ReadString()
	pl:SetNWString("dvp", cmd)
	if cmd == "sanic" then
		pl:SetRunSpeed(1000)
		pl:SetWalkSpeed(500)
		pl:Say("GOTTA GO FAST!")
		pl:SetNWString("m_sDMsg", "sanic")
	elseif cmd == "suicide" then
		pl:EmitSound("snap.wav")
		pl:Kill()
	end
end)

function SCP_914_Rough(ent)
	if ent && ent:IsPlayer() then
		print("got rough")
		ent:EmitSound("sfx/scp/914/playerdeath.ogg")
		ent:Kill()
	end
end

function SCP_914_Coarse(ent)
	if ent && ent:IsPlayer() then
		print("got coarse")
		ent:EmitSound("sfx/scp/914/playerdeath.ogg")
		ent:SetHealth(24)
		ent:SetNWBool( "bleeding", true )
		ent:SetNWFloat( "bleedmult", 0.1 )
	end
end

function SCP_914_1_1()
		print("got 1:1")
end

function SCP_914_Fine()
		print("got fine")
end

function SCP_914_Veryfine()
		print("got very fine")
end

function GM:ScalePlayerDamage( ply, hitgroup, dmginfo )
	local bleedmult = ply:GetNWFloat("bleedmult")
	local saytxt = ""
	ply:SetWalkSpeed(GetConVarNumber("sv_scbwalkspeed")*math.Clamp((ply:Health()/100),0.5, 1))
	ply:SetRunSpeed(GetConVarNumber("sv_scbrunspeed")*math.Clamp((ply:Health()/100),0.5, 1) )
	if dmginfo:IsBulletDamage() then
			--net.Start("scb_bleed")
			--	net.WriteBool(true)
		--	net.Send(ply)

		if hitgroup == HITGROUP_LEFTARM then
			saytxt = "You feel a sharp pain in your left arm."
		elseif hitgroup == HITGROUP_RIGHTARM then
			saytxt = "You feel a sharp pain in your right arm."
		elseif hitgroup == HITGROUP_CHEST then
			saytxt = "You feel a sharp pain in your chest."
		elseif hitgroup == HITGROUP_STOMACH then
			saytxt = "You feel a sharp pain in your abdomen."
		elseif hitgroup == HITGROUP_LEFTLEG then
			saytxt = "You feel a sharp pain in your left leg."
		elseif hitgroup == HITGROUP_RIGHTLEG then
			saytxt = "You feel a sharp pain in your right leg."
		end
		net.Start("scb_sendmsg")

		net.WriteString(saytxt)

		net.Send(ply)
		ply:SetNWFloat("hitgroup", hitgroup)
		ply:SetNWString("m_sDMsg", "bleedbullet")
		ply:SetNWBool( "bleeding", true )
		ply:SetNWFloat("bleedmult", bleedmult + (dmginfo:GetDamage()/50))
	end

end

hurtSound= {"vo/npc/male01/imhurt01.wav",
		"vo/npc/male01/imhurt02.wav",
		"vo/npc/male01/moan01.wav",
		"vo/npc/male01/moan02.wav",
		"vo/npc/male01/moan03.wav",
		"vo/npc/male01/moan04.wav",
		"vo/npc/male01/moan05.wav",
		"vo/npc/male01/pain01.wav",
		"vo/npc/male01/pain02.wav",
		"vo/npc/male01/pain03.wav",
		"vo/npc/male01/pain04.wav",
		"vo/npc/male01/pain05.wav",
		"vo/npc/male01/pain06.wav",
		"vo/npc/male01/pain07.wav",
		"vo/npc/male01/pain08.wav",
		"vo/npc/male01/pain09.wav",}
--function GM:PlayerPostThink()
function GM:Move( ply, mv )
	bRefresh = bRefresh + (ply:GetNWFloat("bleedmult")/100)
	local health = ply:Health()
	--ply:SetHullDuck( Vector(0,0,0), Vector(0,0,32) )

	if ply:GetNWBool("bleeding") && bRefresh >= 1 && ply:Health() > 0 then
		vRefresh = vRefresh + 1
		if vRefresh >= 5 then
			ply:EmitSound( hurtSound[math.random(1, #hurtSound)] )
			vRefresh = 0
		end
		ply:SetHealth(math.Clamp(health - ply:GetNWFloat("bleedmult"), 0, 100))
		ply:SetWalkSpeed(GetConVarNumber("sv_scbwalkspeed")*math.Clamp((ply:Health()/100),0.5, 1))
		ply:SetRunSpeed(GetConVarNumber("sv_scbrunspeed")*math.Clamp((ply:Health()/100),0.5, 1) )
		bRefresh = 0
		tr = util.TraceLine({start = ply:GetPos(), endpos = (ply:GetPos()-Vector(0,0,15)), filter = ply})
		local Pos1 = tr.HitPos + tr.HitNormal
		local Pos2 = tr.HitPos - tr.HitNormal
		util.Decal("Blood", Pos1, Pos2, ply)

		if tr.HitPos then
			sound.Play( "sfx/character/d9341/blooddrip"..math.random(0,3)..".ogg", ply:GetPos() )
		end
	end
	if ply:Health() <= 0 && ply:Alive() then
		ply:Kill()
	end
end


function GM:PlayerCanHearPlayersVoice( listener, talker )
	return talker:Alive(), true
end

function GM:PlayerCanSeePlayersChat( text, team, listener, speaker )
	return speaker:Alive()
end

function GM:PlayerDeath( victim, inflictor, attacker )
	if victim then
		if victim:GetNWString("dvp") == "sanic" then
			PrintMessage( HUD_PRINTTALK, victim:GetName().." ran too fast for his heart." )
		elseif victim:GetNWString("dvp") == "suicide" then
			PrintMessage( HUD_PRINTTALK, victim:GetName().." took the easy way out." )
		else
			PrintMessage( HUD_PRINTTALK, victim:GetName().." died" )
		end
	end
end

function GM:PlayerNoClip( ply, desiredState )
	if ply:SteamID() == "STEAM_0:0:35717190" || ply:IsAdmin() || desiredState == false then
		return true
	else
		return false
	end
end

function GM:PlayerConnect(name, ip)

	print("Player "..name.." connected. IP: "..ip)

end


function GM:CanPlayerSuicide( ply )
	if ply:GetNWString("dvp") == "sanic" then
		return true
	else
		return false
	end
end

cvars.AddChangeCallback( "sv_scbwalkspeed", function( convar_name, value_old, value_new )
	for _, ply in next, player.GetAll() do
		ply:SetWalkSpeed(GetConVarNumber("sv_scbwalkspeed"))
	end
end )

cvars.AddChangeCallback( "sv_scbrunspeed", function( convar_name, value_old, value_new )
	for _, ply in next, player.GetAll() do
		ply:SetRunSpeed(GetConVarNumber("sv_scbrunspeed"))
	end
end )

function GM:CreateEntityRagdoll( owner, ragdoll )
	if IsValid(owner:GetNWEntity("ragdoll")) && IsEntity(owner:GetNWEntity("ragdoll")) then
		owner:GetNWEntity("ragdoll"):Remove()
	end

	owner:Spectate( OBS_MODE_IN_EYE )
	owner:SpectateEntity(ragdoll)
	owner:GetRagdollEntity():Remove()
	owner:SetNWEntity("ragdoll", ragdoll)
end

function GM:PlayerFootstep( ply, pos, foot, sound, volume, filter )

	--setpos -6000, -5070, -2000
	if ply:GetPos().x >= -6000 && ply:GetPos().y <= -5000 then
		--print("yes")
		ply:EmitSound( 'sfx/step/steppd'..math.random(1,3)..'.ogg' )
		return true
	end
	--ply:EmitSound( 'stepmetal'..math.random(1,3)..'.ogg' )
	--ply:PlayStepSound( 1 )
	--return true
end

for _, ply in next, player.GetAll() do
	ply:Spawn()
	if !table.HasValue(scbplayers,ply) && #scbplayers <= 10 then
		table.insert(scbplayers, ply)
		move = (128 * (#scbplayers-1))
		ply:SetPos(Vector((-13087)-move , -6025, -2198))
		ply:SetEyeAngles(Angle(0,-90,0))
	end
end


function GM:PlayerSpawn( pl )
	player_manager.SetPlayerClass( pl, "player_scb" )
	pl:SetPlayerColor(Vector(1,0.5,0))
	pl:SetWalkSpeed(GetConVarNumber("sv_scbwalkspeed"))
	pl:SetRunSpeed(GetConVarNumber("sv_scbrunspeed"))
	pl:SetCrouchedWalkSpeed(0.5)
	pl:SetNWBool( "bleeding", false )
	pl:SetNWFloat( "bleedmult", 0 )
	pl:SetNWBool( "blind", false )
	pl:SetNWBool( "m_bDuck", false )
	pl:SetNWString( "m_sDMsg", "Unknown" )
	pl:SetNWString( "dvp", "" )
	if  IsValid(ply) && ply:IsPlayer() && !ply:IsBot() then
		pl:SetShouldServerRagdoll( true )
	else
		pl:SetShouldServerRagdoll( false )
	end
	--pl:PrintMessage( HUD_PRINTTALK, "my team is "..pl:Team() )
	--pl:SetPos(Vector(-13087, -6025, -2198))
		if IsValid(pl:GetNWEntity("ragdoll")) && IsEntity(pl:GetNWEntity("ragdoll")) then
		ply:GetNWEntity("ragdoll"):Remove()
	end
	BaseClass.PlayerSpawn( self, pl )
	print("spawned again")
	for i = 1, #scbplayers do
			print(tostring(scbplayers[i]))
		if !IsValid(scbplayers[i]) || scbplayers[i] == nil then
			print("Take a non existant player's cell")
			move = (128 * (i-1))
			pl:SetPos(Vector((-13087)-move , -6025, -2198))
			pl:SetEyeAngles(Angle(0,-90,0))
			scbplayers[i] = pl
			return
		elseif scbplayers[i] == pl then
			print("take your cell back")
			move = (128 * (i-1))
			pl:SetPos(Vector((-13087)-move , -6025, -2198))
			pl:SetEyeAngles(Angle(0,-90,0))
			return
		end
	end

	if !table.HasValue(scbplayers,pl) && #scbplayers <= 10 then
		table.insert(scbplayers, pl)
		print("we got here: "..#scbplayers)
		move = (128 * (#scbplayers-1))
		pl:SetPos(Vector((-13087)-move , -6025, -2198))
		pl:SetEyeAngles(Angle(0,-90,0))
	end


end

function GM:PlayerInitialSpawn(ply)
	PrintMessage( HUD_PRINTTALK, ply:GetName().." spawned.")
	--player_manager.SetPlayerClass( ply, "player_scb" )
	ply:SetWalkSpeed(GetConVarNumber("sv_scbwalkspeed"))
	ply:SetRunSpeed(GetConVarNumber("sv_scbrunspeed"))
	ply:SetCrouchedWalkSpeed(0.5)
	ply:SetNWBool( "bleeding", false )
	ply:SetNWFloat( "bleedmult", 0 )
	ply:SetNWBool( "blind", false )
	ply:SetNWBool( "m_bDuck", false )
	ply:SetNWString( "m_sDMsg", "Unknown" )
	ply:SetNWString( "dvp", "" )
	print("Player ".. ply:GetName().. " spawned.")
	ply:SetTeam(1)
end


function GM:OnPlayerChangedTeam( ply, oldTeam, newTeam )
	PrintMessage( HUD_PRINTTALK, ply:GetName().." switched from "..oldTeam.. " to "..newTeam)
end

function checkadmin(ply)
	return ply:IsAdmin()
end

function GM:Initialize()
	self.BaseClass.Initialize(self)
end
		--start1
--setpos -13087.0 -6025.0 -2198.0

--setpos -13215.0 -6025.0 -2198.0
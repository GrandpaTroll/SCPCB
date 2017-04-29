
AddCSLuaFile()
DEFINE_BASECLASS( "player_default" )


if ( CLIENT ) then

	CreateConVar( "cl_playercolor", "0.24 0.34 0.41", { FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_DONTRECORD }, "The value is a Vector - so between 0-1 - not between 0-255" )
	CreateConVar( "cl_weaponcolor", "0.30 1.80 2.10", { FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_DONTRECORD }, "The value is a Vector - so between 0-1 - not between 0-255" )
	CreateConVar( "cl_playerskin", "0", { FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_DONTRECORD }, "The skin to use, if the model has any" )
	CreateConVar( "cl_playerbodygroups", "0", { FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_DONTRECORD }, "The bodygroups to use, if the model has any" )
	CreateConVar( "scb_give", "", { FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_REPLICATED }, "" )
end

CreateConVar( "sv_scbwalkspeed", "100", { FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_NOTIFY, FCVAR_REPLICATED }, "Walkspeed" )
CreateConVar( "sv_scbrunspeed", "200", { FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_NOTIFY, FCVAR_REPLICATED }, "Runspeed" )

if CLIENT then
	CreateConVar( "scb_debug", "0", {  FCVAR_PROTECTED }, 'Allow testing for further analysis; 1 or "client" = client debug only, 2 or "server" = server debug only, 3 or "both" = both.' )
	CreateConVar( "scb_debugadmin", "0", { FCVAR_USERINFO, FCVAR_REPLICATED, FCVAR_NOTIFY }, "Debug text for admin only." )
end


local PLAYER = {}

PLAYER.DuckSpeed			= 0.1		-- How fast to go from not ducking, to ducking
PLAYER.UnDuckSpeed			= 0.1		-- How fast to go from ducking, to not ducking

--
-- Creates a Taunt Camera
--
PLAYER.TauntCam = TauntCamera()

--
-- See gamemodes/base/player_class/player_default.lua for all overridable variables
--

--[[
AvoidPlayers	=	true
CalcView	=	function: 0x2ed472f0
CanUseFlashlight	=	true
CreateMove	=	function: 0x2ed19998
CrouchedWalkSpeed	=	0.3
DisplayName	=	Default Class
DropWeaponOnDie	=	false
DuckSpeed	=	0.3
FinishMove	=	function: 0x2ed31f28
GetHandsModel	=	function: 0x2ece2fc0
Init	=	function: 0x2eda1310
JumpPower	=	200
Loadout	=	function: 0x2ed472c0
MaxHealth	=	100
Move	=	function: 0x2ed31f10
PostDrawViewModel	=	function: 0x2ece2fa8
PreDrawViewModel	=	function: 0x2ece2f90
RunSpeed	=	600
SetModel	=	function: 0x2ed472d8
SetupDataTables	=	function: 0x2ed44750
ShouldDrawLocal	=	function: 0x2ed199b0
Spawn	=	function: 0x2ed292a8
StartArmor	=	0
StartHealth	=	100
StartMove	=	function: 0x2ed199c8
TeammateNoCollide	=	true
ThisClass	=	player_default
UnDuckSpeed	=	0.3
UseVMHands	=	true
ViewModelChanged	=	function: 0x2ed31f40
WalkSpeed	=	400
]]
PLAYER.WalkSpeed 			= 100
PLAYER.RunSpeed				= 200
PLAYER.CrouchedWalkSpeed 	= 0.5


--
-- Set up the network table accessors
--


function PLAYER:SetupDataTables()

	BaseClass.SetupDataTables( self )

end

function PLAYER:SetModel()
	males = {
	"models/player/Group01/Male_01.mdl",
	"models/player/Group01/Male_02.mdl",
	"models/player/Group01/Male_03.mdl",
	"models/player/Group01/Male_04.mdl",
	"models/player/Group01/Male_05.mdl",
	"models/player/Group01/Male_06.mdl",
	"models/player/Group01/Male_07.mdl",
	"models/player/Group01/Male_08.mdl",
	"models/player/Group01/Male_09.mdl"}
	females = {
	"models/player/Group01/Female_01.mdl",
	"models/player/Group01/Female_02.mdl",
	"models/player/Group01/Female_03.mdl",
	"models/player/Group01/Female_04.mdl",
	"models/player/Group01/Female_06.mdl"}
	local mdl = males[math.random(1, #males)]
	self.Player:SetModel(mdl)

  	 -- Always clear color state, may later be changed in TTTPlayerSetColor
  	self.Player:SetPlayerColor(Vector(1,0.7,0))
	local skin = self.Player:GetInfoNum( "cl_playerskin", 0 )
	self.Player:SetSkin( skin )

	local groups = self.Player:GetInfo( "cl_playerbodygroups" )
	if ( groups == nil ) then groups = "" end
	local groups = string.Explode( " ", groups )
	for k = 0, self.Player:GetNumBodyGroups() - 1 do
		self.Player:SetBodygroup( k, tonumber( groups[ k + 1 ] ) or 0 )
	end

end

function PLAYER:Loadout()

end

--
-- Called when the player spawns
--
function PLAYER:Spawn()

	BaseClass.Spawn( self )

	local col = self.Player:GetInfo( "cl_playercolor" )
	self.Player:SetPlayerColor( Vector( col ) )
	self.Player:SetWalkSpeed(GetConVarNumber("sv_scbwalkspeed"))
	self.Player:SetRunSpeed(GetConVarNumber("sv_scbrunspeed"))
	local col = Vector( self.Player:GetInfo( "cl_weaponcolor" ) )
	if col:Length() == 0 then
		col = Vector( 0.001, 0.001, 0.001 )
	end
	self.Player:SetWeaponColor( col )

end

--
-- Return true to draw local (thirdperson) camera - false to prevent - nothing to use default behaviour
--
function PLAYER:ShouldDrawLocal() 

	if ( self.TauntCam:ShouldDrawLocalPlayer( self.Player, self.Player:IsPlayingTaunt() ) ) then return true end

end

--
-- Allow player class to create move
--
function PLAYER:CreateMove( cmd )
	if ( self.TauntCam:CreateMove( cmd, self.Player, self.Player:IsPlayingTaunt() ) ) then return true end
end

--
-- Allow changing the player's view
--
function PLAYER:CalcView( view )

	if ( self.TauntCam:CalcView( view, self.Player, self.Player:IsPlayingTaunt() ) ) then return true end

	-- Your stuff here

end

function PLAYER:GetHandsModel()

	-- return { model = "models/weapons/c_arms_cstrike.mdl", skin = 1, body = "0100000" }

	local cl_playermodel = self.Player:GetInfo( "cl_playermodel" )
	return player_manager.TranslatePlayerHands( cl_playermodel )

end

--
-- Reproduces the jump boost from HL2 singleplayer
--

function PLAYER:StartMove( move )
	
	-- Only apply the jump boost in FinishMove if the player has jumped during this frame
	-- Using a global variable is safe here because nothing else happens between SetupMove and FinishMove
end


function PLAYER:FinishMove( move )
	
	-- If the player has jumped this frame
end

player_manager.RegisterClass( "player_scb", PLAYER, "player_default" )
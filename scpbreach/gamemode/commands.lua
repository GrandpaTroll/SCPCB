--[[---------------------------------------------------------
	Name: CanPlayerSpawnSENT
-----------------------------------------------------------]]
local function CanPlayerSpawnSENT( player, EntityName )

	-- Make sure this is a SWEP
	local sent = scripted_ents.GetStored( EntityName )
	if ( sent == nil ) then

		-- Is this in the SpawnableEntities list?
		local SpawnableEntities = list.Get( "SpawnableEntities" )
		if ( !SpawnableEntities ) then return false end
		local EntTable = SpawnableEntities[ EntityName ]
		if ( !EntTable ) then return false end
		if ( EntTable.AdminOnly && !player:IsAdmin() ) then return false end
		return true

	end

	-- We need a spawn function. The SENT can then spawn itself properly
	local SpawnFunction = scripted_ents.GetMember( EntityName, "SpawnFunction" )
	if ( !isfunction( SpawnFunction ) ) then return false end

	-- You're not allowed to spawn this unless you're an admin!
	if ( !scripted_ents.GetMember( EntityName, "Spawnable" ) && !player:IsAdmin() ) then return false end
	if ( scripted_ents.GetMember( EntityName, "AdminOnly" ) && !player:IsAdmin() ) then return false end

	return true

end

--[[---------------------------------------------------------
	Name: Spawn_SENT
	Desc: Console Command for a player to spawn different items
-----------------------------------------------------------]]
function Spawn_SENT( player, EntityName, tr )

	if ( EntityName == nil ) then return end

	if ( !CanPlayerSpawnSENT( player, EntityName ) ) then return end

	-- Ask the gamemode if it's ok to spawn this
	if ( !gamemode.Call( "PlayerSpawnSENT", player, EntityName ) ) then return end

	local vStart = player:EyePos()
	local vForward = player:GetAimVector()

	if ( !tr ) then

		local trace = {}
		trace.start = vStart
		trace.endpos = vStart + ( vForward * 4096 )
		trace.filter = player

		tr = util.TraceLine( trace )

	end

	local entity = nil
	local PrintName = nil
	local sent = scripted_ents.GetStored( EntityName )

	if ( sent ) then

		local sent = sent.t

		ClassName = EntityName

			local SpawnFunction = scripted_ents.GetMember( EntityName, "SpawnFunction" )
			if ( !SpawnFunction ) then return end
			entity = SpawnFunction( sent, player, tr, EntityName )

			if ( IsValid( entity ) ) then
				entity:SetCreator( player )
			end

		ClassName = nil

		PrintName = sent.PrintName

	else

		-- Spawn from list table
		local SpawnableEntities = list.Get( "SpawnableEntities" )
		if ( !SpawnableEntities ) then return end
		local EntTable = SpawnableEntities[ EntityName ]
		if ( !EntTable ) then return end

		PrintName = EntTable.PrintName

		local SpawnPos = tr.HitPos + tr.HitNormal * 16
		if ( EntTable.NormalOffset ) then SpawnPos = SpawnPos + tr.HitNormal * EntTable.NormalOffset end

		entity = ents.Create( EntTable.ClassName )
		entity:SetPos( SpawnPos )

		if ( EntTable.KeyValues ) then
			for k, v in pairs( EntTable.KeyValues ) do
				entity:SetKeyValue( k, v )
			end
		end

		if ( EntTable.Material ) then
			entity:SetMaterial( EntTable.Material )
		end

		entity:Spawn()
		entity:Activate()

		if ( EntTable.DropToFloor ) then
			entity:DropToFloor()
		end

	end

	if ( IsValid( entity ) ) then

		if ( IsValid( player ) ) then
			gamemode.Call( "PlayerSpawnedSENT", player, entity )
		end

		undo.Create( "SENT" )
			undo.SetPlayer( player )
			undo.AddEntity( entity )
			if ( PrintName ) then
				undo.SetCustomUndoText( "Undone " .. PrintName )
			end
		undo.Finish( "Scripted Entity (" .. tostring( EntityName ) .. ")" )

		player:AddCleanup( "sents", entity )
		entity:SetVar( "Player", player )

	end

end
concommand.Add( "gm_spawnsent", function( ply, cmd, args ) Spawn_SENT( ply, args[ 1 ] ) end )
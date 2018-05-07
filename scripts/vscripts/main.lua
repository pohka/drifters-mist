_G.PlayerInputTable = {}
_G.VelocityTable = {}

--startinting point for scripting
function Brewlit:Start()
	print("Brewlit:Start()")
	Task:Interval(Brewlit.UpdateInput, 0.03)
	Setup:Quick(self)
	
	--disable FoW
	local GameMode = GameRules:GetGameModeEntity()
	GameMode:SetFogOfWarDisabled(true)
end

--called once every second
function Brewlit:Update()
	Input:ListenToDirectionalInput(true)
	
	--set the camera
	if Camera:AllPlayersHaveTarget() == false then
		Camera:LockAllCamerasToHero()
		local playerIDs = Helper:GetAllPlayerIDs()
		for _,playerID in pairs(playerIDs) do
			Camera:UpdateSettings(playerID, 0, 500, 200, 30)
		end
	end
	
	
	
	--placeholder
	local players = Helper:GetAllPlayers()
	for _,player in pairs(players) do
		local hero = player:GetAssignedHero()
		if hero ~= nil then
			--Animation:Set(hero, ACT_DOTA_RUN, 10)
		end
	end
	
	-- Camera:Shake(Vector(0,0,0), 3000, 150, 0.45, 1)
	--Camera:Shake(Vector(0,0,0), 3000, 50, 1, 1)
	
	
end

--update loop for the current state of each players input
function Brewlit:UpdateInput()
	--print("---------------------")
	for playerID,input in pairs(PlayerInputTable) do
		--print(playerID .. ": " .. input.x .. "," .. input.y)
		local player = PlayerResource:GetPlayer(playerID)
		if player ~= nil then
			local hero = player:GetAssignedHero()
			if hero ~= nil then
			
				if VelocityTable[playerID] == nil then
					VelocityTable[playerID] = Vector(0,0,0)
				end
			
				--set position
				local startPt = hero:GetOrigin()
				local forward = hero:GetForwardVector()
				local speed = 7
				local maxSpeed = 60
				local airResistPercent = 0.4
				local minSpeed = 5
				local reversePercent = 0.5
				local reverseMaxSpeed = 25
				
				--accelerate
				if input.y > 0 then
					VelocityTable[playerID] = VelocityTable[playerID] + (forward * speed)
				elseif input.y < 0 then
					VelocityTable[playerID] = VelocityTable[playerID] - (forward * speed)
				end
				
				--limit min speed
				if VelocityTable[playerID]:Length2D() < minSpeed then
					VelocityTable[playerID] = Vector(0,0,0)
				else
					--air resistance
					local airResist = VelocityTable[playerID]:Normalized() * (speed * airResistPercent)
					VelocityTable[playerID] = VelocityTable[playerID] - airResist
				end
				
				
				--check if moving forward or backwards
				local movingForward = true
				local dir = VelocityTable[playerID]:Normalized()
				local dot = dir:Dot(forward)
				local a = dot/(dir:Length() * forward:Length())
				local val = math.acos(a)
				local degrees = val/math.pi  * 180
				if degrees > 90 then
					movingForward = false
				end
				
				--limit to maxSpeed
				local velMag = VelocityTable[playerID]:Length2D()
				--forward
				if movingForward and velMag > maxSpeed then
					local direction = VelocityTable[playerID]:Normalized()
					local maxVel = direction * maxSpeed
					VelocityTable[playerID] = maxVel
				--reverse
				elseif not movingForward and velMag > reverseMaxSpeed then
					local direction = VelocityTable[playerID]:Normalized()
					local maxVel = direction * reverseMaxSpeed
					VelocityTable[playerID] = maxVel
				end
				
				--change position based on current velocity
				if VelocityTable[playerID] ~= Vector(0,0,0) then
					hero:SetOrigin(startPt + VelocityTable[playerID])
				end
				
				--rotation
				local angles = hero:GetAnglesAsVector();
				local turnRate = 2
				local yaw = angles.y
				if input.x > 0 then
					yaw = yaw - turnRate
				elseif input.x < 0 then
					yaw = yaw + turnRate
				end
				
				if input ~= 0 then
					hero:SetAngles(angles.x, yaw, angles.z)
				end
				
				--calc camera yaw degrees and update the net table
				Brewlit:CalcCameraYaw(playerID, hero:GetForwardVector())
				
			end
		end
	end
end

--reading the raw player input into a gloabl input table
function Brewlit:OnInput(input)
	if IsServer() then
		local player = PlayerResource:GetPlayer(input.playerid)
		if player ~= nil then
			PlayerInputTable[input.playerid] = { x = input.move_x, y = input.move_y }
		end
	end
end

function Brewlit:CalcCameraYaw(playerID, forward)
	-- degrees = acos(v1:Dot(v2)/|v1|*|v2|)
	local WORLD_FORWARD = Vector(0,1,0)
	local dot = WORLD_FORWARD:Dot(forward)
	local a = dot/(WORLD_FORWARD:Length() * forward:Length())
	local val = math.acos(a)
	local degrees = val/math.pi  * 180
	
	--check if vectors are pointing in the same direction
	local cross = WORLD_FORWARD:Cross(forward)
	if cross.z < 0 then
		 degrees = -degrees
	end
	
	--print("deg:"..degrees)
	CustomNetTables:SetTableValue("camera_yaw", ""..playerID, { yaw = degrees })
end


--you can listen to particular state changes using listener functions called from GameStateManager
function GameState:OnStateInProgress()
	
	
	
end





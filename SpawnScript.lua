local TweenService = game:GetService('TweenService')
local CollectionService = game:GetService('CollectionService')
local Players = game:GetService('Players')
local RepStorage = game:GetService('ReplicatedStorage')
local SoundService = game:GetService('SoundService')

local sound = SoundService['roblox-spawn']

local remEvent = RepStorage:WaitForChild('RemoteEvents'):WaitForChild('TweenEvent')
local clientEvent = RepStorage:WaitForChild('RemoteEvents'):WaitForChild('ClientSave')
local remFunc = RepStorage:WaitForChild('RemoteFunctions'):WaitForChild('SpawnFunction')

local module = require(RepStorage:WaitForChild('Modules'):WaitForChild('CharacterFunctions'))

local ParticleEmitter = RepStorage:WaitForChild('Instances'):WaitForChild('StageEmitter')

local PartHightlight = script:WaitForChild('PartHighlight')

local player = Players.LocalPlayer

local tag = 'SpawnLocation'

local tagged = CollectionService:GetTagged(tag)

local currentChar = player.Character or player.CharacterAdded:Wait()

player.CharacterAdded:Connect(function(character)
	currentChar = character
end)

local function getTween(spawnL: SpawnLocation)
	local goal = {
		Color = Color3.new(1, 0.152941, 0.196078)
	}

	if spawnL.Name:find('51') then
		goal.Color = Color3.fromRGB(255, 255, 0)
	end

	local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.In)

	local tween = TweenService:Create(spawnL, tweenInfo, goal)

	return tween
end

local function initiateFunctions(spawnL: SpawnLocation, event: RBXScriptConnection, tween: Tween)
	local StageNumber: IntValue = player:WaitForChild('leaderstats'):WaitForChild('StageNumber')

	local existingEmitter = spawnL:FindFirstChild("StageEmitter")

	if not existingEmitter then
		local emitter = ParticleEmitter:Clone()

		emitter.Parent = spawnL

		if spawnL:GetAttribute('Stage') == 51 then
			emitter.Color = ColorSequence.new(Color3.fromRGB(255, 255, 0))
		end
	end
	
	tween:Play()
	sound:Play()
	event:Disconnect()
	
	for _, newSpawn in pairs(CollectionService:GetTagged(tag)) do
		if newSpawn:GetAttribute('Stage') == StageNumber.Value + 1 and newSpawn ~= spawnL then
			PartHightlight.Parent = newSpawn	

			if newSpawn:GetAttribute('Stage') == 51 then
				PartHightlight:Destroy()
			end

			break
		end
	end
end

local canInitiate = false

remEvent.OnClientEvent:Connect(function(bool: boolean)
	canInitiate = bool
end)

local debounce = {}

local function initiateRespawn(spawnL: SpawnLocation)
	local touchCon = nil
	
	local tween = getTween(spawnL)
	
	touchCon = spawnL.Touched:Connect(function(hit)
		if debounce[spawnL] then			
			return nil
		end
		
		local char = module:GetCharacterFromHit(hit)
		
		if not char or char ~= currentChar then return end
		
		debounce[spawnL] = true
		
		local result = remFunc:InvokeServer(spawnL)
		
		if result then
			initiateFunctions(spawnL, touchCon, tween)
		else
			if canInitiate then
				initiateFunctions(spawnL, touchCon, tween)
				canInitiate = false
			end
		end
		
		task.wait(0.2)
		
		debounce[spawnL] = false
	end)
end


for _, spawnL in ipairs(tagged) do
	task.spawn(initiateRespawn, spawnL)
end

CollectionService:GetInstanceAddedSignal(tag):Connect(initiateRespawn)


local function onSave(spawnL: SpawnLocation, stageNumber)
	if not stageNumber then return end

	if not spawnL:FindFirstChild('StageEmitter') then
		if spawnL:GetAttribute('Stage') > stageNumber then return end
		
		local emitter = ParticleEmitter:Clone()

		emitter.Parent = spawnL

		if spawnL:GetAttribute('Stage') == 51 then
			emitter.Color = ColorSequence.new(Color3.fromRGB(255, 255, 0))
		end
	end

	for _, spawnL in pairs(CollectionService:GetTagged(tag)) do
		if spawnL:GetAttribute('Stage') == stageNumber + 1 then
			PartHightlight.Parent = spawnL

			if spawnL:GetAttribute(tostring(51)) then
				PartHightlight:Destroy()
			end

			break
		end
	end

	local tween = getTween(spawnL)
	tween:Play()
end

clientEvent.OnClientEvent:Connect(function(spawnNumber: number)
	for _, spawnL: SpawnLocation in ipairs(CollectionService:GetTagged(tag)) do
		onSave(spawnL, spawnNumber)
	end

	CollectionService:GetInstanceAddedSignal(tag):Connect(function(spawnL)
		onSave(spawnL, spawnNumber)
	end)
end)
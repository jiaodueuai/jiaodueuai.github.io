local DataStoreService = game:GetService('DataStoreService')
local CollectionService = game:GetService('CollectionService')
local Players = game:GetService('Players')
local RepStorage = game:GetService('ReplicatedStorage')

local StageStore = DataStoreService:GetDataStore('StageStore')

local remFunc = RepStorage.RemoteFunctions.DataStoreEvent

local remEvent = RepStorage.RemoteEvents.ClientSave
local bindEvent = RepStorage.BindableEvents.RemoveOrderedDataStoreKey

local tag = 'SpawnLocation'

local tagged = CollectionService:GetTagged(tag)

local function onServerInvoke(player: Player, bool: boolean)
	local userID = player.UserId
	
	local StageNumber: IntValue = player:FindFirstChild('StageNumber', true)
	local SkipStages: IntValue = player:FindFirstChild('SkipStages', true)
	
	local data = {
		StageNumber = StageNumber.Value,
		SkipStages = SkipStages.Value,
	}
	
	if bool then
		local success, result = pcall(function()
			return StageStore:SetAsync(userID, data)
		end)
		
		if not success or not result then
			warn(result)
			
			return false
		end
		
		if success and result then
			print('data saved for '..player.Name)
			
			return true
		end
	else
		bindEvent:Fire(player.UserId)
		
		StageStore:RemoveAsync(player.UserId)
	
		player:Kick('Reset data.')
	end
end

remFunc.OnServerInvoke = onServerInvoke

Players.PlayerAdded:Connect(function(player)
	local userID = player.UserId
	
	local success, result = pcall(function()
		return StageStore:GetAsync(userID)
	end)
	
	if success and result then
		print('data retrieved for '..player.Name)
		
		local StageNumber = player:FindFirstChild('StageNumber', true)
		local SkipStages = player:FindFirstChild('SkipStages', true)
		
		StageNumber.Value = result.StageNumber
		SkipStages.Value = result.SkipStages
		
		if not player.Character then
			player.CharacterAdded:Wait()
		end
				
		local humanoidRootPart: Part = player.Character:FindFirstChild('HumanoidRootPart')
		
		for _, spawnL: SpawnLocation in ipairs(tagged) do
			if spawnL:GetAttribute('Stage') == StageNumber.Value then
				player.RespawnLocation = spawnL
				
				humanoidRootPart.CFrame = spawnL.CFrame + Vector3.new(0, 10, 0)
				
				remEvent:FireClient(player, StageNumber.Value)
				
				break
			end
		end
	end
end)

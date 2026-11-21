local DataStoreService = game:GetService('DataStoreService')
local BadgeService = game:GetService('BadgeService')
local Players = game:GetService('Players')
local RepStorage = game:GetService('ReplicatedStorage')
local SSS = game:GetService('ServerScriptService')
local ServerStorage = game:GetService('ServerStorage')

local module = require(SSS.Modules.GamePasses)

local leaderboardModule = require(SSS.Modules.Leaderboard)

local TimeStore = DataStoreService:GetOrderedDataStore('TimeStore')

local bindEvent = RepStorage.BindableEvents.FinishedObby

local dataStoreEvent = RepStorage.BindableEvents.RemoveOrderedDataStoreKey

local leaderboard = workspace.TimeLeaderboard

local gui = leaderboard.GuiPart.SurfaceGui

local template = ServerStorage.Miscellanous.LeaderboardTemplate

local badgeID = 2324800524440009

local inElligible = {}

local function formatTime(seconds)
	local minutes = math.floor(seconds / 60)
	local secs = math.floor(seconds % 60)
	local ms = math.floor((seconds % 1) * 100)
	return string.format('%02d:%02d.%02d', minutes, secs, ms)
end

local function getAsync(userID: number)
	local returnValue = nil
	
	local success, result = pcall(function()
		return TimeStore:GetAsync(userID)
	end)
	
	if success and result then
		returnValue = result
	else
		returnValue = nil
	end
	
	return returnValue
end

dataStoreEvent.Event:Connect(function(userID)
	local success, errorMsg = pcall(function()
		TimeStore:RemoveAsync(userID)
	end)
	
	if not success then warn(errorMsg) end
end)

Players.PlayerAdded:Connect(function(player)
	local userID = player.UserId
	
	local StageNumber = player:WaitForChild('leaderstats', 5):WaitForChild('StageNumber', 5)

	if StageNumber.Value > 1  or module:getGamepassStatus(userID) then
		table.insert(inElligible, userID) 
	end
	
	task.spawn(function()
		leaderboardModule:AwardBadgeIfOnLeaderboard(userID, badgeID, TimeStore)
	end)
end)

Players.PlayerRemoving:Connect(function(player, reason)
	local userID = player.UserId
	
	local index = table.find(inElligible, userID)
	
	if index then
		table.remove(inElligible, index)
	end
end)

bindEvent.Event:Connect(function(player: Player)
	local userID = player.UserId
	
	if table.find(inElligible, userID) then return end
	
	local Time: IntValue = player:WaitForChild('PlayerStats'):WaitForChild('RawTime')
	
	local value = Time.Value
	
	local currentValue = getAsync(userID)
	
	if currentValue and currentValue <= value then
		return nil
	end
	
	local success, result = pcall(function()
		TimeStore:SetAsync(userID, value)
	end)

	if success then
		print('success')

		return true
	else
		warn(result)

		return false
	end
end)

local function updateLeaderboard()

	local pages = TimeStore:GetSortedAsync(true, 10)

	local currentPage = pages:GetCurrentPage()

	for rank, data in ipairs(currentPage) do
		local Time = data.value
		local userID = data.key

		local statsFrame = template:Clone()

		local nameSuccess, nameResult = pcall(function()
			return Players:GetNameFromUserIdAsync(userID)
		end)

		local imageSuccess, imageResult = pcall(function()
			return Players:GetUserThumbnailAsync(userID, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
		end)

		local StatLabel  = statsFrame.StatLabel
		local PlaceLabel = statsFrame.PlaceLabel
		local NameLabel = statsFrame.NameLabel
		local ImageLabel = statsFrame.ImageLabel

		if nameSuccess and nameResult then
			NameLabel.Text = nameResult
			print(nameResult)
		else
			NameLabel.Text = 'Error'
		end

		if imageSuccess and imageResult then
			ImageLabel.Image = imageResult
			print(imageResult)
		else
			ImageLabel.Image = 'rbxassetid://103073095226701'
		end

		StatLabel.Text = formatTime(Time / 100)
		PlaceLabel.Text = tostring(rank)

		if rank == 1 then PlaceLabel.TextColor3 = Color3.fromRGB(255, 255, 0) end
		if rank == 2 then PlaceLabel.TextColor3 = Color3.fromRGB(131, 131, 131) end
		if rank == 3 then PlaceLabel.TextColor3 = Color3.fromRGB(34, 25, 16) end

		statsFrame.LayoutOrder = rank
		statsFrame.Name = tostring(userID)

		statsFrame.Parent = gui
	end
end

while true do
	for _, child in gui:GetChildren() do
		if not child:IsA('UIListLayout') then child:Destroy() end
	end
	
	local success, errorMsg = pcall(updateLeaderboard)

	if not success then warn(errorMsg) end
	
	print('refreshed')

	task.wait(60)
end
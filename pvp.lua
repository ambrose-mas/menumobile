 local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")
local ENABLED = false
local TELEPORT_OFFSET = CFrame.new(0, 0, -4)
local CHECK_INTERVAL = 0.4
local mySpawn, enemySpawn

task.delay(1, function()
	for _, v in ipairs(workspace:GetDescendants()) do
		if v:IsA("SpawnLocation") then
			if v.TeamColor == player.TeamColor then
				mySpawn = v
			else
				enemySpawn = enemySpawn or v
			end
		end
	end
end)

-------------------- UTIL --------------------------
local function getBiggestPart(model)
	local biggest, size = nil, 0
	for _, v in ipairs(model:GetDescendants()) do
		if v:IsA("BasePart") then
			local s = v.Size.Magnitude
			if s > size then
				size = s
				biggest = v
			end
		end
	end
	return biggest
end

local function isCrystal(model)
	if not model:IsA("Model") then return false end
	local n = model.Name:lower()
	return n:find("crystal") or n:find("phale")
end

local function isEnemyCrystal(part)
	if not mySpawn or not enemySpawn then return false end

	local mid = (mySpawn.Position + enemySpawn.Position) / 2
	local dMy = (part.Position - mySpawn.Position).Magnitude
	local dMid = (part.Position - mid).Magnitude

	return dMy > dMid
end
local function findEnemyCrystalsOrdered()
	if not enemySpawn then return {} end

	local sub, main = {}, {}

	for _, obj in ipairs(workspace:GetDescendants()) do
		if isCrystal(obj) then
			local part = getBiggestPart(obj)
			if part and isEnemyCrystal(part) then
				local dist = (part.Position - enemySpawn.Position).Magnitude

				if part.Size.Magnitude < 20 then
					table.insert(sub, {model = obj, d = dist})
				else
					table.insert(main, {model = obj, d = dist})
				end
			end
		end
	end

	-- crystal phụ: xa spawn địch hơn → đi trước
	table.sort(sub, function(a, b)
		return a.d > b.d
	end)

	-- crystal chính: gần spawn địch hơn → đi sau
	table.sort(main, function(a, b)
		return a.d < b.d
	end)

	local ordered = {}
	for _, v in ipairs(sub) do
		table.insert(ordered, v.model)
	end
	for _, v in ipairs(main) do
		table.insert(ordered, v.model)
	end

	return ordered
end
local function teleportToCrystal(crystal)
	local hitbox = getBiggestPart(crystal)
	if not hitbox then return end

	hrp.Anchored = true
	hrp.CFrame = hitbox.CFrame * TELEPORT_OFFSET
end
local function waitUntilDestroyed(crystal)
	while ENABLED and crystal and crystal.Parent do
		task.wait(CHECK_INTERVAL)
	end
end
task.spawn(function()
	while true do
		if ENABLED then
			local list = findEnemyCrystalsOrdered()
			for _, crystal in ipairs(list) do
				if not ENABLED then break end
				if crystal and crystal.Parent then
					teleportToCrystal(crystal)
					waitUntilDestroyed(crystal)
				end
			end
		end
		task.wait(1)
	end
end)
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 170, 0, 70)
frame.Position = UDim2.new(0.05, 0, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
frame.Active = true
frame.Draggable = true

local btn = Instance.new("TextButton", frame)
btn.Size = UDim2.new(1, -10, 1, -10)
btn.Position = UDim2.new(0,5,0,5)
btn.Text = "START TELE"
btn.Font = Enum.Font.SourceSansBold
btn.TextSize = 16
btn.TextColor3 = Color3.new(1,1,1)
btn.BackgroundColor3 = Color3.fromRGB(0,150,0)

btn.MouseButton1Click:Connect(function()
	ENABLED = not ENABLED
	if ENABLED then
		btn.Text = "STOP TELE"
		btn.BackgroundColor3 = Color3.fromRGB(150,0,0)
	else
		btn.Text = "START TELE"
		btn.BackgroundColor3 = Color3.fromRGB(0,150,0)
		hrp.Anchored = false
	end
end)

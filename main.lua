-- SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- ================== STATE ==================
local KillAura = false
local MultiAttack = false
local SpeedRun = false

local SpeedAttackValue = 0.15
local MultiRange = 10
local SpeedRunValue = 24

-- ================== GUI ==================
local gui = Instance.new("ScreenGui", player.PlayerGui)
gui.Name = "MobileCombatMenu"
gui.ResetOnSpawn = false

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0,220,0,300)
main.Position = UDim2.new(0,20,0.4,0)
main.BackgroundColor3 = Color3.fromRGB(25,25,25)
main.Active = true
main.Draggable = true
Instance.new("UICorner", main)

local header = Instance.new("TextButton", main)
header.Size = UDim2.new(1,0,0,35)
header.Text = "⚔ MENU (Thu gọn)"
header.BackgroundColor3 = Color3.fromRGB(40,40,40)
header.TextColor3 = Color3.new(1,1,1)

local body = Instance.new("Frame", main)
body.Position = UDim2.new(0,0,0,35)
body.Size = UDim2.new(1,0,1,-35)
body.BackgroundTransparency = 1

local collapsed = false
header.MouseButton1Click:Connect(function()
	collapsed = not collapsed
	body.Visible = not collapsed
	header.Text = collapsed and "⚔ MENU (Mở)" or "⚔ MENU (Thu gọn)"
	main.Size = collapsed and UDim2.new(0,220,0,35) or UDim2.new(0,220,0,300)
end)

-- ================== UI HELPER ==================
local function toggleButton(text,y,callback)
	local b = Instance.new("TextButton", body)
	b.Size = UDim2.new(1,-20,0,30)
	b.Position = UDim2.new(0,10,0,y)
	b.Text = text .. ": OFF"
	b.BackgroundColor3 = Color3.fromRGB(120,50,50)
	b.TextColor3 = Color3.new(1,1,1)
	Instance.new("UICorner", b)

	local state = false
	b.MouseButton1Click:Connect(function()
		state = not state
		b.Text = text .. (state and ": ON" or ": OFF")
		b.BackgroundColor3 = state and Color3.fromRGB(50,150,50) or Color3.fromRGB(120,50,50)
		callback(state)
	end)
end

local function slider(text,y,min,max,default,callback)
	local label = Instance.new("TextLabel", body)
	label.Position = UDim2.new(0,10,0,y)
	label.Size = UDim2.new(1,-20,0,20)
	label.Text = text..": "..default
	label.TextColor3 = Color3.new(1,1,1)
	label.BackgroundTransparency = 1

	local bar = Instance.new("Frame", body)
	bar.Position = UDim2.new(0,10,0,y+22)
	bar.Size = UDim2.new(1,-20,0,8)
	bar.BackgroundColor3 = Color3.fromRGB(60,60,60)

	local fill = Instance.new("Frame", bar)
	fill.Size = UDim2.new((default-min)/(max-min),0,1,0)
	fill.BackgroundColor3 = Color3.fromRGB(0,170,255)

	local dragging = false
	bar.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
		end
	end)
	bar.InputEnded:Connect(function()
		dragging = false
	end)

	RunService.RenderStepped:Connect(function()
		if dragging then
			local x = math.clamp((UIS:GetMouseLocation().X - bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
			fill.Size = UDim2.new(x,0,1,0)
			local value = math.floor(min + (max-min)*x)
			label.Text = text..": "..value
			callback(value)
		end
	end)
end

-- ================== ADD UI ==================
toggleButton("Kill Aura",0,function(v) KillAura=v end)
toggleButton("Multi Attack",40,function(v) MultiAttack=v end)
toggleButton("Speed Run",80,function(v) SpeedRun=v end)

slider("Speed Attack",120,5,40,15,function(v) SpeedAttackValue=v/100 end)
slider("Multi Range",170,5,30,10,function(v) MultiRange=v end)
slider("Speed Run",220,16,60,24,function(v) SpeedRunValue=v end)

-- ================== COMBAT ==================
local function getSword()
	local char = player.Character
	if not char then return end
	for _,v in pairs(char:GetChildren()) do
		if v:IsA("Tool") then return v end
	end
	for _,v in pairs(player.Backpack:GetChildren()) do
		if v:IsA("Tool") then v.Parent=char return v end
	end
end

-- Speed Run
RunService.RenderStepped:Connect(function()
	local char = player.Character
	if char and char:FindFirstChild("Humanoid") then
		char.Humanoid.WalkSpeed = SpeedRun and SpeedRunValue or 16
	end
end)

-- Kill aura + multi
task.spawn(function()
	while true do
		if KillAura then
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			local sword = getSword()
			if root and sword then
				for _,m in pairs(workspace:GetDescendants()) do
					if m:IsA("Model") and m:FindFirstChild("Humanoid") and m ~= char then
						local hrp = m:FindFirstChild("HumanoidRootPart")
						if hrp and (hrp.Position-root.Position).Magnitude <= (MultiAttack and MultiRange or 5) then
							root.CFrame = hrp.CFrame * CFrame.new(0,0,-3)
							sword:Activate()
						end
					end
				end
			end
		end
		task.wait(SpeedAttackValue)
	end
end)

-- ================== HITBOX MOB ==================
for _,m in pairs(workspace:GetDescendants()) do
	if m:IsA("Model") and m:FindFirstChild("HumanoidRootPart") then
		local box = Instance.new("BoxHandleAdornment", m)
		box.Adornee = m.HumanoidRootPart
		box.Size = m.HumanoidRootPart.Size
		box.Color3 = Color3.fromRGB(255,0,0)
		box.Transparency = 0.6
		box.AlwaysOnTop = true
	end
end

-- ================== CHEST ESP ==================
local chestColors = {
	White = Color3.new(1,1,1),
	Green = Color3.fromRGB(0,255,0),
	Blue = Color3.fromRGB(0,170,255),
	Purple = Color3.fromRGB(170,0,255),
	Yellow = Color3.fromRGB(255,255,0),
	Red = Color3.fromRGB(255,0,0),
	Black = Color3.fromRGB(0,0,0)
}

for _,c in pairs(workspace:GetDescendants()) do
	if c:IsA("Part") and chestColors[c.Name] then
		local hl = Instance.new("Highlight", c)
		hl.FillColor = chestColors[c.Name]
		hl.OutlineColor = chestColors[c.Name]
	end
end

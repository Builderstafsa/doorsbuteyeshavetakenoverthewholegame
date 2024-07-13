local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PossibleHallways = ReplicatedStorage:WaitForChild("Possible Hallways")
local PossibleFurniture = ReplicatedStorage:WaitForChild("Possible Furniture")
local GeneratedRooms = workspace:WaitForChild("Generated Rooms")

prevRoom = workspace.StartPoint

local numRooms = 101 

local room = {}
room.info = require(script.RoomInfo)
room.LastTurn = nil
room.random = Random.new()

function interactDrawer(drawer, isopenval, originalcframe)
	local TweenService = game:GetService("TweenService")

	if isopenval.Value == false then
		isopenval.Value = true

		local opensound = drawer.PrimaryPart:FindFirstChild("Drawer Open")

		if opensound then
			opensound:Play()
		end

		local openedcframe = originalcframe * CFrame.new(0,0,-1.5)
		local tween = TweenService:Create(drawer.PrimaryPart, TweenInfo.new(0.5), {CFrame = openedcframe})
		tween:Play()

		local coinpickup = drawer:FindFirstChild("CoinPickup")

		if coinpickup then
			local prompt = coinpickup.CoinPickup:FindFirstChild("ProximityPrompt")

			if prompt then
				prompt.Enabled = true
			end
		end

	else
		isopenval.Value = false

		local closesound = drawer.PrimaryPart:FindFirstChild("Drawer Close")

		if closesound then
			closesound:Play()
		end

		local tween = TweenService:Create(drawer.PrimaryPart, TweenInfo.new(0.5), {CFrame = originalcframe})
		tween:Play()

		local coinpickup = drawer:FindFirstChild("CoinPickup")

		if coinpickup then
			local prompt = coinpickup.CoinPickup:FindFirstChild("ProximityPrompt")

			if prompt then
				prompt.Enabled = false
			end
		end
	end
end

function getRoom(prevRoom)
	local randomroom = PossibleHallways:GetChildren()[math.random(1, #PossibleHallways:GetChildren())]

	local direction = room.info[randomroom.Name]["Direction"]

	if (prevRoom.Name == randomroom.Name) or (direction and direction == room.LastTurn) then
		return getRoom(prevRoom)
	else

		if direction then
			room.LastTurn = direction
		end

		return randomroom
	end
end

function flickerLights(Part, PointLight)
	local NewSound = script.LightFlicker:Clone()
	NewSound.Parent = Part
	NewSound:Play()

	game:GetService("Debris"):AddItem(NewSound, NewSound.TimeLength)

	PointLight.Enabled = true
	wait(0.05)
	PointLight.Enabled = false
	wait(0.05)
	PointLight.Enabled = true
	wait(0.05)
	PointLight.Enabled = false
	wait(0.05)
	PointLight.Enabled = true
	wait(0.05)
	PointLight.Enabled = false
	wait(0.05)
	PointLight.Enabled = true
	wait(0.5)
	PointLight.Enabled = false
	wait(0.5)
	PointLight.Parent.Color = Color3.fromRGB(91, 91, 91)
end

function generateRoom(roomNum)
	local randomroom = getRoom(prevRoom)
	local clonedroom = randomroom:Clone()

	local isLocked = false
	local generatedKey = false

	clonedroom.PrimaryPart = clonedroom.Exit
	clonedroom:PivotTo(prevRoom.Entrance.CFrame)

	clonedroom.Parent = GeneratedRooms
	clonedroom.Entrance.Transparency = 1
	clonedroom.Exit.Transparency = 1

	local cloneddoor = ReplicatedStorage:WaitForChild("Door"):Clone()
	cloneddoor.Parent = clonedroom
	cloneddoor.RoomNum.Value = roomNum
	cloneddoor:PivotTo(clonedroom.Entrance.CFrame)

	for i, eye in pairs(clonedroom.Eyes:GetChildren()) do
		if eye.ClassName == "Model" then

			for i, part in pairs(eye:GetChildren()) do
				part.Transparency = 1

				if part.Name == "Eye" then
					local Decal = part:FindFirstChild("Decal")

					if Decal then
						Decal.Transparency = 1
					end

				elseif part.Name == "Part" then
					part:Destroy()
				end
			end
		end
	end

	local determineJack = math.random(1, 20)

	if determineJack <= 1 then
		local newJackAI = ReplicatedStorage.JackAI:Clone()
		newJackAI.Parent = cloneddoor
		newJackAI:PivotTo(cloneddoor.JackSpawnPoint.CFrame)

		local jackTag = Instance.new("StringValue", cloneddoor)
		jackTag.Name = "JackTag"
	end

	local roomVal = Instance.new("IntValue", clonedroom)
	roomVal.Name = "RoomVal"
	roomVal.Value = roomNum

	local plate = cloneddoor.Base:FindFirstChild("Plate")

	if plate then
		plate.RoomNumber.TextLabel.Text = roomNum
	end

	local ClosetFolder = clonedroom:FindFirstChild("Closets")

	if ClosetFolder then
		local TemplateFolder = ClosetFolder:WaitForChild("Templates")
		local ModelsFolder = ClosetFolder:WaitForChild("Models")

		if TemplateFolder then
			for i, template in pairs(TemplateFolder:GetChildren()) do
				template.Transparency = 1
				template.CanCollide = false
				template.CanTouch = false
				template.CanQuery = false

				local newCloset = ReplicatedStorage.Closet:Clone()
				newCloset.Parent = ModelsFolder
				newCloset:PivotTo(template.CFrame)
				newCloset.PrimaryPart.CanCollide = false

				local LeaveRootPart = newCloset:FindFirstChild("LeaveRootPart")
				local RootPart = newCloset:FindFirstChild("RootPart")

				local PromptAttachment = newCloset.PrimaryPart:FindFirstChild("PromptAttach")

				if PromptAttachment then
					local newPrompt = Instance.new("ProximityPrompt")
					newPrompt.Parent = PromptAttachment
					newPrompt.RequiresLineOfSight = false
					newPrompt.MaxActivationDistance = 6

					newPrompt.Triggered:Connect(function(player)
						if player then
							local Character = player.Character
							local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
							local Humanoid = Character:FindFirstChild("Humanoid")

							if Character:FindFirstChild("isHiding") then
								newCloset.Occupied.Value = false

								HumanoidRootPart.CFrame = LeaveRootPart.CFrame
								Humanoid.WalkSpeed = 16
								Humanoid.JumpPower = 50

								wait()
								Character:FindFirstChild("isHiding"):Destroy()
							else
								if newCloset.Occupied.Value == false then
									newCloset.Occupied.Value = true

									local newString = Instance.new("StringValue", Character)
									newString.Name = "isHiding"

									HumanoidRootPart.CFrame = RootPart.CFrame
									Humanoid.WalkSpeed = 0
									Humanoid.JumpPower = 0
								end
							end
						end
					end)
				end
			end
		end
	end

	local FurnitureFolder = clonedroom:FindFirstChild("Furniture")

	if isLocked == false and FurnitureFolder then
		local determinelocked = math.random(1, 10)

		if determinelocked <= 5 then
			isLocked = true

			local newString = Instance.new("StringValue", cloneddoor)
			newString.Name = "Locked"

			cloneddoor:FindFirstChild("Lock").Transparency = 0
		end
	end

	if FurnitureFolder then
		local Models = FurnitureFolder:FindFirstChild("Models")
		local Templates = FurnitureFolder:FindFirstChild("Templates")

		if Models and Templates then

			for i, template in pairs(Templates:GetChildren()) do
				local randomfurniture = PossibleFurniture:GetChildren()[math.random(1, #PossibleFurniture:GetChildren())]
				local clonedfurniture = randomfurniture:Clone()

				clonedfurniture.Parent = Models
				clonedfurniture:PivotTo(template.CFrame)

				template:Destroy()

				if clonedfurniture:FindFirstChild("isShelf") then
					local drawers = clonedfurniture:FindFirstChild("Drawers")

					if isLocked == true then
						if generatedKey == false then
							generatedKey = true

							local determinedrawer = math.random(1,2)
							local newKey = ReplicatedStorage.KeyPickup:Clone()

							local newPrompt = Instance.new("ProximityPrompt", newKey.KeyPickup)
							newPrompt.MaxActivationDistance = 6
							newPrompt.RequiresLineOfSight = true
							newPrompt.ActionText = "Pickup"
							newPrompt.ObjectText = "Key"

							newPrompt.Triggered:Connect(function(player)
								if player.Backpack:FindFirstChild("Key") or player.Character:FindFirstChild("Key") then

								else
									local newToolKey = ReplicatedStorage.Key:Clone()
									newToolKey.Parent = player.Backpack
									newKey:Destroy()
								end
							end)

							if determinedrawer == 1 then
								local drawer1 = drawers:FindFirstChild("Drawer1")

								if drawer1 then
									newKey.Parent = drawer1

									local newWeld = Instance.new("Weld", drawer1.KeyTemplate)
									newWeld.Part0 = drawer1.KeyTemplate
									newWeld.Part1 = newKey.KeyPickup
								end

							else
								local drawer2 = drawers:FindFirstChild("Drawer2")

								if drawer2 then
									newKey.Parent = drawer2

									local newWeld = Instance.new("Weld", drawer2.KeyTemplate)
									newWeld.Part0 = drawer2.KeyTemplate
									newWeld.Part1 = newKey.KeyPickup
								end
							end
						end
					end

					if drawers then
						for i, drawer in pairs(drawers:GetChildren()) do

							if drawer.PrimaryPart:FindFirstChild("Drawer Open") or drawer.PrimaryPart:FindFirstChild("Drawer Close") then

							else
								local newOpenSound = script["Drawer Open"]:Clone()
								local newCloseSound = script["Drawer Close"]:Clone()

								newCloseSound.Parent = drawer.PrimaryPart
								newOpenSound.Parent = drawer.PrimaryPart
							end

							local isopenval = drawer:FindFirstChild("isOpen")
							local interactattachment = drawer.Base:FindFirstChild("Interact")

							local originalcframe = drawer.PrimaryPart.CFrame

							drawer.KeyTemplate.Transparency = 1

							if isopenval and interactattachment then
								local newPrompt = Instance.new("ProximityPrompt", interactattachment)
								newPrompt.MaxActivationDistance = 6
								newPrompt.RequiresLineOfSight = false
								newPrompt.ActionText = ""
								newPrompt.Style = "Custom"

								newPrompt.Triggered:Connect(function()
									interactDrawer(drawer, isopenval, originalcframe)
								end)

								local determinecoin = math.random(1, 20)

								if determinecoin == 1 then
									--//Make Coin

									if not drawer:FindFirstChild("KeyPickup") then
										local chance = math.random(10, 100)
										if chance ~= 10 then
											local newCoin = ReplicatedStorage.CoinPickup:Clone()
											newCoin.Parent = drawer

											local newWeld = Instance.new("Weld", drawer.KeyTemplate)
											newWeld.Part0 = drawer.KeyTemplate
											newWeld.Part1 = newCoin.PrimaryPart

											local newPrompt = Instance.new("ProximityPrompt", newCoin.CoinPickup)
											newPrompt.MaxActivationDistance = 6
											newPrompt.RequiresLineOfSight = false
											newPrompt.ActionText = "Pickup"
											newPrompt.ObjectText = "OxygenTank"
											newPrompt.Enabled = false

											newPrompt.Triggered:Connect(function(player)
												local coin = game.ReplicatedStorage.OxygenTank:Clone()


												coin.Parent = player.Backpack	
												newCoin:Destroy()
										elseif chance == 10 then
											local newMedKit = ReplicatedStorage.MedKitPickUp
											newMedKit.Parent = drawer

											local newWeld = Instance.new("Weld", drawer.KeyTemplate)
											newWeld.Part0 = drawer.KeyTemplate
											newWeld.Part1 = newMedKit.PrimaryPart

											local newPrompt = Instance.new("ProximityPrompt", newMedKit.CoinPickup)
											newPrompt.MaxActivationDistance = 6
											newPrompt.RequiresLineOfSight = false
											newPrompt.ActionText = "Pickup"
											newPrompt.ObjectText = "MedKit"
											newPrompt.Enabled = false

											newPrompt.Triggered:Connect(function(player)
												local medkit = game.ReplicatedStorage.MedKitTool:Clone()


												medkit.Parent = player.Backpack	
												newMedKit:Destroy()
											end)
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
end
end
end

	local determinelights = math.random(1, 10)

	if determinelights <= 2 then
		local lightsfolder = clonedroom:FindFirstChild("Lights")

		if lightsfolder then
			for i, light in pairs(lightsfolder:GetChildren()) do
				light.Material = Enum.Material.SmoothPlastic
				light.Color = Color3.fromRGB(120, 120, 120)

				local pointlight = light:FindFirstChildWhichIsA("PointLight")

				if pointlight then
					pointlight.Enabled = false
				end
			end
		end

	else

	end

	prevRoom = clonedroom

	wait()
	cloneddoor.Handler.Enabled = true
end

function generateJeffsShop(roomNum)
	local clonedroom = ReplicatedStorage.JeffsShop:Clone()

	clonedroom.PrimaryPart = clonedroom.Exit
	clonedroom:PivotTo(prevRoom.Entrance.CFrame)

	clonedroom.Parent = GeneratedRooms
	clonedroom.Entrance.Transparency = 1
	clonedroom.Exit.Transparency = 1

	local cloneddoor = ReplicatedStorage:WaitForChild("Door"):Clone()
	cloneddoor.Parent = clonedroom
	cloneddoor.RoomNum.Value = roomNum
	cloneddoor:PivotTo(clonedroom.Entrance.CFrame)

	local roomVal = Instance.new("IntValue", clonedroom)
	roomVal.Name = "RoomVal"
	roomVal.Value = roomNum

	local plate = cloneddoor.Base:FindFirstChild("Plate")

	if plate then
		plate.RoomNumber.TextLabel.Text = roomNum
	end

	local purchaseablesfolder = clonedroom:FindFirstChild("Purchaseables")

	if purchaseablesfolder then
		for i, item in pairs(purchaseablesfolder:GetChildren()) do
			local targetprompt = item.Handle.PromptAttachment:FindFirstChild("PurchasePrompt")
			local targetinfo = ReplicatedStorage.ToolPurchaseInformation:FindFirstChild(item.Name)

			if targetinfo and targetprompt then
				local cost = targetinfo.Cost
				targetprompt.ObjectText = item.Name.." ("..cost.Value.." Coins)"

				targetprompt.Triggered:Connect(function(player)

					if player.Stats.Coins.Value >= cost.Value and not player.Backpack:FindFirstChild(item.Name) then
						player.Stats.Coins.Value = player.Stats.Coins.Value - cost.Value

						local newTool = ReplicatedStorage.Tools:FindFirstChild(item.Name):Clone()
						newTool.Parent = player.Backpack

					end
				end)
			end
		end
	end

	prevRoom = clonedroom

	wait()
	cloneddoor.Handler.Enabled = true
end

function generateLastRoom(roomNum)
	local clonedroom = game.Workspace.LastRoom:Clone()
	local BooksFolder = clonedroom.Books.Books
	clonedroom.PrimaryPart = clonedroom.Exit
	clonedroom:PivotTo(prevRoom.Entrance.CFrame)

	clonedroom.Parent = GeneratedRooms
	clonedroom.Entrance.Transparency = 1
	clonedroom.Exit.Transparency = 1

	local cloneddoor = ReplicatedStorage:WaitForChild("Door"):Clone()
	cloneddoor.Parent = clonedroom
	cloneddoor.RoomNum.Value = roomNum
	cloneddoor:PivotTo(clonedroom.Entrance.CFrame)


	cloneddoor:FindFirstChild("Lock").Transparency = 1

	local roomVal = Instance.new("IntValue", clonedroom)
	roomVal.Name = "RoomVal"
	roomVal.Value = roomNum
	BooksFolder.Parent = ReplicatedStorage
	local plate = cloneddoor.Base:FindFirstChild("Plate")

	if plate then
		plate.RoomNumber.TextLabel.Text = roomNum
	end

	prevRoom = clonedroom

	wait()
	cloneddoor.Handler.Enabled = true
end
function generateComms(roomNum)
	local clonedroom = ReplicatedStorage.ComsHallway:Clone()
	local changeofit = math.random(1, 10000)
	local change = clonedroom.Change
	clonedroom.PrimaryPart = clonedroom.Exit
	clonedroom:PivotTo(prevRoom.Entrance.CFrame)

	clonedroom.Parent = GeneratedRooms
	clonedroom.Entrance.Transparency = 1
	clonedroom.Exit.Transparency = 1

	local cloneddoor = ReplicatedStorage:WaitForChild("Door"):Clone()
	cloneddoor.Parent = clonedroom
	cloneddoor.RoomNum.Value = roomNum
	cloneddoor:PivotTo(clonedroom.Entrance.CFrame)


	cloneddoor:FindFirstChild("Lock").Transparency = 1

	local roomVal = Instance.new("IntValue", clonedroom)
	roomVal.Name = "RoomVal"
	roomVal.Value = roomNum

	local plate = cloneddoor.Base:FindFirstChild("Plate")

	if plate then
		plate.RoomNumber.TextLabel.Text = roomNum
	end

	prevRoom = clonedroom

	wait()
	cloneddoor.Handler.Enabled = true
	if changeofit > 5000 then
		change.Parent = ReplicatedStorage
		wait(10)
		clonedroom.AttackingBodys.thunder_4297.Animate.Enabled = true
		clonedroom.AttackingBodys.thunder_4297.Follow.Enabled = true
		clonedroom.AttackingBodys.llklkokkllllolloolol.Animate.Enabled = true
		clonedroom.AttackingBodys.llklkokkllllolloolol.Follow.Enabled = true
		clonedroom.AttackingBodys.gamemaker.Animate.Enabled = true
		clonedroom.AttackingBodys.gamemaker.Follow.Enabled = true
		clonedroom.AttackingBodys.f6rbtb3t35.Animate.Enabled = true
		clonedroom.AttackingBodys.f6rbtb3t35.Follow.Enabled = true
		clonedroom.AttackingBodys.Nikolai8.Animate.Enabled = true
		clonedroom.AttackingBodys.Nikolai8.Follow.Enabled = true
		wait(0.1)
		clonedroom.CollectorNow.Parent = ReplicatedStorage
		clonedroom.AttackingBodys.Parent = game.ReplicatedStorage

	end
	if changeofit < 5000 then
		print("It's already in ComsHallway")
		clonedroom.Connection.Screen.Screen.SurfaceGui.TextLabel.TextColor3 = Color3.fromRGB(32, 255, 27)
		clonedroom.Connection.Screen.Screen.SurfaceGui.TextLabel.Text = "01100011 01100100 00100000 01000011 01100001 01101101 01100101 01110010 01100001 00101111 01010010 01100101 01100011 01101111 01110010 01100100 01110011 00101111 01010011 01100101 01100011 01110010 01100101 01110100 00101111 01010111 01100001 01110010 01010010 01100101 01100011 01101111 01110010 01100100 01110011 00101111 00110000 00110110 00101110 00110000 00110100 00101110 00110001 00111001 00110010 00110011 00101110 01110111 01100001 01110110"
		clonedroom.Connection.KeyboardPart.Enter.Enabled = true
		clonedroom.StartPart.Script.Enabled = false
		clonedroom.CollectorNow:Destroy()
		clonedroom.AttackingBodys:Destroy()
		clonedroom.Connection.KeyboardPart.Enter.Triggered:Connect(function()
			clonedroom.WillChangeScreen.Screen.SurfaceGui.TextLabel.TextColor3 = Color3.fromRGB(255, 199, 21)
			clonedroom.WillChangeScreen.Screen.SurfaceGui.TextLabel.Text = "Connection:Middle"
			clonedroom.Connection.Screen.Screen.SurfaceGui.TextLabel.Text = "Connection found, please contact Builders' as quick as you can, I see that you're in a lost place."
			clonedroom.Bending_Microphone.Foam.ProximityPrompt.Enabled = true
		end)
		clonedroom.Bending_Microphone.Foam.ProximityPrompt.Triggered:Connect(function(player)
			clonedroom.Connection.Screen.Screen.SurfaceGui.TextLabel.TextColor3 = Color3.fromRGB(255, 143, 8)
			wait(10)
			clonedroom.Connection.Screen.Screen.SurfaceGui.TextLabel.Text = "50"
			while clonedroom.Connection.Screen.Screen.SurfaceGui.TextLabel.Text > 0 do
				wait(1)
				clonedroom.Connection.Screen.Screen.SurfaceGui.TextLabel.Text = clonedroom.Connection.Screen.Screen.SurfaceGui.TextLabel.Text - 1 
			end
			wait(50)
			clonedroom.WillChangeScreen.Screen.SurfaceGui.TextLabel.Text = "Connection:Lost"
			clonedroom.WillChangeScreen.Screen.SurfaceGui.TextLabel.TextColor3 = Color3.fromRGB(248, 28, 0)
			change.SoundPart.explosion:Play()
			change.SoundPart.explosion:Play()
			change.SoundPart.explosion:Play()
			clonedroom.Connection.Screen.Screen.SurfaceGui.Textlabel.Text = "Error:Connection Couldn't Find"
		end)
		wait(20)
		change.hawlifreddy:Destroy()
		change.builderstafsa:Destroy()
	end
end
function generateOxygenRoom(roomNum)
	local clonedroom = ReplicatedStorage.OxygenHallway:Clone()

	clonedroom.PrimaryPart = clonedroom.Exit
	clonedroom:PivotTo(prevRoom.Entrance.CFrame)

	clonedroom.Parent = GeneratedRooms
	clonedroom.Entrance.Transparency = 1
	clonedroom.Exit.Transparency = 1

	local cloneddoor = ReplicatedStorage:WaitForChild("Door"):Clone()
	cloneddoor.Parent = clonedroom
	cloneddoor.RoomNum.Value = roomNum
	cloneddoor:PivotTo(clonedroom.Entrance.CFrame)


	cloneddoor:FindFirstChild("Lock").Transparency = 1

	local roomVal = Instance.new("IntValue", clonedroom)
	roomVal.Name = "RoomVal"
	roomVal.Value = roomNum

	local plate = cloneddoor.Base:FindFirstChild("Plate")

	if plate then
		plate.RoomNumber.TextLabel.Text = roomNum
	end

	prevRoom = clonedroom

	wait()
	cloneddoor.Handler.Enabled = true
end
function generateOxygenRoom1(roomNum)
	local clonedroom = ReplicatedStorage.OxygenHallway1:Clone()

	clonedroom.PrimaryPart = clonedroom.Exit
	clonedroom:PivotTo(prevRoom.Entrance.CFrame)

	clonedroom.Parent = GeneratedRooms
	clonedroom.Entrance.Transparency = 1
	clonedroom.Exit.Transparency = 1

	local cloneddoor = ReplicatedStorage:WaitForChild("Door"):Clone()
	cloneddoor.Parent = clonedroom
	cloneddoor.RoomNum.Value = roomNum
	cloneddoor:PivotTo(clonedroom.Entrance.CFrame)


	cloneddoor:FindFirstChild("Lock").Transparency = 1

	local roomVal = Instance.new("IntValue", clonedroom)
	roomVal.Name = "RoomVal"
	roomVal.Value = roomNum

	local plate = cloneddoor.Base:FindFirstChild("Plate")

	if plate then
		plate.RoomNumber.TextLabel.Text = roomNum
	end

	prevRoom = clonedroom

	wait()
	cloneddoor.Handler.Enabled = true
end

function generateSeekCorridor(roomNum)
	local clonedroom = ReplicatedStorage.SeekCorridor:Clone()

	clonedroom.PrimaryPart = clonedroom.Exit
	clonedroom:PivotTo(prevRoom.Entrance.CFrame)

	clonedroom.Parent = GeneratedRooms
	clonedroom.Entrance.Transparency = 1
	clonedroom.Exit.Transparency = 1

	local cloneddoor = ReplicatedStorage:WaitForChild("Door"):Clone()
	cloneddoor.Parent = clonedroom
	cloneddoor.RoomNum.Value = roomNum
	cloneddoor:PivotTo(clonedroom.Entrance.CFrame)

	local roomVal = Instance.new("IntValue", clonedroom)
	roomVal.Name = "RoomVal"
	roomVal.Value = roomNum

	local plate = cloneddoor.Base:FindFirstChild("Plate")

	if plate then
		plate.RoomNumber.TextLabel.Text = roomNum
	end

	for i, eye in pairs(prevRoom.Eyes:GetChildren()) do
		if eye.ClassName == "Model" then

			for i, part in pairs(eye:GetChildren()) do
				part.Transparency = 0

				if part.Name == "Eye" then
					local Decal = part:FindFirstChild("Decal")

					if Decal then
						Decal.Transparency = 0
					end
				end
			end
		end
	end

end
function generateLabRoom(roomNum)
	local clonedroom = workspace.LabRoom:Clone()

	clonedroom.PrimaryPart = clonedroom.Exit
	clonedroom:PivotTo(prevRoom.Entrance.CFrame)

	clonedroom.Parent = GeneratedRooms
	clonedroom.Entrance.Transparency = 1
	clonedroom.Exit.Transparency = 1

	local cloneddoor = ReplicatedStorage:WaitForChild("Door"):Clone()
	cloneddoor.Parent = clonedroom
	cloneddoor.RoomNum.Value = roomNum
	cloneddoor:PivotTo(clonedroom.Entrance.CFrame)

	cloneddoor:FindFirstChild("Lock").Transparency = 1

	local roomVal = Instance.new("IntValue", clonedroom)
	roomVal.Name = "RoomVal"
	roomVal.Value = roomNum

	local plate = cloneddoor.Base:FindFirstChild("Plate")

	if plate then
		plate.RoomNumber.TextLabel.Text = roomNum
	end

	prevRoom = clonedroom

	wait()
	cloneddoor.Handler.Enabled = true
end


local Rush = require(script.Rush)
local generatedrooms = {prevRoom}

for i = 1, numRooms do
	if i == 10 then
		generateOxygenRoom1(i)
	elseif i == 20 then
		generateOxygenRoom(i)
	elseif i == 30 then
		generateLabRoom(i)
	elseif i == 100 then
		generateLastRoom(i)
	elseif i == 79 then
		generateComms(i)
	else	
		generateRoom(i)
	end

	generatedrooms[i] = prevRoom
end

script.doorOpen.Event:Connect(function(roomNum)

	for i, player in pairs(game:GetService("Players"):GetChildren()) do
		local CurrentRoom = player:FindFirstChild("CurrentRoom")

		if CurrentRoom then
			CurrentRoom.Value = roomNum
		end
	end

	if roomNum % 3 == 0 then
		local NextRoom
		local PreviousRoom

		for i, room in pairs(GeneratedRooms:GetChildren()) do
			if room.RoomVal.Value == roomNum + 1 then
				NextRoom = room

			elseif room.RoomVal.Value == roomNum then
				PreviousRoom = room
			end
		end

		wait()

		local PrevRoomLightsFolder = PreviousRoom:FindFirstChild("Lights")

		for i, light in pairs(PrevRoomLightsFolder:GetChildren()) do
			local PointLight = light:FindFirstChildWhichIsA("PointLight")

			if PointLight then
				flickerLights(light, PointLight)
			end
		end

		local NextRoomLightsFolder = NextRoom:FindFirstChild("Lights")

		for i, light in pairs(NextRoomLightsFolder:GetChildren()) do
			local PointLight = light:FindFirstChildWhichIsA("PointLight")

			if PointLight then
				flickerLights(light, PointLight)
			end
		end


		wait(3)

		Rush.New(roomNum, generatedrooms)
	end
end)

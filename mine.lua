-- Pre-functions

function Location()
	return {
		x = 0,
		y = 0,
		z = 0,
		d = 0, -- 0, forward. 1, left. 2, backward. 3, right. (counter-clockwise)
		turnLeft = function (self)
			self.d = (self.d + 1) % 4
		end,
		turnRight = function (self)
			self.d = (self.d - 1) % 4
		end,
		move = function (self, v)
			if self.d == 0 then
				self.z = self.z + v
			elseif self.d == 1 then
				self.x = self.x + v
			elseif self.d == 2 then
				self.z = self.z - v
			else
				self.x = self.x - v
			end
		end,
		mag = function (self)
			return math.sqrt((self.x * self.x) + (self.y * self.y) + (self.z * self.z))
		end
	}
end

function Set (list)
	local set = {}
	for _, l in ipairs(list) do
		set[l] = true
	end
	return set
end

function concat(consumer, supplier)
	for k, v in pairs(supplier) do
		consumer[k] = v
	end
	return consumer
end

-- Static Variables

local torchID = "minecraft:torch"

local filler = Set({
	"minecraft:dirt",
	"minecraft:grass",
	"minecraft:cobblestone",
	"minecraft:stone",
	"projectred-exploration:stone"
})

local trash = concat(Set({
	"minecraft:gravel",
	"minecraft:stonebrick",
	"minecraft:end_bricks",
	"minecraft:mycelium"
}), filler)

local badblocks = concat(Set({
	"minecraft:bedrock",
	torchID,
	"minecraft:lava",
	"minecraft:stone_stairs",                                            
	"minecraft:flowing_lava",
	"thermalfoundation:fluid_redstone",
	"buildcraftenergy:fluid_block_oil_heat_0",
	"buildcraftenergy:fluid_block_oil_heat_1",
	"buildcraftenergy:fluid_block_oil_heat_2",
	"minecraft:water",
	"minecraft:flowing_water"
}), trash)

local torch = 0
local targs = { ... }
local steps = tonumber(targs[1]) or 1
local mainSteps = 0
local torchesneeded = (steps > 14) and (steps / 14) or 0
local minFuel = 2000
local maxDistance = 5
local fuelNeeded = 2000
local tunnleCount = tonumber(targs[2])

local direction = nil
if targs[3] == "left" or targs[3] == "right" then
	direction = targs[3]
else
	print("Error: \"" .. targs[3] .. "\" is an invalid direction!")
	return
end

local useTorches = tonumber(targs[4]) == 1

-- Functions

function checkFuel()
	if (turtle.getFuelLevel() <= minFuel) then
		getFuel()
	end
	return
end

function getFuel()
	print("Please insert more fuel into slot 16")
	local oldSelction = 1;
	if (turtle.getSelectedSlot ~= 1) then
		local oldSlection = turtle.getSelectedSlot()
	end
	repeat
		sleep(1)
		turtle.select(16)
		turtle.refuel()
		turtle.drop()
	until (turtle.fuelLevel() >= (minFuel + fuelNeeded))
	
	if (oldSelction ~= turtle.getSelectedSlot()) then
		turtle.select(oldSelction)
	end
end

function dropAll()
	for i = 1, 16 do
		local target = turtle.getItemDetail(i)
		if (target) and (isValuable(target.name))then
			turtle.select(i)
			turtle.drop()
		end
	end
	return true
end

function moveToChest()
	--Prevents the bot from running wild
	if direction == "left" then
		turtle.turnRight()
	else
		turtle.turnLeft()
	end
	
	for i = 1, mainSteps do
		digForward(true)
	end
	
	--Drops all the items if the chest is found
	local check, data = turtle.inspect()
	if (data.name == "minecraft:chest") then
		dropAll()
	end
	
	--Returnes to the origin if there is more to do
	if (tunnleCount > 0) then
		turnAround()
		for i = 1, mainSteps do
			digForward(true)
		end
		if direction == "left" then
			turtle.turnRight()
		else
			turtle.turnLeft()
		end
	end
	
	return true
end

function isValuable(blockName)
	return not badblocks[blockName]
end

function turnAround()
	turtle.turnLeft()
	turtle.turnLeft()
end

function digForward(attack)
	if turtle.forward() then
		return true
	end
	while turtle.dig() do
		if turtle.forward() then
			return true
		end
	end
	if attack then
		turtle.attack()
		return digForward(attack)
	end
	return false
end

function digBack(attack)
	if turtle.back() then
		return true
	end
	turnAround()
	local success = digForward(attack)
	turnAround()
	return success
end

function digUp(attack)
	if turtle.up() then
		return true
	end
	while turtle.digUp() do
		if turtle.up() then
			return true
		end
	end
	if attack then
		turtle.attackUp()
		return digUp(attack)
	end
	return false
end

function digDown(attack)
	if turtle.down() then
		return true
	end
	while turtle.digDown() do
		if turtle.down() then
			return true
		end
	end
	if attack then
		turtle.attackDown()
		return digDown(attack)
	end
	return false
end

function processValuablesForward(relativeLocation)
	local success, data = turtle.inspect()
	-- Check block, dig block and move forward
	if success and isValuable(data.name) and digForward() then
		relativeLocation:move(1)
		processValuables(true, relativeLocation)
		digBack(true)
		relativeLocation:move(-1)
	end
end

function processValuables(forward, relativeLocation)
	if not relativeLocation then
		relativeLocation = Location()
	end
	-- Check recursion limit
	if relativeLocation:mag() > maxDistance then
		return
	end
	-- Process up block
	local successUp, dataUp = turtle.inspectUp()
	if successUp and isValuable(dataUp.name) and digUp() then
		relativeLocation.y = relativeLocation.y + 1
		processValuables(true, relativeLocation)
		digDown(true)
		relativeLocation.y = relativeLocation.y - 1
	end
	-- Turn left and process left block
	turtle.turnLeft()
	relativeLocation:turnLeft()
	processValuablesForward(relativeLocation)
	turtle.turnRight()
	relativeLocation:turnRight()
	-- Process forward block
	if forward then
		processValuablesForward(relativeLocation)
	end
	-- Turn right and process right block
	turtle.turnRight()
	relativeLocation:turnRight()
	processValuablesForward(relativeLocation)
	turtle.turnLeft()
	relativeLocation:turnLeft()
	-- Process down block
	local successDown, dataDown = turtle.inspectDown()
	if successDown and isValuable(dataDown.name) and digDown() then
		relativeLocation.y = relativeLocation.y - 1
		processValuables(true, relativeLocation)
		digUp(true)
		relativeLocation.y = relativeLocation.y + 1
	end
end

function selectFiller()
	local currentDetail = turtle.getItemDetail()
	if currentDetail and filler[currentDetail.name] then
		return true
	end
	for i = 1, 16 do
		local data = turtle.getItemDetail(i)
		if data and filler[data.name] then
			turtle.select(i)
			return true
		end
	end
	return false
end

function selectTorch()
	for i = 1, 16 do
		local detail = turtle.getItemDetail(i)
		if detail and (detail.name == torchID) then
			turtle.select(i)
			return true
		end
	end
	return false
end

function getTorchCount()
	local count = 0
	for i = 1, 16 do
		local detail = turtle.getItemDetail(i)
		if detail and (detail.name == torchID) then
			count = count + detail.count
		end
	end
	return count
end

function compactInventory()
	local oldSlot = turtle.getSelectedSlot()
	for source = 2, 16 do
		local sourceDetail = turtle.getItemDetail(source)
		if sourceDetail then
			for target = 1, source - 1 do
				local targetDetail = turtle.getItemDetail(target)
				if targetDetail and (sourceDetail.name == targetDetail.name) and (targetDetail.count < 64) then
					turtle.select(source)
					turtle.transferTo(target)
				end
			end
		end
	end
	if turtle.getSelectedSlot() ~= oldSlot then
		turtle.select(oldSlot)
	end
end

function removeTrash()
	local oldSlot = turtle.getSelectedSlot()
	for i = 2, 14 do
		local detail = turtle.getItemDetail(i)
		if detail and trash[detail.name] then
			turtle.select(i)
			turtle.drop()
		end
	end
	if turtle.getSelectedSlot() ~= oldSlot then
		turtle.select(oldSlot)
	end
end

-- Dynamic Variables

local torchesgot = getTorchCount()

-- Welcome messages

print(" ")
print("Smart Branch Miner")
print(" ")
print("Distance to mine: ", steps)
if useTorches then
	print("Torches needed: ", torchesneeded)
	print("Torch level: ", torchesgot)
end

-- Resource Acquiring

if useTorches and torchesgot < torchesneeded then
	print("Please insert required torches...")
	repeat
		sleep(0.5)
		torchesgot = getTorchCount()
	until torchesgot >= torchesneeded
end

print("Resources acquired. Beginning mining...")

-- Begin Digging

function digBranch()
	-- Dig forward
	for i = 1, steps do
		digForward(true)
		turtle.digUp()
		
		processValuables(false)
		
		-- Attempt to place cobblestone below turtle
		if selectFiller() then
			turtle.placeDown()
		end
		
		removeTrash()
		compactInventory()
		
		if useTorches then
			torch = torch + 1
			if torch == 14 then
				turnAround()
				selectTorch()
				turtle.place()
				turnAround()
				turtle.select(1)
				torch = 1
			end
		end
	end
	
	-- Return to origin
	digUp(true)
	for i = 1, steps do
		processValuables(false)
		digBack(true)
	end
	digDown(true)
	
	tunnleCount = tunnleCount - 1
	
	moveToChest()
	checkFuel()
end

digBranch()

while (tunnleCount > 0) do
	if direction == "left" then
		turtle.turnLeft()
	else
		turtle.turnRight()
	end
	for i = 1, 3 do -- leave 2 rows between each branch
		--Incement mainSteps for returning to chest
		if digForward() then
			mainSteps = mainSteps + 1
		end
		digUp(true)
		turtle.digUp()
		digDown(true)
	end
	if direction == "left" then
		turtle.turnRight()
	else
		turtle.turnLeft()
	end
	digBranch()
end

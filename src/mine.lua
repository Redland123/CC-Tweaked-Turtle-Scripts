-- Imports

local Location = require("lib.Location")
local Set = require("lib.Set")
local movement = require("lib.movement")
local dig = require("lib.dig")
local inventory = require("lib.inventory")

-- Static Variables

local torchID = "minecraft:torch"

local chests = Set({
	"minecraft:chest",
	"enderstorage:ender_storage"
})

local filler = Set({
	"minecraft:dirt",
	"minecraft:grass",
	"minecraft:cobblestone",
	"minecraft:stone",
	"projectred-exploration:stone"
})

local trash = Set({
	"minecraft:gravel",
	"minecraft:stonebrick",
	"minecraft:end_bricks",
	"minecraft:mycelium"
}) .. filler

local badblocks = Set({
	"minecraft:bedrock",
	torchID,
	"minecraft:lava",
	"minecraft:stone_stairs",
	"minecraft:flowing_lava",
	"thermalfoundation:fluid_redstone",
	"buildcraftenergy:fluid_block_oil_heat_0",
	"buildcraftenergy:fluid_block_oil_heat_1",
	"buildcraftenergy:fluid_block_oil_heat_2",
	"thermalfoundation:fluid_crude_oil",
	"minecraft:water",
	"minecraft:flowing_water"
}) .. trash .. chests

local torch = 0
local targs = { ... }
local steps = tonumber(targs[1]) or 1
local mainSteps = 0
local torchesneeded = (steps > 14) and (steps / 14) or 0
local minFuel = 10000
local maxDistance = 5
local fuelNeeded = 5000
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
	local oldSelection = 1;
	if (turtle.getSelectedSlot() ~= 1) then
		local oldSlection = turtle.getSelectedSlot()
	end
	repeat
		sleep(1)
		turtle.select(16)
		turtle.refuel()
		turtle.drop()
	until (turtle.getfuelLevel() >= (minFuel + fuelNeeded))
	
	if (oldSelection ~= turtle.getSelectedSlot()) then
		turtle.select(oldSelection)
	end
end

function moveToChest()
	-- Prevents the bot from running wild
	if direction == "left" then
		turtle.turnRight()
	else
		turtle.turnLeft()
	end
	
	for i = 1, mainSteps do
		dig.forward(true)
	end
	
	-- Drops all the items if the chest is found
	local check, data = turtle.inspect()
	if check and chests[data.name] then
		-- Unload valuable items into chest
		for i = 1, 16 do
			local target = turtle.getItemDetail(i)
			if (target) and (isValuable(target.name))then
				turtle.select(i)
				turtle.drop()
			end
		end
	end

	checkFuel()
	
	-- Returns to the origin if there is more to do
	if (tunnleCount > 0) then
		movement.turnAround()
		for i = 1, mainSteps do
			dig.forward(true)
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

function processValuablesForward(relativeLocation)
	local success, data = turtle.inspect()
	-- Check block, dig block and move forward
	if success and isValuable(data.name) and dig.forward() then
		relativeLocation:move(1)
		processValuables(true, relativeLocation)
		dig.back(true)
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
	if successUp and isValuable(dataUp.name) and dig.up() then
		relativeLocation.y = relativeLocation.y + 1
		processValuables(true, relativeLocation)
		dig.down(true)
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
	if successDown and isValuable(dataDown.name) and dig.down() then
		relativeLocation.y = relativeLocation.y - 1
		processValuables(true, relativeLocation)
		dig.up(true)
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

local torchesgot = inventory.countID(torchID)

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
		torchesgot = inventory.countID(torchID)
	until torchesgot >= torchesneeded
end

print("Resources acquired. Beginning mining...")

-- Begin Digging

function digBranch()
	-- Dig forward
	for i = 1, steps do
		dig.forward(true)
		turtle.digUp()

		--Allows for the user to check the fuel level of the turtle while mine is active
		print("Fuel level: " .. ((turtle.getFuelLevel()/turtle.getFuelLimit()) * 100) .. " %")
		
		processValuables(false)
		
		-- Attempt to place cobblestone below turtle
		if selectFiller() then
			turtle.placeDown()
		end
		
		removeTrash()
		inventory.compact()
		
		if useTorches then
			torch = torch + 1
			if torch == 14 then
				movement.turnAround()
				inventory.selectID(torchID)
				turtle.place()
				movement.turnAround()
				turtle.select(1)
				torch = 1
			end
		end
	end
	
	-- Return to origin
	dig.up(true)
	for i = 1, steps do
		processValuables(false)
		dig.back(true)
	end
	dig.down(true)
	
	tunnleCount = tunnleCount - 1
	
	moveToChest()
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
		if dig.forward() then
			mainSteps = mainSteps + 1
		end
		dig.up(true)
		turtle.digUp()
		dig.down(true)
	end
	if direction == "left" then
		turtle.turnRight()
	else
		turtle.turnLeft()
	end
	digBranch()
end

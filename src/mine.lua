-- Imports
local args = require("lib.args")
local Location = require("lib.Location")
local Set = require("lib.Set")
local movement = require("lib.movement")
local dig = require("lib.dig")
local inventory = require("lib.inventory")

-- Verify this is a turtle
if not turtle then 
	printError("Requires turtle")
	return
end

-- Static Variables
local torchID = "minecraft:torch"

-- Breadcumbs must not be affected by water (so not torches)
local breadcrumbIDs = Set({
	"minecraft:cobbled_deepslate",
	"minecraft:cobblestone"
})

local chests = Set({
	"minecraft:chest",
	"enderstorage:ender_storage",
	"ironchest:iron_chest"
})

-- Block IDs that will cause the turtle to cancel its job
-- if the block is placed next to the starting location
local cancelSides = Set({
	"minecraft:white_wool"
})

local cancelTop = Set({
	"minecraft:white_wool"
}) .. cancelSides

local filler = Set(breadcrumbIDs) .. Set({
	"minecraft:tuff",
	"minecraft:cobbled_deepslate",
	"minecraft:stone",
	"minecraft:granite",
	"minecraft:dirt",
	"minecraft:grass",
	"minecraft:netherrack",
	"projectred-exploration:stone"
})

local trash = Set({
	"minecraft:sand",
	"minecraft:sandstone",
	"minecraft:gravel",
	"minecraft:stonebrick",
	"minecraft:dripstone_block",
	"minecraft:andesite",
	"minecraft:smooth_basalt",
	"minecraft:end_bricks",
	"minecraft:mycelium",
	"projectx:xycronium_crystal", -- handles all colors of crystals
	"minecraft:rotten_flesh"
}) .. filler

local badblocks = Set({
	torchID,
	"minecraft:bedrock",
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

-- Configuration
local targs = { ... }

local numOfTunnels
local tunnelDepth
local tunnelOffset
local side
local useTorches
local useChest

if args.count(targs) == 0 then
	print("Start wizard:")
	print("")

	print("Tunnel count: [int]")
	numOfTunnels = tonumber(read())
	print("")

	print("Branch depth: [int]")
	tunnelDepth = tonumber(read())
	print("")

	print("Start offset: [int]")
	tunnelOffset = tonumber(read())
	print("")

	print("Side: [right|left]")
	side = read()
	print("")

	print("Place torches?: [true|false]")
	useTorches = read()
	print("")

	print("Use chest?: [true|false]")	
	useChest = read()
	print("")

elseif args.count(targs) >= 4 then
	numOfTunnels = tonumber(targs[1])
	tunnelDepth = tonumber(targs[2])	
	tunnelOffset = tonumber(targs[3])
	side = targs[4]
	useTorches = targs[5]
	useChest = targs[6]
else 
	print("Error: Wrong number of arguments")
	return 
end

-- Check numOfTunnels
if numOfTunnels == nil then
	print("Error: [num-of-tunnels] must be a number!")
	return
elseif numOfTunnels <= 0 then
	print("Error: [num-of-tunnels] must be greater than 0!")
	return
end

-- Check tunnelDepth
if tunnelDepth == nil then
	print("Error: [tunnel-depth] must be a number!")
	return
elseif tunnelDepth <= 0 then
	print("Error: [tunnel-depth] must be greater than 0!")
	return
end

-- Check tunnelOffset
if tunnelOffset == nil then
	print("Error: [tunnel-offset] must be a number!")
	return
elseif tunnelOffset < 0 then
	print("Error: [tunnel-offset] must be greater than or equal to 0!")
	return
end

-- Check side
if side == nil then
	print("Error: [Side] must not be null")
	return
elseif side ~= "right" and side ~= "left" then
	print("Error: [side] must be either right or left")
	return
end

-- Check useTorches
if useTorches == nil then
	useTorches = false
elseif useTorches == "true" then
	useTorches = true
elseif useTorches == "false" then
	useTorches = false
else
	print("Error: [use-torches] must be true or false")
	return
end

-- Check useChest
if useChest == nil then
	useChest = true
elseif useChest == "true" then
	useChest = true
elseif useChest == "false" then
	useChest = false
else 
	print("Error: [use-chest] must be true or false")
	return
end

-- Constants
local BLOCKS_BETWEEN_EACH_TUNNEL = 2
local MAX_DISTANCE = 5 -- distance to search for valuables away from the tunnel
local FUEL_SLOT = 16
local MIN_FUEL = 10000 -- this should be calculated based on numOfTunnels and tunnelDepth
local FUEL_NEEDED = 5000 -- this should be calculated based on numOfTunnels and tunnelDepth
local TORCHES_NEEDED = (tunnelDepth > 14) and (tunnelDepth / 14) or 0

-- Variables
local distanceFromChest = 0
local torchesgot = inventory.countID(torchID)

-- Startup diagnostics
print("Distance to mine: ", tunnelDepth)
if useTorches then
	print("Torches needed: ", TORCHES_NEEDED)
	print("Torch level: ", torchesgot)
end

-- Functions
function checkFuel()
	if turtle.getFuelLevel() <= MIN_FUEL then
		getFuel()
	end
	return
end

function getFuel()
	print("Please insert more fuel into slot " .. FUEL_SLOT)
	local oldSelection = turtle.getSelectedSlot()
	repeat
		sleep(1)
		turtle.select(FUEL_SLOT)
		turtle.refuel()
		turtle.drop()
	until turtle.getFuelLevel() >= (MIN_FUEL + FUEL_NEEDED)

	if oldSelection ~= turtle.getSelectedSlot() then
		turtle.select(oldSelection)
	end
end

-- Turtle should be facing down the most recent tunnel.
-- Returns whether the turtle moved back to the tunnel location (will be facing down the main mine shaft)
function moveToChest()
	local actualStepsMoved = moveToStartingLocation()

	-- Drops all the items if the chest is found
	local check, data = turtle.inspect()
	if check and chests[data.name] then
		-- Unload valuable items into chest
		for i = 1, 16 do
			local target = turtle.getItemDetail(i)
			if target and isValuable(target.name) then
				turtle.select(i)
				turtle.drop()
			end
		end
	end

	if numOfTunnels <= 0 then
		return false
	end

	-- Check if there is a cancel block above
	local successUp, dataUp = turtle.inspectUp()
	if successUp and cancelTop[dataUp.name] then
		numOfTunnels = -1
		return false
	end

	checkFuel()

	-- Check if there is a cancel block on either side
	turtle.turnRight()
	
	local successRight, dataRight = turtle.inspect()
	if successRight and cancelSides[dataRight.name] then
		numOfTunnels = -1
		return false
	end

	movement.turnAround()

	local successLeft, dataLeft = turtle.inspect()
	if successLeft and cancelSides[dataLeft.name] then
		numOfTunnels = -1
		return false
	end

	turtle.turnLeft()

	-- Returns to the origin if there is more to do
	for i = 1, actualStepsMoved do
		dig.forward(true)
	end

	return true
end

-- Assumes turtle is facing down a tunnel
function moveToStartingLocation()
	-- Turn to face up the main mining shaft (back towards the chest)
	if side == "left" then
		turtle.turnLeft()
	else
		turtle.turnRight()
	end

	local actualStepsMoved = 0
	for i = 1, distanceFromChest do
		local check, data = turtle.inspect()
		if check and chests[data.name] then
			break
		end
		if dig.forward(true) then
			actualStepsMoved = actualStepsMoved + 1
		end
	end

	return actualStepsMoved
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
	if relativeLocation:mag() > MAX_DISTANCE then
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

-- Returns the slot containing the optimal filler material,
-- or 0 if there is no filler material in the turtle's inventory.
function getOptimalFiller()
	local bestPriority = 1000000
	local bestSlot = 0
	for i = 1, 16 do
		local data = turtle.getItemDetail(i)
		if data then
			local priority = filler[data.name]
			if priority and priority < bestPriority then
				bestPriority = priority
				bestSlot = i
			end
		end
	end
	return bestSlot
end

function removeTrash(fillerSlot)
	if not fillerSlot then
		fillerSlot = getOptimalFiller()
	end
	local oldSlot = turtle.getSelectedSlot()
	for i = 1, 16 do
		if i ~= fillerSlot then
			local detail = turtle.getItemDetail(i)
			if detail and trash[detail.name] then
				turtle.select(i)
				turtle.drop()
			end
		end
	end
	if turtle.getSelectedSlot() ~= oldSlot then
		turtle.select(oldSlot)
	end
end

-- Primary Digging Functions

function digMain()
	if dig.forward() then
		-- Increment distanceFromChest for returning to chest
		distanceFromChest = distanceFromChest + 1
	end
	dig.up(true)
	turtle.digUp()
	dig.down(true)
end

-- A breadcrumb block at the beginning of tunnels indicate the tunnel is already completed
-- Turtle should be facing into the tunnel before checking for the breadcrumb
function hasBreadcrumb()
	local check, data = turtle.inspect()
	return check and breadcrumbIDs[data.name]
end

-- Turtle should be facing into the tunnel
-- Turtle will be facing into the tunnel when function returns
-- Returns whether a breadcrumb was successfully placed
function digBranch()
	local torch = 0

	-- Dig forward
	for i = 1, tunnelDepth do
		dig.forward(true)
		turtle.digUp()

		--Allows for the user to check the fuel level of the turtle while mine is active
		print("Fuel level: " .. ((turtle.getFuelLevel()/turtle.getFuelLimit()) * 100) .. " %")

		processValuables(false)

		-- Attempt to place a filler block below turtle
		local fillerSlot = getOptimalFiller()
		if fillerSlot > 0 then
			turtle.select(fillerSlot)
			turtle.placeDown()
		end

		inventory.compact()
		removeTrash(fillerSlot)

		if useTorches then
			torch = torch + 1
			if torch == 14 then
				if inventory.selectID(torchID) then
					movement.turnAround()
					turtle.place()
					movement.turnAround()
				end
				torch = 1
			end
		end
	end

	-- Return to main mining shaft
	dig.up(true)
	for i = 1, tunnelDepth do
		processValuables(false)

		inventory.compact()
		removeTrash()

		dig.back(true)
	end
	dig.down(true)

	-- Place breadcrumb on first block of tunnel
	if not inventory.selectIDs(breadcrumbIDs) then
		return false
	end
	-- Try 5 times to place breadcrumb
	for i = 1, 5 do
		if turtle.place() then
			return true
		end
		dig.forward(true)
		dig.back(true)
	end

	return turtle.place()
end

-- Verify that a chest is next to the turtle (if useChest is enabled)

if useChest then
	-- Attempt to find chest (could be in any direction)
	local found = false
	for i = 1, 4 do
		local check, data = turtle.inspect()
		if check and chests[data.name] then
			found = true
			break
		end
		turtle.turnLeft()
	end
	if not found then
		print("Error: Could not find a chest around the turtle!")
		return
	end
	-- Turn around to face away from chest
	movement.turnAround()
end

-- Resource Acquiring

if useTorches and torchesgot < TORCHES_NEEDED then
	print("Please insert required torches...")
	repeat
		sleep(0.5)
		torchesgot = inventory.countID(torchID)
	until torchesgot >= TORCHES_NEEDED
end

print("Resources acquired. Beginning mining...")

-- Start digging tunnels

local atStartingLocation = true
local stepsToNextTunnel = tunnelOffset
repeat
	-- Dig to next tunnel
	for i = 1, stepsToNextTunnel do
		digMain()
	end
	stepsToNextTunnel = 1 + BLOCKS_BETWEEN_EACH_TUNNEL
	-- Turn to face tunnel direction
	if side == "left" then
		turtle.turnLeft()
	else
		turtle.turnRight()
	end
	-- Decrement num of tunnels remaining
	numOfTunnels = numOfTunnels - 1
	-- Define local variable for tracking whether we are facing down the main shaft
	local facingDownMainShaft = false
	-- Check if tunnel has breadcrumb (this indicates tunnel has already been completed)
	if not hasBreadcrumb() then
		-- If no breadcrumb, then dig branch tunnel
		if not digBranch() then
			print("Error: No " .. breadcrumbIDs .. " available to place breadcrumb!")
			return
		end
		if useChest then
			-- Go to chest to deposit valuables
			atStartingLocation = not moveToChest()
			facingDownMainShaft = true
		end
	end
	if not facingDownMainShaft then
		-- Turn to face down main mining shaft
		if side == "left" then
			turtle.turnRight()
		else
			turtle.turnLeft()
		end
		atStartingLocation = false
	end
until numOfTunnels <= 0

-- Move back to starting location
if not atStartingLocation then
	-- Face back towards the tunnel to meet pre-req
	if side == "left" then
		turtle.turnLeft()
	else
		turtle.turnRight()
	end
	-- Now we go back to the starting location
	moveToStartingLocation()
end

if numOfTunnels < 0 then
	print("Cancelled!")
else
	print("Finished!")
end

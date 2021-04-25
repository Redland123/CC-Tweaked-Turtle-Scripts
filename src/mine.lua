-- Imports

local args = require("lib.args")
local Location = require("lib.Location")
local Set = require("lib.Set")
local movement = require("lib.movement")
local dig = require("lib.dig")
local inventory = require("lib.inventory")

-- Static Variables

local torchID = "minecraft:torch"
local breadcrumbID = "minecraft:cobblestone" -- a breadcrumb must not be affected by water (so no torches)

local chests = Set({
	"minecraft:chest",
	"enderstorage:ender_storage",
	"ironchest:iron_chest"
})

local filler = Set({
	"minecraft:dirt",
	"minecraft:grass",
	"minecraft:cobblestone",
	"minecraft:stone",
	"minecraft:netherrack",
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

-- Welcome messages

print("Smart Branch Miner")
print(" ")

-- Configuration

local targs = { ... }

if args.count(targs) < 4 then
	-- Print help
	textutils.pagedPrint("Arguments: mine [num-of-tunnels] [tunnel-depth] [tunnel-offset] [side:left|right] [use-torches:0|1] [use-chest:0|1]")
	textutils.pagedPrint("- num-of-tunnels: The number of tunnels to mine from the chest.")
	textutils.pagedPrint("- tunnel-depth: The number of blocks to mine from the main mining shaft.")
	textutils.pagedPrint("- tunnel-offset: The number of blocks to move forward from the starting location before mining the first tunnel.")
	textutils.pagedPrint("- side: Which side of the main mining shaft the turtle is on.")
	textutils.pagedPrint("? use-torches=false: Whether to use torches to light the tunnels.")
	textutils.pagedPrint("? use-chest=true: Whether to store items in a chest at the turtle's starting location.")
	textutils.pagedPrint("Instructions:")
	textutils.pagedPrint("- Place turtle facing down main tunnel on the side it should mine.")
	textutils.pagedPrint("- A chest should be directly behind the turtle.")
	textutils.pagedPrint("- The turtle will use " .. breadcrumbID .. " to mark each branching tunnel as complete.")
	return
end

local numOfTunnels = tonumber(targs[1])
if numOfTunnels == nil then
	print("Error: [num-of-tunnels] must be a number!")
	return
elseif numOfTunnels <= 0 then
	print("Error: [num-of-tunnels] must be greater than 0!")
	return
end

local tunnelDepth = tonumber(targs[2])
if tunnelDepth == nil then
	print("Error: [tunnel-depth] must be a number!")
	return
elseif tunnelDepth <= 0 then
	print("Error: [tunnel-depth] must be greater than 0!")
	return
end

local tunnelOffset = tonumber(targs[3])
if tunnelOffset == nil then
	print("Error: [tunnel-offset] must be a number!")
	return
elseif tunnelOffset < 0 then
	print("Error: [tunnel-offset] must be greater than or equal to 0!")
	return
end

local side = nil
if targs[4] == "left" or targs[4] == "right" then
	side = targs[4]
else
	print("Error: [side] must be either 'left' or 'right'!")
	return
end

local useTorches = tonumber(targs[5])
if useTorches == nil then
	useTorches = false
else
	useTorches = useTorches == 1
end

local useChest = tonumber(targs[6])
if useChest == nil then
	useChest = true
else
	useChest = useChest == 1
end

-- Constants

local BLOCKS_BETWEEN_EACH_TUNNEL = 2
local MAX_DISTANCE = 5 -- distance to search for valuables away from the tunnel
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
	print("Please insert more fuel into slot 16")
	local oldSelection = 1;
	if turtle.getSelectedSlot() ~= 1 then
		local oldSlection = turtle.getSelectedSlot()
	end
	repeat
		sleep(1)
		turtle.select(16)
		turtle.refuel()
		turtle.drop()
	until turtle.getfuelLevel() >= (MIN_FUEL + FUEL_NEEDED)

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

	checkFuel()

	-- Returns to the origin if there is more to do
	movement.turnAround()
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
	return check and data.name == breadcrumbID
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

		-- Attempt to place cobblestone below turtle
		if selectFiller() then
			turtle.placeDown()
		end

		removeTrash()
		inventory.compact()

		if useTorches then
			torch = torch + 1
			if torch == 14 then
				if inventory.selectID(torchID) then
					movement.turnAround()
					turtle.place()
					movement.turnAround()
					turtle.select(1)
				end
				torch = 1
			end
		end
	end

	-- Return to main mining shaft
	dig.up(true)
	for i = 1, tunnelDepth do
		processValuables(false)
		dig.back(true)
	end
	dig.down(true)

	-- Place breadcrumb on first block of tunnel
	if not inventory.selectID(breadcrumbID) then
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
			print("Error: No " .. breadcrumbID .. " available to place breadcrumb!")
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

print("Finished!")

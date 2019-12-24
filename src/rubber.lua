-- Globals
local minFuel = 2000
local fuelNeeded = 2000

-- Imports

local Set = require("lib.Set")
local dig = require("lib.dig")

-- Static Variables

local badblocks = Set({                                      
	"minecraft:flowing_lava",
	"ThermalFoundation:FluidRedstone",
	"minecraft:water",
	"minecraft:flowing_water",
	"minecraft:redstone_wire",
	"minecraft:powered_repeater",
	"minecraft:dirt",
	"minecraft:grass",
	"minecraft:cobblestone",
	"minecraft:stone",
	"minecraft:redstone_torch",
	"IC2:blockRubSapling",
	"minecraft:sapling"
})

-- Functions

function isValuable(blockName)
	return not badblocks[blockName]
end

function processValuablesForward()
	local success, data = turtle.inspect()
	-- Check block, dig block and move forward
	if success and isValuable(data.name) and dig.forward() then
		processValuables(true)
		dig.back(true)
	end
end

function processValuables(forward)
	-- Process up block
	local successUp, dataUp = turtle.inspectUp()
	if successUp and isValuable(dataUp.name) and dig.up() then
		processValuables(true)
		dig.down(true)
	end
	-- Turn left and process left block
	turtle.turnLeft()
	processValuablesForward()
	turtle.turnRight()
	-- Process forward block
	if forward then
		processValuablesForward()
	end
	-- Turn right and process right block
	turtle.turnRight()
	processValuablesForward()
	turtle.turnLeft()
	-- Process down block
	local successDown, dataDown = turtle.inspectDown()
	if successDown and isValuable(dataDown.name) and dig.down() then
		processValuables(true)
		dig.up(true)
		turtle.select(1)
		turtle.placeDown()
	end
end

function checkRedStone()
	local success, data = turtle.inspectDown()
	return success and data.metadata > 0
end

--Move to tree
function treeMove()
	if turtle.forward() then
		treeMove()
		turtle.back()
	else
		processValuables(true)
	end
end

function startTreeMove(direction)	
	if direction == 0 then
		turtle.turnLeft()
	elseif direction == 1 then
		turtle.turnRight()
	end
	
	treeMove()
	
	if direction == 0 then
		turtle.turnRight()
	elseif direction == 1 then
		turtle.turnLeft()
	end
end

-- Keep moving till a wall or the redstone is found
function travelRight()
	if checkRedStone() then
		startTreeMove(0)
	elseif (turtle.forward()) then
		travelRight()
		turtle.back()
	end
end

function startRight()
	turtle.forward()
	turtle.forward()
	turtle.turnRight()
	travelRight()
	turtle.turnLeft()
	turtle.back()
	turtle.back()
end

function travelLeft()
	if (checkRedStone()) then
		startTreeMove(1)
	end
	if (turtle.forward()) then
		travelLeft()
		turtle.back()
	end
end

function startLeft()
	turtle.forward()
	turtle.forward()
	turtle.turnLeft()
	travelLeft()
	turtle.turnRight()
	turtle.back()
	turtle.back()
end

-- Begin Digging

function main()
	-- Waits for a tree to grow
	while not checkRedStone() do
		sleep(5)
	end

	startRight()
	startLeft()

	for i = 2, 16 do
		local target = turtle.getItemDetail(i)
		if (target) then
			turtle.select(i)
			turtle.drop()
		end
	end
	
	main()
end

main()

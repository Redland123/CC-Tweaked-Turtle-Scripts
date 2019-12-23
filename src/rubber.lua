-- Globals
local minFuel = 2000
local fuelNeeded = 2000

-- Pre-functions
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

local filler = Set({ "IC2:blockRubSapling" })

local badblocks = concat(Set({                                      
	"minecraft:flowing_lava",
	"ThermalFoundation:FluidRedstone",
	"minecraft:water",
	"minecraft:flowing_water",
	"minecraft:redstone_wire",
	"minecraft:powered_repeater",
	"minecraft:dirt",
	"minecraft:grass)",
	"minecraft:cobblestone",
	"minecraft:stone",
	"minecraft:redstone_torch",
}), filler)

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

function processValuablesForward()
	local success, data = turtle.inspect()
	-- Check block, dig block and move forward
	if success and isValuable(data.name) and digForward() then
		processValuables(true)
		digBack(true)
	end
end

function processValuables(forward)
	-- Process up block
	local successUp, dataUp = turtle.inspectUp()
	if successUp and isValuable(dataUp.name) and digUp() then
		processValuables(true)
		digDown(true)
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
	if successDown and isValuable(dataDown.name) and digDown() then
		processValuables(true)
		digUp(true)
	end
end

function selectSapling()
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

function checkRedStone()
	local success, data = turtle.inspectDown()
	if success then
		if data.metadata > 0 then 
			return true
		else 
			return false
		end
	end
end

--Move to tree
function treeMove()
	if (turtle.forward()) then
		treeMove()
		turtle.back()
	else
		processValuables(true)
	end
end

function startTreeMove(direction)
	if (direction == "right") then
		turtle.turnLeft()
	else 
		turtle.turnRight()
	end
	
	treeMove()
	
	if (direction == "left") then
		turtle.turnLeft()
	else 
		turtle.turnRight()
	end
	
end

--Keep moving till a wall or the redstone is found
function travelRight()
	if (checkRedStone()) then
		startTreeMove("right")
		return
	end
	
	if (turtle.forward()) then
		travelRight()
		turtle.back()
	end
end

function startRight()
	turtle.forward()
	turtle.turnRight()
	travelRight()
	turtle.turnLeft()
	turtle.back()
end

function travelLeft()
	if (checkRedStone()) then
		startTreeMove("left")
	end
	
	if (turtle.forward()) then
		travelLeft()
		turtle.back()
	end
end

function startLeft()
	turtle.turnLeft()
	travelLeft()
	turtle.turnRight()
end

-- Begin Digging

function main()
	local redStoneState = checkRedStone()

	--Waits for a tree to grow
	while (redStoneState == false) do
		sleep(5)
		redStoneState = checkRedStone()
	end

	startRight()
end

main()
local chest = require("lib.chest")

local targs = { ... }
local each = tonumber(targs[1]) or 1
local totalQuantity = tonumber(targs[2]) or nil

function nextChest()
    if turtle.turnRight() and turtle.forward() and turtle.forward() and turtle.turnLeft() then
        -- Verify chest in front of turtle
        if chest.detect() then
            return true
        end
        print("No chest found!")
    end
    return false
end

function returnToFirstChest(numOfSupplyChests)
    turtle.turnLeft()
    for i = 1, (numOfSupplyChests * 2) do
        if not turtle.forward() then
            return false
        end
    end
    turtle.turnRight()
    -- Verify chest in front of turtle
    if chest.detect() then
        return true
    end
    print("No chest found!")
    return false
end

function craft()
    -- Assumes turtle is in front of left-most chest
    -- Take 6 insulated copper cable
    if not chest.extract(each, "ic2:cable", 0, {1, 2, 3, 9, 10, 11}, "Out of insulated copper cable!", "No insulated copper cable in first chest!") then
        return false
    end
    -- Move to redstone chest
    if not nextChest() then
        print("Error: Failed to move to redstone chest!")
        return false
    end
    -- Take 2 redstone
    if not chest.extract(each, "minecraft:redstone", nil, {5, 7}, "Out of redstone!", "No redstone in second chest!") then
        return false
    end
    -- Move to refined iron nextChest
    if not nextChest() then
        print("Error: Failed to move to refined iron chest!")
        return false
    end
    -- Take 1 refined iron
    if not chest.extract(each, "ic2:ingot", 7, {6}, "Out of refined iron!", "No refined iron in last chest!") then
        return false
    end
    -- Move to deposit chest
    if not nextChest() then
        print("Error: Failed to move to deposit chest!")
        return false
    end
    -- Craft item
    turtle.select(1)
    if not turtle.craft(each) then
        print("Error: Failed to craft item!")
        return false
    end
    -- Deposit crafted item
    if not turtle.drop(each) then
        print("Error: Failed to deposit crafted item into chest!")
        return false
    end
    -- Return to first chest
    if not returnToFirstChest(3) then
        print("Error: Failed to return to insulated copper chest!")
        return false
    end
    return true
end

-- Check pre-condition
if not chest.detect() then
    print("Error: Place turtle in front of left-most chest facing it.")
    return
end

local itemsCrafted = 0
while (totalQuantity == nil) or (itemsCrafted < totalQuantity) do
    if not craft() then
        return
    end
    itemsCrafted = itemsCrafted + 1
end
print("Successfully crafted " .. itemsCrafted .. " items!")

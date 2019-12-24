local chest = require("lib.chest")

local targs = { ... }
local totalQuantity = tonumber(targs[1]) or nil

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
    local quantity = 1
    -- Assumes turtle is in front of left-most chest
    -- Take 3 copper ingots
    if not chest.extract(quantity, "thermalfoundation:material", 128, {5, 6, 7}, "Out of copper ingots!", "No copper ingots in first chest!") then
        return false
    end
    -- Move to rubber chest
    if not nextChest() then
        print("Error: Failed to move to rubber chest!")
        return false
    end
    -- Take 6 rubber
    if not chest.extract(quantity, "ic2:crafting", 0, {1, 2, 3, 9, 10, 11}, "Out of rubber!", "No rubber in second chest!") then
        return false
    end
    -- Move to deposit chest
    if not nextChest() then
        print("Error: Failed to move to deposit chest!")
        return false
    end
    -- Craft item
    turtle.select(1)
    if not turtle.craft(quantity) then
        print("Error: Failed to craft item!")
        return false
    end
    -- Deposit crafted item
    if not turtle.drop(quantity) then
        print("Error: Failed to deposit crafted item into chest!")
        return false
    end
    -- Return to first chest
    if not returnToFirstChest(2) then
        print("Error: Failed to return to copper chest!")
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

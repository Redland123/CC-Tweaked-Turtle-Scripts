local targs = { ... }
local totalQuantity = tonumber(targs[1]) or nil

function extractItem(quantity, itemID, subID, slots, outOfMessage, incorrectMessage)
    for _, slot in ipairs(slots) do
        -- Suck item from chest into slot
        turtle.select(slot)
        local suckResult = turtle.suck(quantity)
        if not suckResult then
            print("Error: " .. outOfMessage)
            return false
        end
        -- Verify item in slot
        local itemData = turtle.getItemDetail()
        if not itemData then
            print("Error?: " .. outOfMessage)
            return false
        end
        if (itemData.name ~= itemID) or ((subID ~= nil) and (itemData.damage ~= subID)) then
            print("Error: " .. incorrectMessage)
            return false
        end
        if itemData.count ~= quantity then
            print("Error: Incorrect number of items in slot " .. slot)
            return false
        end
    end
    return true
end

function checkChest()
    local success, data = turtle.inspect()
    return success and data.name == "minecraft:chest"
end

function nextChest()
    if turtle.turnRight() and turtle.forward() and turtle.forward() and turtle.turnLeft() then
        -- Verify chest in front of turtle
        if checkChest() then
            return true
        end
        print("No chest found!")
    end
    return false
end

function returnToFirstChest()
    turtle.turnLeft()
    for i = 1, 6 do
        if not turtle.forward() then
            return false
        end
    end
    turtle.turnRight()
    -- Verify chest in front of turtle
    if checkChest() then
        return true
    end
    print("No chest found!")
    return false
end

function craft()
    local quantity = 1
    -- Assumes turtle is in front of left-most chest
    -- Take 1 insulated copper cable
    if not extractItem(quantity, "ic2:cable", 0, {2}, "Out of insulated copper cable!", "No insulated copper cable in first chest!") then
        return false
    end
    -- Move to redstone chest
    if not nextChest() then
        print("Error: Failed to move to redstone chest!")
        return false
    end
    -- Take 2 redstone
    if not extractItem(quantity, "minecraft:redstone", nil, {6, 10}, "Out of redstone!", "No redstone in second chest!") then
        return false
    end
    -- Move to tin ingot nextChest
    if not nextChest() then
        print("Error: Failed to move to tin ingot chest!")
        return false
    end
    -- Take 4 tin ingots
    if not extractItem(quantity, "thermalfoundation:material", 129, {5, 7, 9, 11}, "Out of tin ingots!", "No tin ingots in last chest!") then
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
    if not returnToFirstChest() then
        print("Error: Failed to return to insulated copper chest!")
        return false
    end
    return true
end

-- Check pre-condition
if not checkChest() then
    print("Error: Place turtle in front of left-most chest facing it.")
    return
end

craft()
--while craft() do end

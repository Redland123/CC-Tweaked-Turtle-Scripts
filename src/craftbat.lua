function extractItem(quantity, itemID, slots, outOfMessage, incorrectMessage)

end

function nextChest()

end

function returnToFirstChest()

end

function craft()
    -- Assumes turtle is in front of left-most chest
    -- Take 1 insulated copper cable
    if not extractItem(1, "", {2}, "Out of insulated copper cable!", "No insulated copper cable in first chest!") then
        return false
    end
    -- Move to redstone chest
    if not nextChest() then
        print("Error: Failed to move to redstone chest!")
        return false
    end
    -- Take 2 redstone
    if not extractItem(1, "", {6, 10}, "Out of redstone!", "No redstone in second chest!") then
        return false
    end
    -- Move to tin ingot nextChest
    if not nextChest() then
        print("Error: Failed to move to tin ingot chest!")
        return false
    end
    -- Take 4 tin ingots
    if not extractItem(1, "", {}, "Out of tin ingots!", "No tin ingots in last chest!") then
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
local success, data = turtle.inspect()
if (not success) or (data.name ~= "minecraft:chest") then
    print("Error: Place turtle in front of left-most chest facing it.")
    return
end

while craft() do end

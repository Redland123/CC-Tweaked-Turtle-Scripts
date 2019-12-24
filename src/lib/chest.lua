local Set = require("lib.Set")

local api = {}

local chests = Set({
    "minecraft:chest",
    "enderstorage:ender_storage"
})

-- Gets a set of string IDs for all known chests
function api.ids()
    return Set(chests)
end

-- Detects whether there is a chest (or inventory) in front of the turtle.
function api.detect()
    local success, data = turtle.inspect()
    return success and chests[data.name]
end

function api.extract(quantity, itemID, subID, slots, outOfMessage, incorrectMessage)
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

return api

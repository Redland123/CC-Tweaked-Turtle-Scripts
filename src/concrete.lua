local inventory = require("lib.inventory")
local blockID = "minecraft:concrete_powder"

while inventory.selectID(blockID) and turtle.place() do
    local success, data = turtle.inspect()
    if success and data.name ~= blockID then
        turtle.dig()
    end
end
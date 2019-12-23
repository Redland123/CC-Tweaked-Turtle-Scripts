local targs = { ... }
local slot = tonumber(targs[1]) or 1

local data = turtle.getItemDetail(slot)
if data then
    print("Item name: ", data.name)
    print("Item damage value: ", data.damage)
    print("Item count: ", data.count)
else
    print("No item in slot " .. slot)
end

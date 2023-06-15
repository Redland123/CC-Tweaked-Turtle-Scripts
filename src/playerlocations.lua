local pf = peripheral.wrap("bottom")
local playerList
local largestNameLen = 0

while 1 do
    local dataTable = {}

    playerList = pf.getOnlinePlayers()

    for i, v in ipairs(playerList) do
        p = pf.getPlayerPos(v)
        table.insert(dataTable, {name = v, x = p["x"], y = p["y"], z = p["z"]})

        if largestNameLen < string.len(v) then
            largestNameLen = string.len(v)
        end
    end

    term.clear()

    for i, v in ipairs(dataTable) do 
        -- print(v["name"] .. ":", v["x"], v["y"], v["z"])
        term.setCursorPos(1,i)
        print(v["name"] .. ":")
        term.setCursorPos(largestNameLen + 3, i)
        print(v["x"])  
        term.setCursorPos(largestNameLen + 9, i)
        print(v["y"])
        term.setCursorPos(largestNameLen + 13, i)
        print(v["z"])

    end

    sleep(1)
end
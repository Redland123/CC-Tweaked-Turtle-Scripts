local playerFinder = peripheral.wrap("bottom")
local pPos = 0

local geoScanner = peripheral.wrap("right")
rednet.open("top")

local computerLocation = {x = -252, y = 21, z = -827}

local blockId
local scanData
local player = "Redland123"

local vector = {length = 0, x = 0, y = 0, z = 0}

local blockList = {}

rednet.broadcast("Enter block Id: ")
-- blockId = read()
blockId = "minecraft:diamond_block"

rednet.broadcast("Enter scan radius: ")
scanData = geoScanner.scan(tonumber(read()))

-- rednet.broadcast()

for i, v in ipairs(scanData) do
    if (v["name"]) == blockId then
        table.insert(blockList, v)
        -- rednet.broadcast(v["name"], "added")
    end
end

for i, v in ipairs(blockList) do
    rednet.broadcast(i, v["name"], v["x"], v["y"], v["z"])
end

read()

while 1 do
    pPos = playerFinder.getPlayerPos(player)

    for i, v in ipairs(blockList) do    
        vector["x"] = pPos["x"] - (v["x"] + computerLocation["x"])
        vector["y"] = pPos["y"] - (v["y"] + computerLocation["y"])
        vector["z"] = pPos["z"] - (v["z"] + computerLocation["z"])
        
        rednet.broadcast(blockList[i]["name"])
        rednet.broadcast("Vector: ", tostring(vector["x"]), tostring(vector["y"]), tostring(vector["z"]))
        rednet.broadcast("Player: ", tostring(pPos["x"]), tostring(pPos["y"]), tostring(pPos["z"]))
        rednet.broadcast("Block Pos: ", tostring(v["x"] + computerLocation["x"]), tostring(v["y"] + computerLocation["y"]), v["z"] + computerLocation["z"])

        local tmpValue = ((vector["x"] ^ 2) - (vector["y"] ^ 2) - (vector["z"] ^ 2))

        if tmpValue < 0 then
            tmpValue = tmpValue * -1
        end
 
        local newVectorLength = math.sqrt(tmpValue)

        rednet.broadcast("New vector length:", newVectorLength)

        if i == 1 then
            vector["length"] = newVectorLength
        elseif newVectorLength < vector["length"] then
            vector["length"] = newVectorLength
            rednet.broadcast("Nearest changed")
        end

        rednet.broadcast()
    end

    rednet.broadcast("Distance to nearest:", vector["length"])      
    rednet.broadcast()

    sleep(1)
end
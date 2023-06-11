local playerFinder = peripheral.wrap("bottom")
local pPos = 0

local geoScanner = peripheral.wrap("right")
rednet.open("top")

local computerLocation = {x = -252, y = 21, z = -827}

local blockId
local scanData
local player

local debug = false

local vector = {length = 0, x = 0, y = 0, z = 0}

local blockList = {}

print("Enter name: ")
player = read()
print()

print("Enter block Id: ")
blockId = read()
print()

print("Enter scan radius: ")
scanData, error = geoScanner.scan(tonumber(read()))
print()

print("Debug enabled: ")
debug = read()
print()

if scanData == nil then
    print(error)
    return
end

term.clear()

for i, v in ipairs(scanData) do
    if (v["name"]) == blockId then
        table.insert(blockList, v)
    end
end

for i, v in ipairs(blockList) do
    rednet.broadcast(tostring(i) .. tostring(v["name"]) .. tostring(v["x"]) .. tostring(v["y"]) .. tostring(v["z"]))
end

while 1 do
    pPos = playerFinder.getPlayerPos(player)

    for i, v in ipairs(blockList) do    
        vector["x"] = pPos["x"] - (v["x"] + computerLocation["x"])
        vector["y"] = pPos["y"] - (v["y"] + computerLocation["y"])
        vector["z"] = pPos["z"] - (v["z"] + computerLocation["z"])
        
        if (debug == "true") then
            rednet.broadcast(blockList[i]["name"])
            rednet.broadcast("Vector: " .. tostring(vector["x"]) .. tostring(vector["y"]) .. tostring(vector["z"]))
            rednet.broadcast("Player: " .. tostring(pPos["x"]) .. tostring(pPos["y"]) .. tostring(pPos["z"]))
            rednet.broadcast("Block Pos: " .. tostring(v["x"] + computerLocation["x"]) .. tostring(v["y"] + computerLocation["y"]) .. tostring(v["z"] + computerLocation["z"]))
        end

        local tmpValue = ((vector["x"] ^ 2) - (vector["y"] ^ 2) - (vector["z"] ^ 2))

        if tmpValue < 0 then
            tmpValue = tmpValue * -1
        end
 
        local newVectorLength = math.sqrt(tmpValue)

        if (debug == "true") then
            rednet.broadcast("New vector length:" .. tostring(newVectorLength))
        end

        if i == 1 then
            vector["length"] = newVectorLength
        elseif newVectorLength < vector["length"] then
            vector["length"] = newVectorLength

            if (debug == "true") then 
                rednet.broadcast("Nearest changed")
            end
        end

        rednet.broadcast("")
    end

    rednet.broadcast("Distance to nearest:" .. tostring(vector["length"])) 
    rednet.broadcast("")

    print("Distance to nearest:", vector["length"])
    print()

    sleep(1)
end
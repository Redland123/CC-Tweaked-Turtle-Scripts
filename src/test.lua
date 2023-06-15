local geoScanner = peripheral.wrap("back")

local blockId
local scanData

local blockList = {}

local vectorLength = 0

-- print("Enter block id: ")
-- blockId = read()
-- print()

blockId = "minecraft:diamond_block"

term.clear()

for i, v in ipairs(blockList) do
    print(i, v["name"], v["x"], v["y"], v["z"])
end

while 1 do
    scanData, errorMessage = geoScanner.scan(16)

    if errorMessage ~= nil then
        print(errorMessage)
        return
    end

    for i, v in ipairs(scanData) do
        if (v["name"]) == blockId then
            table.insert(blockList, v)
        end
    end

    for i, v in ipairs(blockList) do    
        print("Vector: ", v["x"], v["y"], v["z"])

        local tmpValue = ((v["x"] ^ 2) - (v["y"] ^ 2) - (v["z"] ^ 2))
   
        print("TmpValue: ", tmpValue)        

        if tmpValue < 0 then
            tmpValue = tmpValue * -1
        end

        tmpValue = math.sqrt(tmpValue)

        if i == 1 then
            vectorLength = tmpValue
        elseif tmpValue < vectorLength then
            vectorLength = tmpValue
            print("Nearest changed")
        end

        print()
    end

    print("Distance to nearest:", vector["length"])
    term.
    sleep(5)
end


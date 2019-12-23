local success, data = turtle.inspect()
if success then
    print("Block name: ", data.name)
    print("Block metadata: ", data.metadata)
    print("Block state:")
    for k, v in pairs(data.state) do
        print(" - " .. k .. ": " .. v)
    end
else
    print("No block in front of turtle: " .. data)
end

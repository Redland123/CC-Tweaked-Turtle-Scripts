rednet.open("back")


while 1 do
    local sender, message, protocol = rednet.receive()
    print(message)
end
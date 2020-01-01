function main()
    if turtle.getSelectedSlot ~= 1 then
        turtle.select(1)
    end

    while 1 == 1 do
        turtle.place()
        local success, data = turtle.inspect()
        if success and data == "minecraft:concrete" then
            turtle.dig()
        end
    end
end

main()
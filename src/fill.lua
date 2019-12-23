--Gets user input and saves it to a variable that makes sense
local targs = { ... }
local diameter = targs[1]

--"Constants"
local invSize = 16

--funcitons
--Finds and selects the first block in the inventory
function findBlock()
    for i = 1, invSize do
        if turtle.getItemDetail(i) then
            if turtle.getSelectedSlot ~= i then
                turtle.select(i)
                return true
            end
        end
    end
    return false
end

function placeLine()
    for i = 1, diameter do
        --Find the first block in the inventory
        if findBlock() ~= true then
            print("Error, no blocks found. ")

            --loops findblock till a block is provided
            while findBlock ~= true do
                sleep(1)
            end
        end

        --Attemps to place the currently selected block under the turtle
        turtle.placeDown()

        turtle.forward()
    end
end

--Moves the turtle into the correct location for creating a new line
function moveNext(side)
    if side == 0 then
        turtle.turnRight()
        turtle.forward()
        turtle.turnRight()
    else 
        turtle.turnLeft()
        turtle.forward()
        turtle.turnLeft()
    end
end

function main()
    local side = 0

    --Moves the bot forward to start
    turtle.forward()

        for i = 0, diameter do
            placeLine()

            if side == 0 then side = 1
            else side = 0 end

            moveNext(side)
        end             
end

--Runs the main function
main()
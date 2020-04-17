-- Gets user input and saves it to a variable that makes sense
local targs = { ... }
local diameter = targs[1]

-- Constants
local invSize = 16

-- Finds and selects the first block in the inventory
function findBlock()
    for i = 1, invSize do
        if turtle.getItemDetail(i) then
            if turtle.getSelectedSlot() ~= i then
                turtle.select(i)
            end
            return true
        end
    end
    return false
end

function placeLine()
    for i = 1, diameter do
        -- Find the first block in the inventory
        if not findBlock() then
            print("Error: No blocks found.")

            -- Waits until block is placed in inventory
            while not findBlock() do
                sleep(1)
            end
        end

        -- Attemps to place the currently selected block under the turtle
        turtle.forward()
        turtle.placeDown()
    end
end

-- Moves the turtle into the correct location for creating a new line
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

    for i = 1, diameter do
        placeLine()

        if side == 0 then
            side = 1
        else 
            side = 0
        end

        moveNext(side)
    end
end

--Runs the main function
main()

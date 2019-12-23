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
            end
        end
    end
end

function placeLine()
    for i = 1, diameter do
        --Find the first block in the inventory
        findBlock()
        --Attemps to place the currently selected block under the turtle
        turtle.placeDown()

        turtle.forward()
    end
end

--Moves the turtle into the correct location for creating a new line
function moveNext()
        turtle.turnRight()
        turtle.forward()
        turtle.turnRight()
end

function main()
        for i = 1, diameter do
            placeLine()
            moveNext()
        end             
end

--Runs the main function
main()
local api = {}

-- Gets the number of positional arguments.
function api.count(targs)
    local n = 0
    for i = 1, 100 do
        if targs[i] == nil then
            break
        end
        n = n + 1
    end
    return n
end

return api

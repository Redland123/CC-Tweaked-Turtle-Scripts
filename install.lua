local scripts = {
    "mine",
    "rubber"
}

local libs = {
    "init",
    "dig",
    "inventory",
    "Location",
    "Set",
    "movement",
    "utils"
}

local args = { ... }
local download = args[1] == "download"
local urlPrefix = "https://raw.githubusercontent.com/BTOdell/computercraft-turtle-scripts/master/"

function downloadLua(url, path)
    if not path then
        path = url
    end
    local handle = http.get(urlPrefix .. url .. ".lua")
    if not handle then
        print("Unable to download " .. path)
        return false
    end
    if handle.getResponseCode() ~= 200 then
        print("Error when downloading " .. path .. ": " .. handle.getResponseCode())
        handle.close()
        return false
    end
    local content = handle.readAll()
    handle.close()
    fs.delete(path)
    local file = fs.open(path, "w")
    if not file then
        print("Error creating file " .. path)
        return false
    end
    file.write(content)
    file.close()
    return true
end

if not download then
    -- Download latest copy of the install script first
    if downloadLua("install") then
        print("Self-updated installer.")
        -- Restart install script with argument
        shell.run("install", "download")
    end
else
    -- Clean existing libs
    fs.delete("lib")
    -- Download all scripts and libs from repo
    for _, script in ipairs(scripts) do
        downloadLua("src/" .. script, script)
    end
    for _, lib in ipairs(libs) do
        local libPath = "lib/" .. lib
        downloadLua("src/" .. libPath, libPath)
    end
    print("Successfully installed scripts!")
end

local scripts = {
    "mine",
    "rubber"
}

local libs = {
    "Location",
    "Set",
    "movement",
    "utils"
}

local args = { ... }
local download = args[1] == "download"
local urlPrefix = "https://raw.githubusercontent.com/BTOdell/computercraft-turtle-scripts/master/"

function downloadLua(path)
    shell.run("delete", path)
    shell.run("delete", path .. ".lua")
    shell.run("wget", urlPrefix .. path .. ".lua", path .. ".lua")
end

if not download then
    -- Download latest copy of the install script first
    downloadLua("install")
    -- Restart install script with argument
    shell.run("install", "download")
else
    -- Download all scripts and libs from repo
    for _, script in ipairs(scripts) do
        downloadLua(script)
    end
    for _, lib in ipairs(libs) do
        downloadLua("lib/" .. lib)
    end
end

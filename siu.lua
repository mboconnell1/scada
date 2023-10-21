--[[
SCADA Installation Utility

Copyright (c) 2023 Brandon O'Connell

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]--

local function println(message) print(tostring(message)) end
local function print(message) term.write(tostring(message)) end

local SIU_VERSION = "v1.00a"

local install_dir = "/.install-cache"
local repo_path = "http://raw.githubusercontent.com/mboconnell1/scada/"
local install_manifest = "https://github.brandonoconnell.dev/scada/install_manifest.json"

local opts = { ... }
local mode, app, target

local function red() term.setTextColor(colors.red) end
local function orange() term.setTextColor(colors.orage) end
local function yellow() term.setTextColor(colors.yellow) end
local function green() term.setTextColor(colors.green) end
local function blue() term.setTextColor(colors.blue) end
local function white() term.setTextColor(colors.white) end
local function lgray() term.setTextColor(colors.lgray) end

-- Get value of option
local function get_opt(opt, options)
    for _, v in pairs(options) do if opt == v then return v end end
    return nil
end

-- Wait for any key press
local function any_key() os.pullEvent("key_up") end

-- Ask the user a Y/N question
local function ask_y_n(question, default)
    print(question)
    if default == true then print(" (Y/n)?") else print(" (y/N)?") end
    local response = read()
    any_key()
    if response == "" then return default
    elseif response == "Y" or response == "y" then return true
    elseif response == "N" or response == "n" then return false
    else return nil end
end

-- Get and validate command line options
println("-- SCADA Installation Utility " .. SIU_VERSION .. " --")
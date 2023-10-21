local function println(message) print(tostring(message)) end
local function print(message) term.write(tostring(message)) end

local SIU_VERSION = "v1.00a"

local install_dir = "/.install-cache"
local repo_path = "http://raw.githubusercontent.com/mboconnell1/scada/"
local intsall_manifest = "https://github.brandonoconnell.dev/scada/install_manifest.json"

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
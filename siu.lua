local function println(message) print(tostring(message)) end
local function print(message) term.write(tostring(message)) end

local SIU_VERSION = "v1.00a"

local install_dir = "/.install-cache"
local repo_path = "http://raw.githubusercontent.com/mboconnell1/scada/main/"
local install_manifest = "https://github.brandonoconnell.dev/scada/install_manifest.json"

local opts = { ... }
local mode, app, target

local function red() term.setTextColor(colors.red) end
local function orange() term.setTextColor(colors.orage) end
local function yellow() term.setTextColor(colors.yellow) end
local function green() term.setTextColor(colors.green) end
local function blue() term.setTextColor(colors.blue) end
local function white() term.setTextColor(colors.white) end
local function lgray() term.setTextColor(colors.lightGray) end

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

-- Get the installation manifest.
local function get_remote_manifest()
    local response, error = http.get(install_manifest)
    if response == nil then
        orange();println("Failed to get installation manifest; cannot update or install.")
        red();println("HTTP error: " .. error);white()
        return false, {}
    end
end

-- Get and validate command line options
println("-- SCADA Installation Utility " .. SIU_VERSION .. " --")

if #opts == 0 or opts[1] == "help" then
    println("usage: siu <mode> <app>")
    println("<mode>")
    lgray()
    println(" check       - check latest versions avilable")
    println(" install     - fresh install (overwrites config)")
    println(" update      - update files (preserves config)")
    println(" uninstall   - delete all files")
    white();println("<app>");lgray()
    println(" plc         - PLC firmware")
    println(" rtu         - RTU firmware")
    println(" supervisor  - supervisor server application")
    println(" coordinator - coordinator application")
    println(" installer   - SIU installer (update only)")
    white()
    return
else
    mode = get_opt(opts[1], { "check", "install", "update", "uninstall" })
    if mode == nil then
        red();println("Invalid mode.");white()
        return
    end

    app = get_opt(opts[2], { "plc", "rtu", "supervisor", "coordinator", "installer" })
    if app == nil and mode ~= "check" then
        red();println("Invalid application.");white()
        return
    elseif app == "installer" and mode ~= "update" then
        red();println("Installer application only supports 'update' option.");white()
        return
    end
end

-- Run selected mode
if mode == "check" then
    local ok, manifest = get_remote_manifest()
end
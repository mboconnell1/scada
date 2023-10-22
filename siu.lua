local function println(message) print(tostring(message)) end
local function print(message) term.write(tostring(message)) end

local SIU_VERSION = "v1.00a"

local install_dir = "/.install-cache"
local repo_path = "http://raw.githubusercontent.com/mboconnell1/scada/main/"
local install_manifest = repo_path .. "install_manifest.json"

local opts = { ... }
local mode, app, target

local function red() term.setTextColor(colors.red) end
local function orange() term.setTextColor(colors.orage) end
local function yellow() term.setTextColor(colors.yellow) end
local function green() term.setTextColor(colors.green) end
local function cyan() term.setTextColor(colors.cyan) end
local function blue() term.setTextColor(colors.blue) end
local function purple() term.setTextColor(colors.purple) end
local function white() term.setTextColor(colors.white) end
local function lgray() term.setTextColor(colors.lightGray) end

-- Get value of command line options.
local function get_opt(opt, options)
    for _, v in pairs(options) do if opt == v then return v end end
    return nil
end

-- Wait for any key press.
local function any_key() os.pullEvent("key_up") end

local function ask(question, default)
    print(question)
    if default == true then print(" (Y/n)? ") else print(" (y/N)? ") end
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

    local ok, manifest = pcall(function () return textutils.unserialiseJSON(response.readAll()) end)
    if not ok then red();println("Error parsing remote installation manifest.");white() end

    return ok, manifest
end

-- Read the local installation manifest file.
local function read_local_manifest()
    local ok = false
    local manifest = {}
    local manifest_file = fs.open("install_manifest.json", "r")
    if manifest_file ~= nil then
        ok, manifest = pcall(function () return textutils.unserialiseJSON(manifest_file.readAll()) end)
        manifest_file.close()
    end
    return ok, manifest
end

local function package_message(message, package) white();print(message .. " ");blue();println(package);white() end

local function show_package_change(name, v)
    if v.v_local ~= nil then
        if v.v_local ~= v.v_remote then
            purple();print(string.format("%-14s", "[" .. name .. "]"));lgray();print("updating ");white();print(v.v_local);white();print(" \xbb ");cyan();println(v.v_remote);white()
        elseif mode == "install" then
            purple();print(string.format("%-14s", "[" .. name .. "]"));lgray();print("reinstalling ");cyan();println(v.v_remote);white()
        end
    else purple();print(string.format("%-14s", "[" .. name .. "]"));lgray();print("fresh installing ");cyan();println(v.v_remote);white() end
    return v.v_local ~= v.v_remote
end

-- Parse command line options.
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

-- Run selected mode.
if mode == "check" then
    -- Get remote and local manifest.
    local remote_ok, remote_manifest = get_remote_manifest()
    if not remote_ok then return end

    local local_ok, local_manifest = read_local_manifest()
    if not local_ok then
        yellow();println("Failed to load local installation information.");white()
        local_manifest = { versions = { installer = SIU_VERSION } }
    else
        local_manifest.versions.installer = SIU_VERSION
    end

    -- List versions.
    for key,value in pairs(remote_manifest.versions) do
        purple();print(string.format("%-14s", "[" .. key .. "]"))
        if key == "installer" or (local_ok and (local_manifest.versions[key] ~= nil)) then
            blue();print(local_manifest.versions[key])
            if value ~= local_manifest.versions[key] then
                white();print(" (");cyan();print(value);white();println(" available)")
            else green();println(" (up to date)") end
        else
            lgray();print("not installed");white();print(" (latest ");cyan();print(value);white();println(")")
        end
    end

    if remote_manifest.versions.installer ~= local_manifest.versions.installer then
        yellow();println("\nA newer version of the installer is available; updating is recommended (use 'siu update installer').");white()
    end
elseif mode == "install" or mode == "update" then
    local update_installer = app == "installer"
    local remote_ok, remote_manifest = get_remote_manifest()
    if not remote_ok then return end

    local ver = {
        app = { v_local = nil, v_remote = nil, changed = false },
        boot = { v_local = nil, v_remote = nil, changed = false },
        comms = { v_local = nil, v_remote = nil, changed = false },
        common = { v_local = nil, v_remote = nil, changed = false },
        graphics = { v_local = nil, v_remote = nil, changed = false },
        lockbox = { v_local = nil, v_remote = nil, changed = false }
    }

    -- Attempt to find local versions.
    local local_ok, local_manifest = read_local_manifest()
    if not local_ok then
        if mode == "update" then
            red();println("Failed to load local installation information; cannot update.");white()
            return
        end
    elseif not update_installer then
        ver.app.v_local = local_manifest.versions[app]
        ver.boot.v_local = local_manifest.versions.bootloader
        ver.comms.v_local = local_manifest.versions.comms
        ver.common.v_local = local_manifest.versions.common
        ver.graphics.v_local = local_manifest.versions.graphics
        ver.lockbox.v_local = local_manifest.versions.lockbox

        if local_manifest.versions[app] == nil then 
            red();println("Another application has already been installed. Please uninstall before installing a new application.");white()
            return
        end
    end
    
    -- Update installation utility.
    if remote_manifest.versions.installer ~= SIU_VERSION then
        if not update_installer then yellow();println("\nA newer version of the installer is available; updating is recommended (use 'siu update installer').");white() end
        if update_installer or ask("Would you like to update the installer now?") then
            lgray();println("GET siu.lua")
            local dl, err = http.get(repo_path .. "siu.lua")
            if dl == nil then
                orange();println("Failed to download latest installer.")
                red();println("HTTP error: " .. err);white()
            else
                local handle = fs.open(debug.getinfo(1, "S").source:sub(2), "w")
                handle.write(dl.readAll())
                handle.close()
                green();println("Installer updated successfully.");white()
            end
            return
        end
    elseif update_installer then
        green();println("Installer already up-to-date.");white()
        return
    end

    ver.app.v_remote = remote_manifest.versions[app]
    ver.boot.v_remote = remote_manifest.versions.bootloader
    ver.comms.v_remote = remote_manifest.versions.comms
    ver.common.v_remote = remote_manifest.versions.common
    ver.graphics.v_remote = remote_manifest.versions.graphics
    ver.lockbox.v_remote = remote_manifest.versions.lockbox

    green()
    if mode == "install" then
        println("Installing " .. app .. " files...")
    elseif mode == "update" then
        println("Updating " .. app .. " files (preserving config.lua)...")
    end
    white()

    ver.boot.changed = show_package_change("bootldr", ver.boot)
    ver.common.changed = show_package_change("common", ver.common)
    ver.comms.changed = show_package_change("comms", ver.comms)
    if ver.comms.changed and ver.comms.v_local ~= nil then
        print("[comms] ");yellow();println("other devices on the network will require an update.");white()
    end
    ver.app.changed = show_package_change(app, ver.app)
    ver.graphics.changed = show_package_change("graphics", ver.graphics)
    ver.lockbox.changed = show_package_change("lockbox", ver.lockbox)

    if not ask("Continue", false) then return end

    -- TODO: Install/Update
end
local util = require("common.util")

local BOOTLOADER_VERSION = "0.0.1"

local println = util.println
local println_ts = util.println_ts

println("SCADA Bootloader v" .. BOOTLOADER_VERSION)

local exit_code

println("BOOT> Searching for applications...")

if fs.exists("plc/startup.lua") then
    println("BOOT> Found PLC application: executing startup.lua")
    exit_code = shell.execute("plc/startup")
elseif fs.exists("rtu/startup.lua") then
    println("BOOT> Found RTU application: executing startup.lua")
    exit_code = shell.execute("rtu/startup")
elseif fs.exists("supervisor/startup.lua") then
    println("BOOT> Found supervisor application: executing startup.lua")
    exit_code = shell.execute("supervisor/startup")
elseif fs.exists("coordinator/startup.lua") then
    println("BOOT> Found coordinator application: executing startup.lua")
    exit_code = shell.execute("coordinator/startup")
else
    println("BOOT> No application startup found. Exiting...")
    return false
end
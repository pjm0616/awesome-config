local gears = require("gears")
local awful = require("awful")
local naughty = require("naughty")

local myutils = {}


-- Returns the system's hostname.
local function gethostname()
    local f = io.popen("/bin/hostname", "r")
    local s = f:read()
    local ret = f:close()
    if ret ~= true then
        return ""
    end
    s = s:gsub("[ \r\n]", "")
    return s
end
local g_hostname = gethostname()
myutils.hostname = g_hostname

-- Sends a notification that quickly disappears.
local function errnotify(msg)
    naughty.notify({
        timeout = 1,
        title = "ERROR",
        text = msg,
    })
end

-- Reads an integer from a file.
-- Returns nil on failure.
local function readint(path)
        local f = io.open(path, "r")
        if f == nil then
            errnotify("Failed to open " .. path .. " for read")
            return nil
        end
        local val = 0 + f:read()
        f:close()
        return val
end

-- Writes an interger to a file.
local function writeint(path, val)
        local f = io.open(path, "w")
        if f == nil then
            errnotify("Failed to open " .. path .. " for write")
            return false
        end
        f:write(string.format("%d", val))
        f:close()
        return true
end


myutils.myglobalkeys = {}

if g_hostname == "pjm0616-laptop3" then
    function myutils.set_brightness(change)
        local prefix = "/sys/class/backlight/intel_backlight/"
        local current = readint(prefix .. "brightness")
        if current == nil then return end
        local max = readint(prefix .. "max_brightness")
        if max == nil then return end

        local curr_ratio = current / max
        local new_ratio = math.max(0.0, math.min(1.0, curr_ratio + change))
        local new_val = math.ceil(new_ratio * max)

        local ret = writeint(prefix .. "brightness", new_val)
        if not ret then return end

        naughty.notify({
            timeout = 1,
            title = "Screen Brightness",
            text = string.format("%.00f%%", new_ratio * 100)
        })
    end

    function myutils.set_kbd_brightness(change)
        local prefix = "/sys/devices/platform/applesmc.768/leds/smc::kbd_backlight/"
        local current = readint(prefix .. "brightness")
        if current == nil then return end
        local max = readint(prefix .. "max_brightness")
        if max == nil then return end

        local curr_ratio = current / max
        local new_ratio = math.max(0.0, math.min(1.0, curr_ratio + change))
        local new_val = math.floor(new_ratio * max)

        local ret = writeint(prefix .. "brightness", new_val)
        if not ret then return end

        naughty.notify({
            timeout = 1,
            title = "Keyboard Brightness",
            text = string.format("%.00f%%", new_ratio * 100)
        })
    end

    myutils.myglobalkeys = gears.table.join(myutils.myglobalkeys,
        --[[
        awful.key({}, "XF86AudioRaiseVolume",
            function()
            end),
        awful.key({}, "XF86AudioLowerVolume",
            function()
            end),
        awful.key({}, "XF86AudioMute",
            function()
            end),
        --]]
        awful.key({}, "XF86MonBrightnessUp",
            function()
                myutils.set_brightness(0.05)
            end),
        awful.key({}, "XF86MonBrightnessDown",
            function()
                myutils.set_brightness(-0.05)
            end),
        awful.key({}, "XF86KbdBrightnessUp",
            function()
                myutils.set_kbd_brightness(0.1)
            end),
        awful.key({}, "XF86KbdBrightnessDown",
            function()
                myutils.set_kbd_brightness(-0.1)
            end),
        {}
    )
else
    function myutils.set_brightness(change)
        naughty.notify({
            timeout = 1,
            title = "Screen Brightness",
            text = "Not supported on this device: " .. g_hostname
        })
    end

    function myutils.set_kbd_brightness(change)
        naughty.notify({
            timeout = 1,
            title = "Keyboard Brightness",
            text = "Not supported on this device: " .. g_hostname
        })
    end
end

return myutils
-- vim: et ts=4 sts=4 sw=4

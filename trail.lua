local ffi = require "ffi"
local vector = require "vector" -- The holy vector library

local master_switch = ui.new_checkbox("VISUALS", "Effects", "Enable trail")

local menu = {
    rainbow = ui.new_checkbox("VISUALS", "Effects", "Rainbow trail"),
    colour = ui.new_color_picker("VISUALS", "Effects", "Enable trail", 71, 182, 255, 255)
}

local signature_GlowObjectManager = client.find_signature("client.dll", "\xA1\xCC\xCC\xCC\xCC\xA8\x01\x75\x4B") or error("client.dll!::GlowObjectManager couldn't be found. Signature is outdated.")
local signature_AddGloxBox = client.find_signature("client.dll", "\x55\x8B\xEC\x53\x56\x8D") or error("client.dll!::AddGlowBox couldn't be found. Signature is outdated.")

local native_GlowObjectManager = ffi.cast("void*(__cdecl*)()", signature_GlowObjectManager)
local native_AddGlowBox = ffi.cast("int(__thiscall*)(void*, Vector, Vector, Vector, Vector, unsigned char[4], float)", signature_AddGloxBox) -- @ void* GlowObjectManager, Vector BoxPosition, Vector Direction, Vector Mins, Vector Maxs, unsigned char[4] Colour, float Duration

local paint = function(ctx)
    local localplayer = entity.get_local_player()
    if not localplayer or not entity.is_alive(localplayer) then return end
    
    local colour = ffi.cast("unsigned char**", ffi.new("unsigned char[4]", ui.get(menu.colour)))[0]

    if ui.get(menu.rainbow) then
        local realtime = globals.realtime() * 0.2 * 3
        local val = realtime % 3
        
        local r, g, b = math.abs(math.sin(val + 4))*255, math.abs(math.sin(val + 2))*255, math.abs(math.sin(val))*255

        colour = ffi.cast("unsigned char**", ffi.new("unsigned char[4]", { r, g, b, 255}))[0]
    end

    local origin = vector(entity.get_origin(localplayer))
    local velocity = vector(entity.get_prop(localplayer, "m_vecVelocity"))

    local vec_mins = vector(entity.get_prop(localplayer, "m_vecMins"))

    if velocity:length2d() > 2 then
        native_AddGlowBox(native_GlowObjectManager(), origin, vector(client.camera_angles()), vec_mins * 0.5, vec_mins * 0.5, colour, 1)
    end
end

local ui_callback = function(self)
    local enabled = ui.get(self)
    local updatecallback = enabled and client.set_event_callback or client.unset_event_callback

    updatecallback("paint", paint)
end

ui.set_callback(master_switch, ui_callback)
ui_callback(master_switch)

local ffi = require "ffi"
local vector = require "vector"

local signature_GlowObjectManager = client.find_signature("client.dll", "\xA1\xCC\xCC\xCC\xCC\xA8\x01\x75\x4B") or error("client.dll!::GlowObjectManager couldn't be found. Signature is outdated.")
local signature_AddGloxBox = client.find_signature("client.dll", "\x55\x8B\xEC\x53\x56\x8D") or error("client.dll!::AddGlowBox couldn't be found. Signature is outdated.")

local native_GlowObjectManager = ffi.cast("void*(__cdecl*)()", signature_GlowObjectManager)
local native_AddGlowBox = ffi.cast("int(__thiscall*)(void*, Vector, Vector, Vector, Vector, unsigned char[4], float)", signature_AddGloxBox) -- @ void* GlowObjectManager, Vector BoxPosition, Vector Direction, Vector Mins, Vector Maxs, unsigned char[4] Colour, float Duration

local enabled = ui.new_checkbox("LUA", "B", "Trail color")
local color = ui.new_color_picker("LUA", "B", "Trail color", 71, 182, 255, 255)

client.set_event_callback("paint", function() 
    local localPlayer = entity.get_local_player()
    local vec_mins = vector(entity.get_prop(localPlayer, 'm_vecMins'))
    local clr = ffi.cast("unsigned char**", ffi.new("unsigned char[4]", ui.get(color)))[0]
    local origin = vector(entity.get_origin(localPlayer))
    local speed = vector(entity.get_prop(localPlayer, 'm_vecVelocity')):length()
    if speed > 2 and ui.get(enabled) then
        native_AddGlowBox(native_GlowObjectManager(), origin, vector(client.camera_angles()), vec_mins * 0.5, vec_mins * 0.5, clr, 1) 
    end
end)
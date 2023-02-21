local vector = require 'vector'

function countMap(list)
    local counts = {}
    for _, value in ipairs(list) do
        counts[value] = (counts[value] or 0) + 1
    end
    return counts
end

function keyLargest(map)
    local best = next(map)
    for key in pairs(map) do
        if map[best] < map[key] then
            best = key
        end
    end
    return best
end

function mostCommon(list)
    return keyLargest(countMap(list))
end

function round(number)
    return math.floor(number + 0.5)
end

local states = {
    standing = {
        displayName = "standing",
        data = {},
        hasPrinted = false
    },
    running = {
        displayName = "running",
        data = {},
        hasPrinted = false
    },
    air = {
        displayName = "in air",
        data = {},
        hasPrinted = false
    }
}

local ticksThreshold = 50

local lastTime, lastYaw, selectedPlayer;

function restoreDefaults()
    client.unset_event_callback("net_update_end", grabYaw)
    lastTime, lastYaw, selectedPlayer = nil, nil, nil
    for var, value in pairs(states) do
        value.data = {}
        value.hasPrinted = false
    end
end

function validateJitter(table)
    return (round(mostCommon(table) / 2))/2
end

function saveYawToTable(yaw)
    if not entity.is_alive(selectedPlayer) or entity.is_dormant(selectedPlayer) then
        client.error_log("[AA STEALER] Entity is invalid or dormant, aborting.")
        restoreDefaults()
    end

    if not entity.is_alive(entity.get_local_player()) then
        client.error_log("[AA STEALER] Invalid (or dead) local player.")
        restoreDefaults()
    end

    local velocity = vector(entity.get_prop(selectedPlayer, "m_vecVelocity"))
    local playerName = entity.get_player_name(selectedPlayer)

    if lastYaw then
        local delta = yaw - lastYaw;
        if velocity:length() < 2 then
            table.insert(states.standing.data, delta)
        end
        if velocity:length() > 2 then
            table.insert(states.running.data, delta)
        end
        if bit.band(entity.get_prop(selectedPlayer, "m_fFlags"), 1) == 0 then
            table.insert(states.air.data, delta)
        end
    end

    for var, value in pairs(states) do
        for index, values in pairs(value.data) do
            if index > ticksThreshold and not value.hasPrinted then
                client.log("[AA STEALER] Finished stealing " .. playerName .. " " .. value.displayName ..
                               " AA, waiting for other conditions.")
                value.hasPrinted = true
            end
        end
    end

    if states.standing.hasPrinted and states.running.hasPrinted and states.air.hasPrinted then
        for var, value in pairs(states) do
            client.log("[AA STEALER] " .. playerName .. " " .. value.displayName .. " Jitter is " ..
                           validateJitter(value.data))
        end
        restoreDefaults()
    end
end

function grabYaw()
    currentTime = entity.get_prop(selectedPlayer, "m_flSimulationTime") / globals.tickinterval()

    if not lastTime or lastTime < currentTime then
        local pitch, yaw = entity.get_prop(selectedPlayer, "m_angEyeAngles")
        lastTime = currentTime
        saveYawToTable(yaw)
        lastYaw = yaw
    end
end

local stealer = ui.new_button("Players", "Adjustments", "Steal AA", function()
    selectedPlayer = ui.get(ui.reference("Players", "Players", "Player List"))
    client.set_event_callback("net_update_end", grabYaw)
end)

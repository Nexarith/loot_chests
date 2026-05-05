local spawns = {}

local storage = minetest.get_mod_storage()

--------------------------------------------------

-- ⚙️ CONFIGURATION (MATCHES MAPVAULT)

--------------------------------------------------

-- This is where players wait before accepting rules

local newbie_spawn = {x = 0, y = 62, z = 0} 

-- The center and size of your protected arena

local map_center = {x = 100, y = 50, z = 100} 

local protected_radius = 750

--------------------------------------------------

-- 💾 LOAD/SAVE DATA

--------------------------------------------------

local saved = storage:get_string("spawns")

if saved ~= "" then

    spawns = minetest.deserialize(saved) or {}

end

local function save_spawns()

    storage:set_string("spawns", minetest.serialize(spawns))

end

--------------------------------------------------

-- ⚔️ COMBAT CHECK

--------------------------------------------------

local function is_in_combat(name)

    if _G.in_combat then

        return _G.in_combat(name)

    end

    return false

end

local function get_combat_time_left(name)

    if not _G.combat_players then return 0 end

    local end_time = _G.combat_players[name]

    if not end_time then return 0 end

    return math.max(0, end_time - os.time())

end

--------------------------------------------------

-- 🎯 SPAWN TELEPORT (THE LOGIC)

--------------------------------------------------

local function teleport_to_spawn(player)

    if #spawns == 0 then return end

    

    local pos = player:get_pos()

    local dist = vector.distance(pos, map_center)

    -- ONLY teleport if they are INSIDE the mapvault protected area

    if dist <= protected_radius then

        local spawn = spawns[math.random(#spawns)]

        player:set_pos(spawn)

       

    else

        -- If they are outside, they stay where they logged in

        minetest.log("action", "[Spawn] " .. player:get_player_name() .. " is outside spawn area, skipping teleport.")

    end

end

--------------------------------------------------

-- 🚪 JOIN PLAYER

--------------------------------------------------

minetest.register_on_joinplayer(function(player)

    local name = player:get_player_name()

    -- Small delay to allow the engine to position the player first

    minetest.after(0.5, function()

        if not player or not player:is_player() then return end

        -- 📜 Rules check (If they haven't accepted, force them to lobby)

        if _G.rules and _G.rules.has_accepted then

            if not _G.rules.has_accepted(name) then

                player:set_pos(newbie_spawn)

                return

            end

        end

        -- Check if they are in the protected zone; if so, warp them out

        teleport_to_spawn(player)

    end)

end)

--------------------------------------------------

-- 💀 RESPAWN

--------------------------------------------------

minetest.register_on_respawnplayer(function(player)

    -- When a player dies, they ALWAYS go to a random spawn

    minetest.after(0.1, function()

        if player and #spawns > 0 then

            local spawn = spawns[math.random(#spawns)]

            player:set_pos(spawn)

        end

    end)

    return true

end)

--------------------------------------------------

-- 🧱 ADMIN COMMANDS

--------------------------------------------------

minetest.register_chatcommand("addspawn", {

    privs = {server = true},

    func = function(name)

        local player = minetest.get_player_by_name(name)

        if not player then return end

        table.insert(spawns, vector.round(player:get_pos()))

        save_spawns()

        return true, "Spawn added!"

    end

})

minetest.register_chatcommand("removespawn", {

    privs = {server = true},

    func = function(name)

        local player = minetest.get_player_by_name(name)

        if not player then return end

        local pos = player:get_pos()

        local closest, dist = nil, math.huge

        for i, s in ipairs(spawns) do

            local d = vector.distance(pos, s)

            if d < dist then

                closest, dist = i, d

            end

        end

        if closest then

            table.remove(spawns, closest)

            save_spawns()

            return true, "Removed nearest spawn"

        end

        return false, "No spawn found"

    end

})

minetest.register_chatcommand("listspawns", {

    privs = {server = true},

    func = function()

        if #spawns == 0 then return false, "No spawns" end

        local msg = "Spawns:\n"

        for i, s in ipairs(spawns) do

            msg = msg .. i .. ": (" .. s.x .. "," .. s.y .. "," .. s.z .. ")\n"

        end

        return true, msg

    end

})

--------------------------------------------------

-- 🎮 SPAWN COMMAND (MANUAL)

--------------------------------------------------

minetest.register_chatcommand("spawn", {

    func = function(name)

        local player = minetest.get_player_by_name(name)

        if not player then return end

        

        if is_in_combat(name) then

            local t = get_combat_time_left(name)

            return false, "In combat. Wait " .. t .. "s"

        end

        

        if #spawns == 0 then return false, "No spawns set!" end

        -- Manual /spawn command always works regardless of radius

        local spawn = spawns[math.random(#spawns)]

        player:set_pos(spawn)

        return true, "Teleported to spawn!"

    end

})

--------------------------------------------------

-- 🔗 RULES HOOK

--------------------------------------------------

_G.on_rules_accepted = function(player)

    if not player then return end

    minetest.after(0.1, function()

        -- When they accept rules, they are usually at the newbie_spawn, 

        -- so the radius check in teleport_to_spawn will trigger.

        teleport_to_spawn(player)

    end)

end
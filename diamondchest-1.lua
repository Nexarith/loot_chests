-- loot_chests/diamondchest.lua

local CHEST_TIME = 30

local chest_states = {}

local function pos_to_key(pos) return pos.x..","..pos.y..","..pos.z end

local loot_items = {

    "default:pick_diamond", "default:sword_diamond", "default:axe_diamond",

    "3d_armor:helmet_diamond", "3d_armor:chestplate_diamond", "3d_armor:leggings_diamond", "3d_armor:boots_diamond",

    "3d_armor:helmet_gold", "3d_armor:chestplate_gold", "3d_armor:leggings_gold",

    "shields:shield_gold", "shields:shield_diamond", "loot_chests:mese_chest",

    "default:apple", "farming:bread", "wool:black", "wool:green", "ctf_ranged:shotgun_loaded","ctf_ranged:ammo"

}

local function shuffle(t) for i = #t, 2, -1 do local j = math.random(i); t[i], t[j] = t[j], t[i] end end

local function spawn_loot(pos)

    local meta = minetest.get_meta(pos)

    local inv = meta:get_inventory()

    if not inv then return end

    inv:set_size("main", 32)

    inv:set_list("main", {})

    local loot_pool = {}

    for _, item in ipairs(loot_items) do table.insert(loot_pool, item) end

    shuffle(loot_pool)

    for i = 1, math.random(6, 10) do

        local name = loot_pool[i]

        local count = 1

        if name == "default:apple" then count = math.random(20,25)

        elseif name == "farming:bread" then count = math.random(10,30)

        elseif name == "wool:black" then count = math.random(10,70)

        elseif name == "wool:green" then count = math.random(10,20) end

        inv:add_item("main", name .. " " .. count)

    end

end

minetest.register_entity("loot_chests:diamond_label", {

    initial_properties = { visual = "upright_sprite", textures = {"blank.png"}, visual_size = {x = 0, y = 0}, pointable = false, physical = false },

    on_step = function(self, dtime)

        self.timer = (self.timer or 0) + dtime

        if self.timer < 1 then return end

        self.timer = 0

        if not self.chest_pos then self.object:remove() return end

        local state = chest_states[pos_to_key(self.chest_pos)]

        if not state or state.locked then self.object:set_properties({ nametag = "" }) return end

        self.object:set_properties({ nametag = "DIAMOND CHEST OPEN: "..math.max(0, math.ceil(state.timer or 0)).."s", nametag_color = "#00FFFF" })

    end,

})

minetest.register_node("loot_chests:diamond_chest", {

    description = "Diamond Chest",

    tiles = {"diamondchest_top.png", "diamondchest_top.png", "diamondchest_side.png", "diamondchest_side.png", "diamondchest_side.png", "diamondchest_front.png"},

    paramtype2 = "facedir", light_source = 8, groups = {unbreakable=1},

    on_construct = function(pos)

        local meta = minetest.get_meta(pos)

        meta:set_string("infotext","Diamond Chest (Locked)")

        chest_states[pos_to_key(pos)] = {locked = true, timer = 0}

    end,

    on_rightclick = function(pos, node, clicker, itemstack)

        local key = pos_to_key(pos)

        local state = chest_states[key] or {locked = true, timer = 0}

        if state.locked then

            if itemstack:get_name() == "loot_chests:diamond_key" then

                state.locked = false; state.timer = CHEST_TIME; chest_states[key] = state

                itemstack:take_item(1); clicker:set_wielded_item(itemstack)

                spawn_loot(pos)

                clicker:punch(clicker, 1.0, {full_punch_interval = 1.0, damage_groups = {fleshy = 4}}, nil)

                minetest.chat_send_all(minetest.colorize("#00FFFF", "[SYSTEM] "..clicker:get_player_name().." opened a Diamond Chest!"))

                local meta = minetest.get_meta(pos)

                meta:set_string("formspec", "size[10,10]list[current_name;main;1,1;8,4;]list[current_player;main;1,6;8,4;]listring[current_name;main]listring[current_player;main]")

                meta:set_string("infotext","Diamond Chest (OPEN)")

                local obj = minetest.add_entity(vector.add(pos, {x=0,y=1.2,z=0}), "loot_chests:diamond_label")

                if obj then obj:get_luaentity().chest_pos = pos end

                minetest.after(CHEST_TIME, function()

                    state.locked = true; local m = minetest.get_meta(pos)

                    m:set_string("formspec",""); m:set_string("infotext","Diamond Chest (Locked)"); m:get_inventory():set_list("main", {})

                end)

            else minetest.chat_send_player(clicker:get_player_name(), "You need a Diamond Key!") end

        end

        return itemstack

    end,

})

minetest.register_globalstep(function(dtime)

    for _, state in pairs(chest_states) do if not state.locked and state.timer then state.timer = state.timer - dtime end end

end)
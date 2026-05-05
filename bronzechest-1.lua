-- loot_chests/bronzechest.lua

local chest_storage = minetest.get_mod_storage()

local REFILL_TIME = 90

local last_refill_tick = tonumber(chest_storage:get_string("bronze_last_refill")) or minetest.get_gametime()

local loot_items = {

    {name="default:pick_bronze", count=1},

    {name="default:axe_bronze", count=1},

    {name="default:shovel_bronze", count=1},

    {name="default:sword_bronze", count=1},

    {name="default:pick_steel", count=1},

    {name="default:axe_steel", count=1},

    {name="default:shovel_steel", count=1},

    {name="default:sword_steel", count=1}

}

local armor_items = {

    "3d_armor:helmet_bronze", "3d_armor:chestplate_bronze", "3d_armor:leggings_bronze", "3d_armor:boots_bronze",

    "3d_armor:helmet_steel", "3d_armor:chestplate_steel", "3d_armor:leggings_steel", "3d_armor:boots_steel"

}

local function get_wool()

    if math.random(2) == 1 then

        return ItemStack({name="wool:green", count=15})

    else

        return ItemStack({name="wool:red", count=math.random(6,12)})

    end

end

local function refill_chest(pos)

    local meta = minetest.get_meta(pos)

    local inv = meta:get_inventory()

    if not inv then return end

    inv:set_list("main", {})

    for i = 1, math.random(2,4) do

        inv:add_item("main", ItemStack(loot_items[math.random(#loot_items)]))

    end

    for i = 1, math.random(1,2) do

        inv:add_item("main", armor_items[math.random(#armor_items)])

    end

    inv:add_item("main", get_wool())

    local apple_counts = {5,10,1,4}

    local bread_counts = {15,4,2,8,6}

    for i = 1, math.random(1,3) do

        if math.random(2) == 1 then

            inv:add_item("main", ItemStack({name="default:apple", count=apple_counts[math.random(#apple_counts)]}))

        else

            inv:add_item("main", ItemStack({name="farming:bread", count=bread_counts[math.random(#bread_counts)]}))

        end

    end

    if math.random(100) <= 2 then

        inv:add_item("main", "loot_chests:diamond_key")

    end

    meta:set_int("last_refill_tick", last_refill_tick or 0)

end

minetest.register_entity("loot_chests:bronze_label", {

    initial_properties = {

        visual = "upright_sprite", textures = {"blank.png"},

        visual_size = {x = 0, y = 0}, pointable = false, physical = false,

    },

    on_step = function(self, dtime)

        self.timer = (self.timer or 0) + dtime

        if self.timer < 1 then return end

        self.timer = 0

        if not self.chest_pos then self.object:remove() return end

        local node = minetest.get_node_or_nil(self.chest_pos)

        if not node or node.name ~= "loot_chests:bronze_loot_chest" then self.object:remove() return end

        local current_tick = last_refill_tick or minetest.get_gametime()

        local time_passed = minetest.get_gametime() - current_tick

        local countdown = math.max(0, REFILL_TIME - time_passed)

        local players = minetest.get_connected_players()

        local show = false

        for _, p in ipairs(players) do

            if vector.distance(p:get_pos(), self.object:get_pos()) < 8 then show = true break end

        end

        if show then

            self.object:set_properties({

                nametag = "Bronze Loot Chest: " .. countdown .. "s",

                nametag_color = "#cd7f32"

            })

        else self.object:set_properties({ nametag = "" }) end

    end,

})

minetest.register_node("loot_chests:bronze_loot_chest", {

    description = "Bronze Loot Chest",

    tiles = {"bronzechest_top.png","bronzechest_top.png","bronzechest_side.png","bronzechest_side.png","bronzechest_side.png","bronzechest_front.png"},

    paramtype2 = "facedir",

    groups = {unbreakable=1},

    on_construct = function(pos)

        local meta = minetest.get_meta(pos)

        meta:set_string("formspec",

            "size[8,9]list[current_name;main;0,0;8,4;]" ..

            "list[current_player;main;0,5;8,4;]" ..

            "listring[current_name;main]" ..

            "listring[current_player;main]"

        )

        meta:get_inventory():set_size("main", 32)

        refill_chest(pos)

        local obj = minetest.add_entity(vector.add(pos, {x=0,y=0.1,z=0}), "loot_chests:bronze_label")

        if obj then obj:get_luaentity().chest_pos = pos end

    end,

})

minetest.register_lbm({

    name = "loot_chests:bronze_refill_handler",

    nodenames = {"loot_chests:bronze_loot_chest"},

    run_at_every_load = true,

    action = function(pos)

        local meta = minetest.get_meta(pos)

        if meta:get_int("last_refill_tick") < (last_refill_tick or 0) then refill_chest(pos) end

        local objs = minetest.get_objects_inside_radius(pos, 0.5)

        local has_label = false

        for _, obj in ipairs(objs) do

            local ent = obj:get_luaentity()

            if ent and ent.name == "loot_chests:bronze_label" then has_label = true break end

        end

        if not has_label then

            local obj = minetest.add_entity(vector.add(pos, {x=0,y=0.05,z=0}), "loot_chests:bronze_label")

            if obj then obj:get_luaentity().chest_pos = pos end

        end

    end,

})

minetest.register_globalstep(function()

    local now = minetest.get_gametime()

    last_refill_tick = last_refill_tick or now

    if now - last_refill_tick >= REFILL_TIME then

        last_refill_tick = now

        chest_storage:set_string("bronze_last_refill", tostring(now))

        for _, player in ipairs(minetest.get_connected_players()) do

            local nodes = minetest.find_nodes_in_area(vector.subtract(player:get_pos(), 32), vector.add(player:get_pos(), 32), {"loot_chests:bronze_loot_chest"})

            for _, c_pos in ipairs(nodes) do refill_chest(c_pos) minetest.sound_play("default_chest_open", {pos = c_pos, gain = 0.3}) end

        end

        minetest.chat_send_all(minetest.colorize("#cd7f32", "[SYSTEM] Bronze chests have been refilled!"))

    end

end)
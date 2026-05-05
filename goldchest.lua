-- loot_chests/goldchest.lua

local chest_storage = minetest.get_mod_storage()

local REFILL_TIME = 180

local last_refill_tick = tonumber(chest_storage:get_string("last_refill_tick")) or minetest.get_gametime()

local loot_items = {

    {name="default:pick_mese", count=1}, {name="default:axe_mese", count=1},

    {name="default:shovel_mese", count=1}, {name="default:sword_mese", count=1},

    {name="shields:shield_gold", count=1}

}

local golden_armor = {"3d_armor:helmet_gold", "3d_armor:chestplate_gold", "3d_armor:leggings_gold", "3d_armor:boots_gold"}

local function refill_chest(pos)

    local meta = minetest.get_meta(pos)

    local inv = meta:get_inventory()

    if not inv then return end

    inv:set_list("main", {})

    for i = 1, math.random(2, 4) do inv:add_item("main", ItemStack(loot_items[math.random(#loot_items)])) end

    for i = 1, math.random(1, 2) do inv:add_item("main", golden_armor[math.random(#golden_armor)]) end

    inv:add_item("main", "default:apple "..math.random(5, 10))

    inv:add_item("main", "farming:bread "..math.random(2, 9))

    inv:add_item("main", "wool:black "..(math.random(2)==1 and 30 or 65))

    if math.random(100) <= 5 then inv:add_item("main", "loot_chests:diamond_key") end

    meta:set_int("last_refill_tick", last_refill_tick or 0)

end

minetest.register_entity("loot_chests:label", {

    initial_properties = { visual = "upright_sprite", textures = {"blank.png"}, visual_size = {x = 0, y = 0}, pointable = false, physical = false },

    on_step = function(self, dtime)

        self.timer = (self.timer or 0) + dtime

        if self.timer < 1 then return end

        self.timer = 0

        if not self.chest_pos then self.object:remove() return end

        local node = minetest.get_node_or_nil(self.chest_pos)

        if not node or node.name ~= "loot_chests:golden_loot_chest" then self.object:remove() return end

        local countdown = math.max(0, REFILL_TIME - (minetest.get_gametime() - (last_refill_tick or minetest.get_gametime())))

        local show = false

        for _, p in ipairs(minetest.get_connected_players()) do if vector.distance(p:get_pos(), self.object:get_pos()) < 8 then show = true break end end

        if show then self.object:set_properties({ nametag = "Golden Loot Chest: " .. countdown .. "s", nametag_color = "#FFD700" })

        else self.object:set_properties({ nametag = "" }) end

    end,

})

minetest.register_node("loot_chests:golden_loot_chest", {

    description = "Golden Loot Chest",

    tiles = {"goldchest_top.png", "goldchest_top.png", "goldchest_side.png", "goldchest_side.png", "goldchest_side.png", "goldchest_front.png"},

    paramtype2 = "facedir", groups = {unbreakable=1},

    on_construct = function(pos)

        local meta = minetest.get_meta(pos)

        meta:set_string("formspec", "size[8,9]list[current_name;main;0,0;8,4;]list[current_player;main;0,5;8,4;]listring[current_name;main]listring[current_player;main]")

        meta:get_inventory():set_size("main", 32)

        refill_chest(pos)

        local obj = minetest.add_entity(vector.add(pos, {x=0,y=0.8,z=0}), "loot_chests:label")

        if obj then obj:get_luaentity().chest_pos = pos end

    end,

})

minetest.register_lbm({

    name = "loot_chests:refill_handler", nodenames = {"loot_chests:golden_loot_chest"}, run_at_every_load = true,

    action = function(pos)

        if minetest.get_meta(pos):get_int("last_refill_tick") < (last_refill_tick or 0) then refill_chest(pos) end

        local has_label = false

        for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 0.5)) do if obj:get_luaentity() and obj:get_luaentity().name == "loot_chests:label" then has_label = true break end end

        if not has_label then local obj = minetest.add_entity(vector.add(pos, {x=0,y=0.1,z=0}), "loot_chests:label"); if obj then obj:get_luaentity().chest_pos = pos end end

    end,

})

minetest.register_globalstep(function()

    local now = minetest.get_gametime()

    last_refill_tick = last_refill_tick or now

    if now - last_refill_tick >= REFILL_TIME then

        last_refill_tick = now; chest_storage:set_string("last_refill_tick", tostring(now))

        for _, player in ipairs(minetest.get_connected_players()) do

            local nodes = minetest.find_nodes_in_area(vector.subtract(player:get_pos(), 32), vector.add(player:get_pos(), 32), {"loot_chests:golden_loot_chest"})

            for _, c_pos in ipairs(nodes) do refill_chest(c_pos); minetest.sound_play("default_chest_open", {pos = c_pos, gain = 0.3}) end

        end

        minetest.chat_send_all(minetest.colorize("#FFD700", "[SYSTEM] Golden chests have been refilled!"))

    end

end)

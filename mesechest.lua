-- loot_chests/mesechest.lua

local REFILL_TIME = 180

local build_loot = {

    building_blocks = {"default:wood", "default:aspen_wood", "default:pine_wood", "default:acacia_wood", "default:glass", "default:obsidian"},

    trees = {"default:tree", "default:aspen_tree", "default:pine_tree", "default:acacia_tree", "default:jungletree", "variety:darkforest_tree", "everness:coral_tree", "everness:crystal_tree", "everness:dry_tree", "everness:cursed_dream_tree", "everness:lava_tree", "everness:mese_tree", "everness:palm_tree", "everness:willow_tree", "everness:sequoia_tree", "swamp:mangrove_tree", "variety:meadow_tree", "variety:autumn_forest_tree", "variety:redwood_tree", "variety:frost_land_tree", "variety:dorwinion_tree", "variety:japanese_tree", "variety:tropical_rainforest_tree"},

    saplings = {"variety:darkforest_sapling", "default:junglesapling", "default:emergent_jungle_sapling", "default:pine_sapling", "default:acacia_sapling", "default:aspen_sapling", "everness:coral_tree_sapling", "everness:crystal_tree_sapling", "everness:crystal_tree_large_sapling", "everness:dry_tree_sapling", "everness:cursed_dream_tree_sapling", "everness:lava_tree_sapling", "everness:mese_tree_sapling", "everness:palm_tree_sapling", "everness:willow_tree_sapling", "everness:sequoia_tree_sapling", "swamp:mangrove_sapling", "everness:coral_tree_bioluminescent_sapling", "variety:meadow_sapling", "variety:autumn_forest_sapling", "variety:redwood_sapling", "variety:frost_land_sapling", "variety:dorwinion_sapling", "variety:japanese_sapling", "variety:tropical_rainforest_sapling", "default:blueberry_bush_sapling"},

    terrain = {"default:sand", "default:gravel", "default:dirt", "default:dirt_with_coniferous_grass", "default:dirt_with_dry_grass", "default:dirt_with_grass", "default:dirt_with_rainforest_litter", "default:dirt_with_snow", "default:dry_dirt_with_dry_grass", "everness:coral_dirt", "everness:crystal_cave_dirt", "everness:crystal_cave_dirt_with_moss", "everness:crystal_dirt", "everness:cursed_dirt", "everness:dirt_1", "everness:dirt_with_coral_grass", "everness:dirt_with_crystal_grass", "everness:dirt_with_cursed_grass", "everness:dirt_with_grass_1", "everness:dirt_with_grass_extras_1", "everness:dirt_with_grass_extras_2", "everness:dry_dirt", "everness:dry_dirt_with_dirt_grass", "everness:dry_ocean_dirt", "swamp:dirt_with_swamp_grass", "variety:cherry_dirt_with_grass", "variety:darkforest_dirt_with_grass", "variety:dirt_with_bamboo", "variety:giant_coniferous_forest_dirt_with_grass", "variety:japanese_dirt_with_grass", "variety:meadow_dirt_with_grass", "variety:rainwood_dirt_with_grass", "variety:tropical_rainforest_dirt_with_grass"},

    ores = {"default:stone_with_coal", "default:stone_with_iron"}

}

local function refill_build_chest(pos)

    local meta = minetest.get_meta(pos); local inv = meta:get_inventory()

    if not inv then return end; inv:set_list("main", {})

    local items = { {cat="building_blocks",c=2,mi=5,ma=20}, {cat="trees",c=2,mi=1,ma=3}, {cat="saplings",c=2,mi=2,ma=5}, {cat="terrain",c=3,mi=2,ma=4}, {cat="ores",c=1,mi=5,ma=12} }

    for _, g in ipairs(items) do for i=1, g.c do inv:add_item("main", build_loot[g.cat][math.random(#build_loot[g.cat])].." "..math.random(g.mi, g.ma)) end end

    meta:set_int("last_refill", minetest.get_gametime())

end

minetest.register_entity("loot_chests:build_label", {

    initial_properties = { visual = "upright_sprite", textures = {"blank.png"}, visual_size = {x = 0, y = 0}, pointable = false, physical = false },

    on_step = function(self, dtime)

        self.timer = (self.timer or 0) + dtime

        if self.timer < 1 then return end

        self.timer = 0

        if not self.chest_pos then self.object:remove() return end

        local meta = minetest.get_meta(self.chest_pos); local node = minetest.get_node_or_nil(self.chest_pos)

        if not node or node.name ~= "loot_chests:mese_chest" then self.object:remove() return end

        local countdown = math.max(0, REFILL_TIME - (minetest.get_gametime() - meta:get_int("last_refill")))

        if countdown <= 0 then refill_build_chest(self.chest_pos); minetest.sound_play("default_chest_open", {pos = self.chest_pos, gain = 0.3}) end

        local show = false

        for _, p in ipairs(minetest.get_connected_players()) do if vector.distance(p:get_pos(), self.object:get_pos()) < 8 then show = true break end end

        if show then self.object:set_properties({ nametag = "Build Chest Refill: " .. countdown .. "s", nametag_color = "#32CD32" })

        else self.object:set_properties({ nametag = "" }) end

    end,

})

minetest.register_node("loot_chests:mese_chest", {

    description = "Build Chest",

    tiles = {"lootchest_mesechest_top.png", "lootchest_mesechest_top.png", "lootchest_mesechest_side.png", "lootchest_mesechest_side.png", "lootchest_mesechest_front.png"},

    paramtype2 = "facedir", groups = {choppy = 2, oddly_breakable_by_hand = 2},

    on_construct = function(pos)

        local meta = minetest.get_meta(pos)

        meta:set_string("formspec", "size[8,9]list[current_name;main;0,0;8,4;]list[current_player;main;0,5;8,4;]listring[current_name;main]listring[current_player;main]")

        meta:set_string("infotext", "Build Chest"); meta:get_inventory():set_size("main", 32); refill_build_chest(pos)

        local obj = minetest.add_entity(vector.add(pos, {x=0,y=0.8,z=0}), "loot_chests:build_label")

        if obj then obj:get_luaentity().chest_pos = pos end

    end,

    after_place_node = function(pos, placer)

        if placer and placer:is_player() then

            placer:get_meta():set_int("score", placer:get_meta():get_int("score") + 5)

            minetest.chat_send_player(placer:get_player_name(), minetest.colorize("#32CD32", "Build Chest placed! +5 Score"))

        end

    end,

})

minetest.register_lbm({

    name = "loot_chests:build_refill_handler", nodenames = {"loot_chests:mese_chest"}, run_at_every_load = true,

    action = function(pos)

        local has_label = false

        for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 0.5)) do if obj:get_luaentity() and obj:get_luaentity().name == "loot_chests:build_label" then has_label = true break end end

        if not has_label then local obj = minetest.add_entity(vector.add(pos, {x=0,y=0.8,z=0}), "loot_chests:build_label"); if obj then obj:get_luaentity().chest_pos = pos end end

    end,

})

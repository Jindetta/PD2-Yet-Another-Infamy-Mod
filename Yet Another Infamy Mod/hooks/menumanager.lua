local Self = YAIMod
Self.register("MenuManager", "show_confirm_become_infamous")
Self.register("MenuCallbackHandler", "is_level_100", "_increase_infamous")

function MenuManager:show_confirm_become_infamous(params)
    if managers.experience:current_rank() < Self.MIN_INFAMY_REQUIREMENT then
        Self.call("MenuManager", "show_confirm_become_infamous", self, params)
    else
        local dialog_data = {
            title = managers.localization:text("dialog_become_infamous"),
            text = managers.localization:text("dialog_become_infamous_modded_text", {penalty = self:penalty_string()}),
            focus_button = 2,
            button_list = {
                {
                    text = managers.localization:text("dialog_yes"),
                    callback_func = params.yes_func
                },
                {
                    text = managers.localization:text("dialog_no"),
                    callback_func = params.no_func,
                    cancel_button = true
                }
            },
            w = 620,
            h = 500
        }

        managers.system_menu:show_new_unlock(dialog_data)
    end
end

function MenuCallbackHandler:is_level_100()
    local has_max_level = Self.call("MenuCallbackHandler", "is_level_100", self)
    local has_required_xp = managers.experience:can_rank_up()

    return has_max_level and has_required_xp
end

function MenuCallbackHandler:_increase_infamous(...)
    self:store_active_loadout()

    Self.call("MenuCallbackHandler", "_increase_infamous", self, ...)

    if managers.experience:current_rank() > Self.MIN_INFAMY_REQUIREMENT then
        for level = 0, managers.experience:current_level() do
            managers.upgrades:aquire_from_level_tree(level)
            managers.upgrades:verify_level_tree(level)
        end

        if managers.experience:current_rank() < Self.MAX_LEVEL then
            local points = managers.skilltree:max_points_for_current_level()
            managers.skilltree:_aquire_points(points)
        end

        self:restore_active_loadout()

        managers.experience:set_initial_level_data()
        managers.savefile:save_progress()
    end

    Global.active_loadout = nil
end

-- Additional functions

function MenuManager:penalty_string()
    return ("%.1f"):format(managers.experience:get_penalty_value(1) * 100)
end

function MenuCallbackHandler:store_active_loadout()
    Global.active_loadout = {
        deployable = managers.blackmarket:equipped_deployable(1),
        secondary_deployable = managers.blackmarket:equipped_deployable(2),
        primary = managers.blackmarket:equipped_weapon_slot("primaries"),
        secondary = managers.blackmarket:equipped_weapon_slot("secondaries"),
        melee = managers.blackmarket:equipped_melee_weapon(),
        grenade = managers.blackmarket:equipped_grenade(),
        armor = managers.blackmarket:equipped_armor()
    }
end

function MenuCallbackHandler:restore_active_loadout()
    local data = Global.active_loadout

    if type(data) == "table" then
        if data.primary then
            managers.blackmarket:equip_weapon("primaries", data.primary)
        end

        if data.secondary then
            managers.blackmarket:equip_weapon("secondaries", data.secondary)
        end

        if data.melee then
            managers.blackmarket:equip_melee_weapon(data.melee)
        end

        if data.grenade then
            managers.blackmarket:equip_grenade(data.grenade)
        end

        if data.armor then
            managers.blackmarket:equip_armor(data.armor)
        end

        if data.deployable then
            managers.blackmarket:equip_deployable({
                name = data.deployable,
                target_slot = 1
            })
        end

        if data.secondary_deployable then
            managers.blackmarket:equip_deployable({
                name = data.secondary_deployable,
                target_slot = 2
            })
        end

        managers.blackmarket:_verfify_equipped()
    end
end
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
    Self.call("MenuCallbackHandler", "_increase_infamous", self, ...)

    if managers.experience:current_rank() > Self.MIN_INFAMY_REQUIREMENT then
        for level = 0, managers.experience:current_level() do
            managers.upgrades:aquire_from_level_tree(level)
            managers.upgrades:verify_level_tree(level)
        end

        local points = managers.skilltree:max_points_for_current_level()
        managers.skilltree:_aquire_points(points)

        managers.experience:set_initial_level_data()
        managers.savefile:save_progress()
    end
end

-- Additional functions

function MenuManager:penalty_string()
    return ("%.1f"):format(managers.experience:get_penalty(1) * 100)
end
local PENALTY_MULTIPLIER = 0.2
local MIN_INFAMY_REQUIREMENT = 25

if RequiredScript == "lib/managers/experiencemanager" then
    function ExperienceManager:get_xp(reputation_level)
        local total_xp = 0

        for i = 1, self:clamp_level(reputation_level) do
            total_xp = total_xp + tweak_data:get_value("experience_manager", "levels", i, "points")
        end

        return math.min(math.floor(total_xp), 23336413)
    end

    function ExperienceManager:clamp_level(level)
        return math.max(0, math.min(level, self:level_cap()))
    end

    function ExperienceManager:recalculate_level(current_level)
        local current_rank = self:current_rank()

        if current_rank > MIN_INFAMY_REQUIREMENT then
            current_level = math.max(current_rank, current_level)
        end

        return self:clamp_level(current_level)
    end

    function ExperienceManager:set_current_rank(value)
        if value <= tweak_data.infamy.ranks then
            managers.infamy:aquire_point()

            self._global.rank = Application:digest_value(value, true)
            self._global.level = Application:digest_value(self:current_level(), true)

            self:_check_achievements()
            self:update_progress()
        end
    end

    function ExperienceManager:completed_rank_xp_requirement()
        if self:current_rank() > MIN_INFAMY_REQUIREMENT then
            return self:total() >= self:get_xp(self:level_cap())
        end

        return true
    end

    function ExperienceManager:completed_initial_requirements()
        if self:current_rank() > MIN_INFAMY_REQUIREMENT then
            local required_level = self:recalculate_level(0)
            local required_xp = self:get_xp(required_level + 1)

            return self:level() >= required_level and self:total() >= required_xp
        end

        return true
    end

    local ExperienceManager_SetNextLevelData = ExperienceManager._set_next_level_data

    function ExperienceManager:_set_next_level_data(level)
        if self:completed_initial_requirements() then
            ExperienceManager_SetNextLevelData(self, level)
        else
            local needed_xp = self:get_xp(level)

            self._global.next_level_data = {}
            self:_set_next_level_data_points(Application:digest_value(needed_xp, true))
            self:_set_next_level_data_current_points(self:total())

            if self._experience_progress_data then
                table.insert(self._experience_progress_data, {
                    level = self:clamp_level(level),
                    current = self:total(),
                    total = needed_xp
                })
            end
        end
    end

    local ExperienceManager_GetXPDissected = ExperienceManager.get_xp_dissected

    function ExperienceManager:get_xp_dissected(...)
        local total_xp, dissection_table = ExperienceManager_GetXPDissected(self, ...)

        if not self:completed_initial_requirements() then
            local penalty_xp = math.floor(total_xp * PENALTY_MULTIPLIER)

            dissection_table.bonus_low_level = dissection_table.bonus_low_level - penalty_xp
            total_xp = total_xp - penalty_xp
        end

        return total_xp, dissection_table
    end

    local ExperienceManager_CurrentLevel = ExperienceManager.current_level

    function ExperienceManager:current_level()
        return self:recalculate_level(self:level())
    end

    function ExperienceManager:level()
        return ExperienceManager_CurrentLevel(self)
    end
elseif RequiredScript == "lib/managers/menumanager" then
    local MenuManager_IsLevel100 = MenuCallbackHandler.is_level_100

    function MenuCallbackHandler:is_level_100()
        local has_max_level = MenuManager_IsLevel100(self)
        local has_required_xp = managers.experience:completed_rank_xp_requirement()

        return has_max_level and has_required_xp
    end

    local MenuManager_ShowConfirmBecomeInfamous = MenuManager.show_confirm_become_infamous

    function MenuManager:show_confirm_become_infamous(params)
        if managers.experience:current_rank() < MIN_INFAMY_REQUIREMENT then
            MenuManager_ShowConfirmBecomeInfamous(self, params)
        else
            local dialog_data = {
                title = managers.localization:text("dialog_become_infamous"),
                text = "-- Are you sure? --",
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

    Hooks:PostHook(MenuCallbackHandler, "_increase_infamous", "YAIMod_IncreaseInfamous", function()
        for level = 0, managers.experience:current_level() do
            managers.upgrades:aquire_from_level_tree(level, false)
            managers.upgrades:verify_level_tree(level, false)
        end

        managers.skilltree:_aquire_points(managers.skilltree:max_points_for_current_level())
    end)
elseif RequiredScript == "lib/managers/menu/infamytreeguinew" then
    Hooks:PostHook(InfamyTreeGui, "_setup", "InfamyTreeGui_Setup", function(self)
        if self._can_go_infamous and not MenuCallbackHandler:can_become_infamous() then
            local button = self.infamous_panel:child("go_infamous_button")
            button:child("go_infamous_text"):set_color(tweak_data.screen_colors.item_stage_3)

            self._can_go_infamous = false
        end
    end)
end
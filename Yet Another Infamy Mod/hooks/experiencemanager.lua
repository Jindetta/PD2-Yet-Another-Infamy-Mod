local Self = YAIMod
Self.register("ExperienceManager", "_set_next_level_data", "get_xp_dissected", "current_level")

function ExperienceManager:_set_next_level_data(level)
    if self:can_level_up_normally() then
        Self.call("ExperienceManager", "_set_next_level_data", self, level)
    else
        self:set_initial_level_data()
    end
end

function ExperienceManager:get_xp_dissected(...)
    local total_xp, data = Self.call("ExperienceManager", "get_xp_dissected", self, ...)

    if not self:can_level_up_normally() then
        local penalty_xp = self:calculate_total_penalty(total_xp)

        data.bonus_low_level = math.floor(data.bonus_low_level - penalty_xp)
        total_xp = math.floor(total_xp - penalty_xp)
    end

    return total_xp, data
end

function ExperienceManager:current_level()
    return self:get_base_level(Self.call("ExperienceManager", "current_level", self))
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

-- Additional functions

function ExperienceManager:set_initial_level_data()
    local required_level = Self.clamp_level(self:get_base_level(0) + 1)
    local required_xp, current_xp = Self.get_xp(required_level), self:total()

    self._global.next_level_data = {}
    self:_set_next_level_data_points(Application:digest_value(required_xp, true))
    self:_set_next_level_data_current_points(current_xp)

    if self._experience_progress_data then
        table.insert(self._experience_progress_data, {
            level = required_level,
            current = current_xp,
            total = required_xp
        })
    end
end

function ExperienceManager:get_base_level(start_level)
    local current_rank = self:current_rank()

    if current_rank > Self.MIN_INFAMY_REQUIREMENT then
        start_level = math.max(current_rank, start_level)
    end

    return Self.clamp_level(start_level)
end

function ExperienceManager:get_penalty(base_offset)
    return 0.1 - Self.clamp_level(self:get_base_level(0) + base_offset - 50) / 1000
end

function ExperienceManager:calculate_total_penalty(base_points)
    local needed_points = self:next_level_data_points() - self:next_level_data_current_points()
    local total_penalty_points = base_points * self:get_penalty(0)

    if base_points - total_penalty_points > needed_points then
        return needed_points * self:get_penalty(0)
    end

    return total_penalty_points
end

function ExperienceManager:can_rank_up()
    return self:current_rank() <= Self.MIN_INFAMY_REQUIREMENT or self:total() >= Self.get_xp(Self.MAX_LEVEL)
end

function ExperienceManager:can_level_up_normally()
    if self:current_rank() > Self.MIN_INFAMY_REQUIREMENT then
        local level = Self.call("ExperienceManager", "current_level", self)

        local required_level = Self.clamp_level(self:get_base_level(0) + 1)
        local required_xp = Self.get_xp(required_level)

        return level >= required_level and self:total() >= required_xp
    end

    return true
end
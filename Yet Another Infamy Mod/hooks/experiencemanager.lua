local Self = YAIMod
Self.register("ExperienceManager", "_set_next_level_data", "get_xp_dissected", "current_level")

function ExperienceManager:_set_next_level_data(level)
    if self:can_level_up_normally() then
        Self.call("ExperienceManager", "_set_next_level_data", self, level)
    else
        self._global.next_level_data = {}
        local needed_xp = Self.get_xp(level)
        local current_xp = self:total()

        self:_set_next_level_data_points(Application:digest_value(needed_xp, true))
        self:_set_next_level_data_current_points(current_xp)

        if self._experience_progress_data then
            table.insert(self._experience_progress_data, {
                level = Self.clamp_level(level),
                current = current_xp,
                total = needed_xp
            })
        end
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

function ExperienceManager:get_base_level(start_level)
    local current_rank = self:current_rank()

    if current_rank > Self.MIN_INFAMY_REQUIREMENT then
        start_level = math.max(current_rank, start_level)
    end

    return Self.clamp_level(start_level)
end

function ExperienceManager:get_penalty()
    return math.max(0, self:get_base_level(0) - 50) / 1000 + 0.15
end

function ExperienceManager:calculate_total_penalty(base_points)
    local needed_points = self:next_level_data_points() - self:next_level_data_current_points()
    local total_penalty_points = base_points * self:get_penalty()

    if needed_points < total_penalty_points then
        return needed_points * self:get_penalty()
    end

    return total_penalty_points
end

function ExperienceManager:can_rank_up()
    return self:current_rank() <= Self.MIN_INFAMY_REQUIREMENT or self:total() >= Self.get_xp(Self.MAX_LEVEL)
end

function ExperienceManager:can_level_up_normally()
    if self:current_rank() > Self.MIN_INFAMY_REQUIREMENT then
        local level = Self.call("ExperienceManager", "current_level", self)

        local required_level = self:get_base_level(0)
        local required_xp = Self.get_xp(required_level + 1)

        return level >= required_level and self:total() >= required_xp
    end

    return true
end
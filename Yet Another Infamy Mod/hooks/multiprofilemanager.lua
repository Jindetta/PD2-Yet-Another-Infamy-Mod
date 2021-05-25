local Self = YAIMod
Self.register("MultiProfileManager", "infamy_reset")

function MultiProfileManager:infamy_reset()
    if managers.experience:current_rank() < Self.MAX_LEVEL then
        Self.call("MultiProfileManager", "infamy_reset", self)
    end
end
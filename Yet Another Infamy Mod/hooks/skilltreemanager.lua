local Self = YAIMod
Self.register("SkillTreeManager", "infamy_reset")

function SkillTreeManager:infamy_reset()
    if managers.experience:current_rank() < Self.MAX_LEVEL then
        Self.call("SkillTreeManager", "infamy_reset", self)
    end
end
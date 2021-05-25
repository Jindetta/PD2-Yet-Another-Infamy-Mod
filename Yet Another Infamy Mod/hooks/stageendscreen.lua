local Self = YAIMod
Self.register("HUDStageEndScreen", "stage_experience_end")

function HUDStageEndScreen:stage_experience_end(t, dt)
    Self.call("HUDStageEndScreen", "stage_experience_end", self, t, dt)

    if MenuCallbackHandler:is_level_100() then
        if managers.experience:current_rank() >= Self.MAX_LEVEL then
            managers.menu_component:post_event("stinger_levelup")
            self._lp_circle:set_color(Color.red)
            self._lp_text:set_color(Color.red)
        end
    end
end
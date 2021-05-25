local Self = YAIMod
Self.register("InfamyTreeGui", "_setup")

function InfamyTreeGui:_setup(...)
    Self.call("InfamyTreeGui", "_setup", self, ...)

    if self._can_go_infamous then
        if not MenuCallbackHandler:can_become_infamous() then
            local button = self.infamous_panel:child("go_infamous_button")
            button:child("go_infamous_text"):set_color(tweak_data.screen_colors.item_stage_3)

            self:create_experience_error_text(button)
            self._can_go_infamous = false
        end
    end
end

-- Additional functions

function InfamyTreeGui:create_experience_error_text(button)
    self.infamous_panel:text({
        text = managers.localization:text("error_not_enough_experience", {xp = self:experience_string()}),
        font_size = tweak_data.menu.pd2_small_font_size,
        font = tweak_data.menu.pd2_small_font,

        color = Color.red,
        align = "center",
        wrap = true,
        layer = 3,

        w = self.infamous_panel:w() - 80,
        y = button:bottom(),
        x = 40
    })
end

function InfamyTreeGui:experience_string()
    local remaining_xp = Self.get_xp(Self.MAX_LEVEL) - managers.experience:total()

    return managers.experience:experience_string(remaining_xp)
end
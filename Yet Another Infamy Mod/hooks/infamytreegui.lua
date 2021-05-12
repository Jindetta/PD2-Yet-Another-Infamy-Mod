local Self = YAIMod
Self.register("InfamyTreeGui", "_setup")

function InfamyTreeGui:_setup(...)
    Self.call("InfamyTreeGui", "_setup", self, ...)

    if self._can_go_infamous then
        if not MenuCallbackHandler:can_become_infamous() then
            local button = self.infamous_panel:child("go_infamous_button")
            button:child("go_infamous_text"):set_color(tweak_data.screen_colors.item_stage_3)

            self._can_go_infamous = false
        end
    end
end
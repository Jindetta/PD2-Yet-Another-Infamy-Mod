if not YAIMod then
    local Self = {
        MAX_LEVEL = 100,
        MIN_INFAMY_REQUIREMENT = 25,
        HOOK_PATH = ModPath .. "hooks/%s.lua"
    }

    function Self.get_xp(level)
        local total_xp = 0

        for i = 1, math.min(level, Self.MAX_LEVEL) do
            total_xp = total_xp + tweak_data:get_value("experience_manager", "levels", i, "points")
        end

        return math.min(23336413, math.floor(total_xp))
    end

    function Self.clamp_level(level)
        return math.clamp(level, 0, Self.MAX_LEVEL)
    end

    function Self.register(hook_class, ...)
        if type(_G[hook_class]) == "table" then
            for _, hook_name in ipairs({...}) do
                local hook_func = _G[hook_class][hook_name]

                if type(hook_func) == "function" then
                    Self._hooks = Self._hooks or {}

                    local entry = Self.get_entry(hook_class, hook_name)
                    Self._hooks[entry] = hook_func
                end
            end
        end
    end

    function Self.call(class_entry, function_entry, ...)
        if type(Self._hooks) == "table" then
            local hook_func = Self._hooks[Self.get_entry(class_entry, function_entry)]

            if type(hook_func) == "function" then
                return hook_func(...)
            end
        end

        return nil
    end

    function Self.get_entry(class_entry, function_entry)
        return ("%s::%s"):format(class_entry, function_entry)
    end

    function Self.setup(hook)
        local scripts = {
            ["lib/managers/menu/infamytreeguinew"] = "infamytreegui",
            ["lib/managers/experiencemanager"] = "experiencemanager",
            ["lib/managers/menumanager"] = "menumanager"
        }

        if scripts[hook] then
            dofile(Self.HOOK_PATH:format(scripts[hook]))
        end
    end

    Hooks:Add("LocalizationManagerPostInit", "YAIMod_LocalizationManagerPostInit", function(self)
        self:add_localized_strings({
            ["error_not_enough_experience"] = "You need to get $xp experience points",
            ["dialog_become_infamous_modded_text"] = [[Starting from Infamy 3.0 ranks (25+) your reputation level no longer starts from 0 after going infamous. Your Infamy rank will become your reputation level instead.

Your current loadout will be reset (including first skill set, primary/secondary weapon, melee, throwable and deployable) but you get to keep your unlocks and skill points up to your initial reputation level.

You cannot level up until you gain the total amount of experience points that your reputation level would normally require. Also, gained XP will be reduced by $penalty% until you level up. Penalty is shown as level reduction during end screen.

This is irreversible, and you CAN NOT get back what you sacrifice.

You get to keep all your guns, mods, masks, patterns and materials. The cash in your offshore account will remain. You will gain one rank of Infamy, if you are at infamy rank 100 or below you will also get an Infamy reward.]]
        })
    end)

    YAIMod = Self
end

YAIMod.setup(RequiredScript)
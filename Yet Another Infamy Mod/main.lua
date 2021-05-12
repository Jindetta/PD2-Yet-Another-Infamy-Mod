if not YAIMod then
    local Self = {
        MAX_LEVEL = 100,
        MIN_INFAMY_REQUIREMENT = 25,
        HOOK_PATH = ModPath .. "hooks/%s.lua",
        LANG_PATH = ModPath .. "lang/%s.json"
    }

    function Self.get_xp(level)
        local total_xp = 0

        for i = 1, math.min(level, Self.MAX_LEVEL) do
            total_xp = total_xp + tweak_data:get_value("experience_manager", "levels", i, "points")
        end

        return math.min(23336413, math.floor(total_xp))
    end

    function Self.clamp_level(level)
        return math.max(0, math.min(level, Self.MAX_LEVEL))
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

    YAIMod = Self
end

YAIMod.setup(RequiredScript)
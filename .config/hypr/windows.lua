local suppressMaximizeRule = hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

local function maximizeJetBrainsWelcome(window)
    if not window then
        return
    end

    if not window.class:match("^jetbrains%-.*$") then
        return
    end

    if not window.title:match("^Welcome to .*$") then
        return
    end

    -- Static maximize rules only see the initial title. React to live title changes
    -- so the same JetBrains frame can maximize correctly when it returns to welcome.
    hl.dispatch(hl.dsp.window.fullscreen({
        mode = "maximized",
        action = "set",
        window = window,
    }))
end

hl.on("window.open", maximizeJetBrainsWelcome)
hl.on("window.title", maximizeJetBrainsWelcome)
hl.on("window.class", maximizeJetBrainsWelcome)

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- hl.window_rule({
--   name = "gsr-ui-windowed-fullscreen",
--   match = { class = "^gsr-ui$" },
--  
--   float = true,
--   no_blur = true,
--   move = {0, 0},
--   size = "monitor_w monitor_h",
--   fullscreen_state = "0 2",
--   sync_fullscreen = false
-- })
-- 
-- hl.window_rule({ match = { class = "firefox" }, no_blur = true })

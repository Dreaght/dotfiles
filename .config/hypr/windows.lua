local suppressMaximizeRule = hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    -- JetBrains welcome windows often re-request maximize after closing a project.
    -- Let those events through so the window can resize itself properly.
    match = { class = "negative:^jetbrains-.*$" },

    suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

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

hl.window_rule({ match = { class = "firefox" }, no_blur = true })

-- Fix jetbrains IDEs
hl.window_rule({
    match = {
        initial_class = "^jetbrains-.*",
        initial_title = "^Welcome to .*",
    },
    suppress_event = "fullscreen"
})

hl.window_rule({
    match = { class = "^(org.qbittorrent.qBittorrent)$" },
    workspace = "10 silent"
})


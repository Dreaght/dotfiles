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

hl.window_rule({
  name = "gsr-ui-windowed-fullscreen",
  match = { class = "^gsr-ui$" },
 
  float = true,
  no_blur = true,
  move = {0, 0},
  size = "monitor_w monitor_h",
  fullscreen_state = "0 2",
  sync_fullscreen = false
})

hl.window_rule({ match = { class = "firefox" }, no_blur = true })

hl.window_rule({
  name = "jetbrains",
  match = {
    class = "^jetbrains-.*$",
    title = "^Welcome to .*$",
  },
  maximize = true,
})

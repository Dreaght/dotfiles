return {
  terminal = "kitty",
  fileManager = "thunar",
  menu = "rofi -show drun",
  clipboard = "/bin/sh -c 'selection=\"$(cliphist list | rofi -dmenu -display-columns 2)\" || exit 0; [ -n \"$selection\" ] || exit 0; printf \"%s\n\" \"$selection\" | cliphist decode | wl-copy'",
  lock = "pidof hyprlock || hyprlock",
  browser = "zen-browser"
}

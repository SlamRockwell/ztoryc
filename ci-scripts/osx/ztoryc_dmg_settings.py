"""dmgbuild settings: styled Ztoryc DMG without Finder at build time."""

import os.path

# Injected by dmgbuild from the command line (-D app=... -D bg=...).
application = defines["app"]  # noqa: F821
_background = defines["bg"]  # noqa: F821

format = "UDZO"
compression_level = 9

files = [application]
symlinks = {"Applications": "/Applications"}

background = _background if os.path.isfile(_background) else "#ffffff"

icon_locations = {
    "Ztoryc.app": (200, 220),
    "Applications": (620, 220),
}

# Sized to roughly match the 1200×700 rendered background aspect ratio
window_rect = ((80, 100), (900, 525))
default_view = "icon-view"
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False

include_icon_view_settings = "auto"
include_list_view_settings = "auto"

arrange_by = None
grid_offset = (0, 0)
grid_spacing = 80
scroll_position = (0, 0)
label_pos = "bottom"
text_size = 13
icon_size = 128

show_icon_preview = False

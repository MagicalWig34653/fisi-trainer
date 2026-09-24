"""Finder layout for the FiSi Trainer distribution disk image."""

import os

application = defines["app"]
background_image = defines["background"]

format = "UDZO"
filesystem = "HFS+"
files = [application]
symlinks = {"Programme": "/Applications"}

app_icon = os.path.join(application, "Contents", "Resources", "AppIcon.icns")
icon = app_icon if os.path.isfile(app_icon) else None

# dmgbuild combines this image with the sibling @2x PNG into a HiDPI TIFF.
background = background_image
window_rect = ((180, 120), (760, 560))
default_view = "icon-view"
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
include_icon_view_settings = True
show_icon_preview = False

icon_size = 104
text_size = 13
label_pos = "bottom"
icon_locations = {
    "FiSiTrainer.app": (190, 250),
    "Programme": (570, 250),
    # Keep supporting files out of view even when Finder shows hidden files.
    ".background.tiff": (1100, 160),
    ".VolumeIcon.icns": (1100, 300),
    ".DS_Store": (1100, 440),
    ".fseventsd": (1100, 580),
}

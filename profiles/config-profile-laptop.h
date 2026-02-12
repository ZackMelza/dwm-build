#ifndef PROFILE_EXTRA_KEYS
#define PROFILE_EXTRA_KEYS \
	{ 0, XF86XK_MonBrightnessUp, spawn, SHCMD("brightnessctl set +10%") }, \
	{ 0, XF86XK_MonBrightnessDown, spawn, SHCMD("brightnessctl set 10%-") }, \
	{ 0, XF86XK_Sleep, spawn, SHCMD("systemctl suspend") }, \
	{ 0, XF86XK_PowerOff, spawn, SHCMD("dwm-power-menu.sh") }, \
	{ Mod1Mask|ShiftMask, XK_Tab, spawn, SHCMD("setxkbmap -layout us,gr -variant , -option grp:alt_shift_toggle; pkill -RTMIN+2 dwmblocks") },
#endif

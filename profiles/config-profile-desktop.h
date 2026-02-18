#ifndef PROFILE_EXTRA_KEYS
#define PROFILE_EXTRA_KEYS \
	{ 0, XF86XK_Display, spawn, SHCMD("command -v arandr >/dev/null 2>&1 && arandr || true") }, \
	{ MODKEY|ControlMask, XK_p, spawn, SHCMD("pkill -x picom || start-picom.sh") },
#endif

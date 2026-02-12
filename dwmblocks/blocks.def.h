// Copy this to blocks.h in your dwmblocks source tree.

static const Block blocks[] = {
  // Icon, command, interval (s), signal
  {"VOL ", "~/.config/dwmblocks/scripts/volume.sh", 0, 1},
  {"NET ", "~/.config/dwmblocks/scripts/network.sh", 5, 2},
  {"CPU ", "~/.config/dwmblocks/scripts/cpu.sh", 5, 3},
  {"MEM ", "~/.config/dwmblocks/scripts/memory.sh", 5, 4},
  {"DISK ", "~/.config/dwmblocks/scripts/disk.sh", 60, 5},
  {"BAT ", "~/.config/dwmblocks/scripts/battery.sh", 15, 6},
  {"UPD ", "~/.config/dwmblocks/scripts/updates.sh", 1800, 7},
  {"", "~/.config/dwmblocks/scripts/date.sh", 1, 0},
};

static char delim[] = " | ";
static unsigned int delimLen = 3;

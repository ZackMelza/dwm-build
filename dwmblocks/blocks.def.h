// Copy this to blocks.h in your dwmblocks source tree.

static const Block blocks[] = {
  // Icon, command, interval (s), signal
  {"⏻  ", "~/.config/dwmblocks/scripts/power.sh", 0, 8},
  {"󰕾  ", "~/.config/dwmblocks/scripts/volume.sh", 0, 1},
  {"󰖩  ", "~/.config/dwmblocks/scripts/network.sh", 5, 2},
  {"  ", "~/.config/dwmblocks/scripts/cpu.sh", 5, 3},
  {"  ", "~/.config/dwmblocks/scripts/memory.sh", 5, 4},
  {"󰋊  ", "~/.config/dwmblocks/scripts/disk.sh", 30, 5},
  {"󰁹  ", "~/.config/dwmblocks/scripts/battery.sh", 30, 6},
  {"󰏖  ", "~/.config/dwmblocks/scripts/updates.sh", 1800, 7},
  {"  ", "~/.config/dwmblocks/scripts/date.sh", 1, 0},
};

static char delim[] = "   ";
static unsigned int delimLen = 3;

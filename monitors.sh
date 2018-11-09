#!/bin/bash

IN="eDP1"
EXT=$(xrandr | awk '/^(VGA1|HDMI1|HDMI2|DP1|DP2) connected/{print $1}')
CONFIG="${HOME}/.config/i3/config"

display_usage() { 
	echo -e "\nOptions for monitors:"
	echo -e "-h show this message\n-c clone\n-e external only\n-i internal only\n-p <orientation of ext monitor> presentation mode\n\nOrientation options same as xrand:\n--above, --below, --right-of, --left-of\nWhen switching to modes different than internal, it may be needed to switch to internal as an intermediate step.\n"
} 

# Returns 1 if proper orientation value for xrandr supplied;
# returns 0 otherwise.
check_orientation() {
  case ${1} in
    --above)
      ;;
    --below)
      ;;
    --left-of)
      ;;
    --right-of)
      ;;
    *)
      return 0
      ;;
  esac
  return 1
}

if ! [[ -x "$(command -v xrandr)" ]]; then
  echo "Error: xrandr is not installed." >&2
  exit 1
fi

if [[ $# -lt 1 || $# -gt 2 ]]
then
  echo "Error: exactly one argument is required.\n" >&2
  display_usage
  exit 1
fi

if [[ "$(echo -n "$EXT" | grep -c '^')" -eq 0 ]]; then
  echo "Error: no external monitor detected." >&2
  exit 1
fi

if [[ $(echo -n "$EXT" | grep -c '^') -gt 1 ]]; then
  echo "Error: more than one external monitor detected." >&2
  exit 1
fi

# Passing only -p (without the required argument) will cause the
# -p conditional in getopts below to NOT be triggered. Hence must
# check that case here.
if [[ $# -eq 1 && "$1" = "-p" ]]
then
  echo "-p requires argument: --above, --below, --right-of, --left-of" >&2
  exit 1
fi

while getopts ":cehip:" opt; do
	case $opt in
    c)
      sed 's/^set\s$DEFAULT\s.*/set $DEFAULT '$IN'/' -i $CONFIG
      sed 's/^set\s$OUTPUT\s.*/set $OUTPUT 'NONE'/' -i $CONFIG
			xrandr --output $IN --primary --auto --output $EXT --auto --same-as $IN
      i3-msg restart
      ;;
    e)
      sed 's/^set\s$DEFAULT\s.*/set $DEFAULT '$EXT'/' -i $CONFIG
      sed 's/^set\s$OUTPUT\s.*/set $OUTPUT 'NONE'/' -i $CONFIG
      # Switch off internal monitor (which always exists), just to be sure.
			xrandr --output $IN --off --output $EXT --primary --auto
      i3-msg restart
      ;;
		h)
			display_usage
			exit 0
			;;
		i)
      sed 's/^set\s$DEFAULT\s.*/set $DEFAULT '$IN'/' -i $CONFIG
      sed 's/^set\s$OUTPUT\s.*/set $OUTPUT 'NONE'/' -i $CONFIG
      # xrandr explicitly disables all external outputs, if any, just to make sure.
      CMD="xrandr --output $IN --primary --auto"
      [[ ! -z $EXT ]] && CMD+=" --output $EXT --off"
      eval ${CMD}
      i3-msg restart
			;;
		p)
      sed 's/^set\s$DEFAULT\s.*/set $DEFAULT '$IN'/' -i $CONFIG
      sed 's/^set\s$OUTPUT\s.*/set $OUTPUT '$EXT'/' -i $CONFIG
      ORIENTATION="${OPTARG}"
      check_orientation ${ORIENTATION}
      if [[ $? -eq 0 ]]
      then
        echo "Wrong orientation option. See -h for help."
        exit 1
      fi
			xrandr --output $IN --primary --auto --output $EXT --auto $ORIENTATION $IN
      i3-msg restart
			;;
    \?)
      echo "Wrong option (-h for help)."
      ;;
  esac
done

# Notes:
# 
# Restarting (instead of reloading) i3 is only needed when changing the place
# of the tray might be required. I.e., with -i and -e. See also:
# https://github.com/i3/i3/issues/1329


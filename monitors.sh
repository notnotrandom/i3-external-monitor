#!/bin/bash

# Check pre-requisites.

# Setting EXT variable requires xrandr, so must check for it first.
if ! [[ -x "$(command -v xrandr)" ]]; then
  echo "Error: xrandr is not installed." >&2
  exit 1
fi

# THIS VAR MUST BE SET BY THE USER, MANUALLY!
IN="eDP1"

# To detect external monitor, capture (from xrandr output) all the connected
# ones, and filter out the internal one.
# NB: if there is more than one external monitor connected, we will detect the
# first one, as ordered by xrandr's output.
all_connected_monitors=$(xrandr | sed -n 's/^\(.\+\) connected .*/\1/p') # string
EXT=""
for i in $all_connected_monitors ; do
  if [[ "$i" != "$IN" ]] ; then
    EXT+="$i"
    echo "Detected external monitor: $EXT"
    break
  fi
done

CONFIG="${HOME}/.config/i3/config"

# Check if there are any external monitors connected (unless -i is given: we
# don't need external monitors to setup just the internal one).
if [[ "$1" != "-i" && $(echo -n "$EXT" | grep -c '^') -eq 0 ]]; then
  echo "Error: no external monitor detected." >&2
  exit 1
fi

# Pre-requisites check finished.
# Check arguments.

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

if [[ $# -lt 1 || $# -gt 2 ]]
then
  echo "Error: at least one and at most two arguments required.\n" >&2
  display_usage
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

# Arguments check finished.
# Now process them, i.e. actually set up the external monitor.

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

      # Have xrandr explicitly disable all external outputs (connected or not),
      # just to make sure. This is needed, for example, when the user
      # disconnects the external monitor *before* disabling it through xrandr.

      # This yields a string with the names of all detected monitors.
      all_monitors=$(xrandr | sed -n 's/^\(.\+\) \(dis\)*connected .*/\1/p')

      # Remove the internal monitor from that string.
      all_external_monitors=""
      for i in $all_monitors ; do
        if [[ "$i" != "$IN" ]] ; then
          all_external_monitors+="$i "
        fi
      done

      # Build xrandr command to disable all external monitors.
      cmd="xrandr --output $IN --primary --auto"
      for i in $all_external_monitors ; do
        cmd+=" --output $i --off"
      done
      eval ${cmd} # Run that command, which disables all external outputs.

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
# of the tray might be required. I.e., with -i and -e. However, to keep it simple,
# I do it on every change (changing monitor layout should happen infrequently, so
# this is not a big problem).


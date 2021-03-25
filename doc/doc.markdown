# i3-external-monitor

Being an awesome minimalist tilling window manager, the minimalism part means that some things in [`i3`](https://i3wm.org/)---like dealing with external monitors---are left to the user. This is how I handle it.

The `monitors.sh` script assumes there is **always** one *internal* monitor (in a laptop this would be the integrated display), and a list of external displays (VGA, HDMI, etc), **at most one of which** might be connected. It wraps the relevant `xrand` commands and changes to `i3`'s config file, for the following scenarios:

- *Internal monitor only* (**-i** argument): disables all external outputs (connected or otherwise), if any, leaving as active only the internal monitor (in laptops, I set this to the laptop's own monitor, usually `eDP1` or similar). Any windows placed on the external display will be moved to the internal one.

- *External monitor only* (**-e** argument): disables the internal monitor, and uses only the external one. If there is more than one external monitor connected, it uses the first one in the list, as per `xrand`'s ordering.

- *Clone internal monitor to external one* (**-c** argument): clones the internal display to the external one.

- *Presentation mode* (**-p** argument): uses the two monitors, and requires another argument --- one of `--above`, `--below`, `--right-of` or `--left-of` --- which is the position of the external monitor relative to the internal one.

**NOTA BENE**: if you do an `-e`, and then a`-p`, settings will be configured properly, **but all existing windows will be left showning on the external monitor**.

## Setup

I assume that you have `i3` properly configured. The first step is to run `xrandr` without arguments, in order to get a listing of connection ports (something like VGA1, DP1, HDMI1, ...). You must detect the name of the port where your internal monitor is connected, and replace the value of the `IN` shell variable (line 12 of `monitors.sh` script) with that detected value. For example:

~~~ {.config .numberLines}
IN="eDP1"
~~~

Next, add the following anywhere in `i3`'s main config file (`~/.config/i3/config` for me; I usually put the variables near the beginning):

~~~ {.config .numberLines}
# For monitor switching.
set $DEFAULT eDP1
set $OUTPUT NONE
~~~

Replace `eDP1` with the same value used for the `IN` variable above.

**NOTA BENE**: *never* set both `$DEFAULT` and `$OUTPUT` to the same value! All kinds of gremlins will ensue otherwise, together with a lot of flickr, as `i3` will keep setting the one and only existing display, to one configuration, then to the other, then back to the first, ...

**Roles of each variable.** (This paragraph may be skipped on a first reading.) In presentation mode (**-p**), which is the only mode where there are two active monitors displaying different content, the `$DEFAULT` variable points to the internal monitor, and the `$OUTPUT` to the external one. This allows setting shortcuts for moving whole workspaces from one output to the other, and also to have different configurations for the status bar/tray icons in each screen (see the section "Extras", below). In all other scenarios `$OUTPUT` is set to the dummy value `NONE` (causing `i3` to ignore the respective config blocks), and `$DEFAULT` is set to either the internal monitor (when using only this monitor, or when cloning, i.e. **-i** or **-c**), or to the external monitor (when using only this monitor, i.e. **-e**). **End.**

The following shortcuts are not strictly necessary, but become rather handy:

~~~ {.text .numberLines}
# move workspace to default output...
bindsym $mod+m move workspace to output $DEFAULT
# move workspace to external output...
bindsym $mod+Shift+m move workspace to output $OUTPUT
~~~

And we are **done**! To setup an external monitor in presentation mode, say, do:

~~~ {.shell .numberLines}
$ sh /path/to/monitors.sh -p --above
~~~

To return to just using the internal monitor (works even if you unplugged the external one, without disabling it first):

~~~ {.shell .numberLines}
$ sh /path/to/monitors.sh -i
~~~

Enjoy!

## Extras

The required config is now done. However, it is very convenient to use an alias; if you use `bash`:

~~~ {.shell .numberLines}
alias monitors="sh /path/to/monitors.sh"
~~~

Still for `bash`, you can enable completion by placing the following in `.bashrc` (change `~/.bash_completion.d/` to anything of your liking; don't forget to create it if necessary):

~~~ {.shell .numberLines}
if test -d ~/.bash_completion.d/; then
	for profile in ~/.bash_completion.d/*.sh; do
		test -r "$profile" && . "$profile"
	done
	unset profile
fi
~~~

Now dump the following in a file named `monitors.sh` in that directory:

~~~ {.shell .numberLines}
_monitors()
{
	if [[ $COMP_CWORD -eq 1 ]]; then
		WORDS="-i -e -p -c -h"
	elif [[ $COMP_CWORD -eq 2 ]]; then
		WORDS="--above --below --left-of --right-of"
	fi
	local cur=${COMP_WORDS[COMP_CWORD]}
	COMPREPLY=( $(compgen -W "$WORDS" -- $cur) )
}
complete -F _monitors monitors ./monitors.sh
~~~

Now you will have (after re-souring `.bashrc`) completion, even when invoking the command as `$ monitors`, i.e. as a `bash` alias.

Finally, when in presentation mode, I like to show, in the external monitor, a bar with less information than what I use for my internal monitor (and no tray icons). To achieve this, we use an extra `bar { }` block, in `i3`'s config:

~~~ {.text .numberLines}
bar {
  output                $DEFAULT
  tray_output           $DEFAULT
  status_command        i3status -c ~/.config/i3/i3status.conf

  ... rest of your regular bar settings here...
}

bar {
  output                $OUTPUT
  tray_output           none
  status_command        i3status -c ~/.config/i3/i3status-external-output.conf

  ... rest of your (perhaps more restricted) bar settings here...
}
~~~

Here `i3status.conf` is the regular status bar config, and `i3status-external-output.conf` is the restricted one (basically the same, but with some items suppressed --- e.g. network information, etc.).

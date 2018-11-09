# A reliable way to handle external monitors (in i3) #

Being an awesome minimalist tilling window manager, the minimalism part means that some things in `i3` --- like dealing with external monitors --- are left to the user. This is how I handle it.

The `monitors.sh` script assumes there is **always** one *internal* monitor (in a laptop this would be the integrated display), and optionally, **one** *external* display (connected through VGA, HDMI, etc). It wraps the relevant `xrand` commands and changes to `i3`'s config file, for the following scenarios:

- *Internal monitor only* (**-i** argument): disables the external output, if any, leaving as active only the one specified in the variable `IN`. In laptops, I set this to the laptop's own monitor (usually `eDP1` or similar).

- *External monitor only* (**-e** argument): disables the internal monitor, and uses only the external one.

- *Clone internal monitor to external one* (**-c** argument): clones the internal display to the external one.

- *Presentation mode* (**-p** argument): uses the two monitors, and requires another argument --- one of `--above`, `--below`, `--right-of` or `--left-of` --- which is the position of the external monitor relative to the internal one.

**NOTA BENE**: if you do `-p` after an `-e`, settings will be configured properly, **but all existing windows will be left showning on the external monitor**.

In order to be able to change the config file, the following variables had to be introduced:

~~~ {.config .numberLines}
# For monitor switching.
set $DEFAULT eDP1
set $OUTPUT NONE
~~~

In presentation mode, which is the only mode where there are two active monitors displaying different content, the `$DEFAULT` variable points to the internal monitor, and the `$OUTPUT` to the external one. This allows setting shortcuts for moving whole workspaces from one output to the other, and also to have different configurations for the status bar/tray icons in each screen (see below). In all other scenarios `$OUTPUT` is set to the dummy value `NONE` (causing `i3` to ignore the respective config blocks), and `$DEFAULT` is set to the internal monitor (when using only this monitor, or when cloning, i.e. **-i** or **-c**), or to the external monitor (when using only this monitor, i.e. **-e**).

I use them in the following two scenarios, in `i3`'s config file (others are possible). Moving between internal and external monitors (only useful in presentation mode):

~~~ {.text .numberLines}
# move workspace to default output...
bindsym $mod+m move workspace to output $DEFAULT
# move workspace to external output...
bindsym $mod+Shift+m move workspace to output $OUTPUT
~~~

Also for presentation mode, for the external monitor I disable tray icons and limit what is shown in the status bar:

~~~ {.text .numberLines}
bar {
  output                $DEFAULT
  tray_output           $DEFAULT
  status_command        i3status -c ~/.config/i3/i3status.conf
}

bar {
  output                $OUTPUT
  tray_output           none
  status_command        i3status -c ~/.config/i3/i3status-external-output.conf
}
~~~

Here `i3status.conf` is the regular status bar config, and `i3status-external-output.conf` is the restricted one (basically the same, but with some items suppressed --- e.g. network information, etc.).

**NOTA BENE**: never set both `$DEFAULT` and `$OUTPUT` to the same value! All kinds of gremlins will ensue otherwise, together with a lot of flickr, as `i3` keep setting the one and only existing display, to one configuration, then to the other, then back to the first, ...

## Setup

The first step is to run `xrandr` without arguments, in order to get a listing of connection ports (something like VGA1, DP1, HDMI1, ...). My assumption is that there will be a fixed set of ports to which external monitors are attached (this is always the case with laptops). Place those ports in the command that is used to defined the `EXT` variable (line 4, replacing the defaults, if needed). Note that error will ensue if there are more than one of those ports with monitors connected.

The required config is now done. However, it is very convenient to use an alias; if you use `bash`:

~~~ {.shell .numberLines}
alias monitors="sh /path/to/monitors.sh"
~~~

Still for `bash`, you can enable completion by placing the following in `.bashrc` (change `~/.bash_completion.d/` to anything of your liking; don't forget to create it):

~~~ {.shell .numberLines}
if test -d ~/.bash_completion.d/; then
	for profile in ~/.bash_completion.d/*.sh; do
		test -r "$profile" && . "$profile"
	done
	unset profile
fi
~~~

Now dump the following in a file name `monitors.sh` in that directory:

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

And we are **done**! Enjoy!

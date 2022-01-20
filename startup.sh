#!/bin/bash

sleep 3

firstrun=true
if [ "$1" = "auto" ]; then
	if test -e /tmp/.awesome_initialized; then
		firstrun=false
	fi
	touch /tmp/.awesome_initialized
fi

xmodmap /home/pjm0616/.Xmodmap
(sleep 5; xmodmap /home/pjm0616/.Xmodmap) &
(sleep 10; xmodmap /home/pjm0616/.Xmodmap) &

# https://awesomewm.org/awesome-www-backup-old/wiki/Problems_with_Java
# > Impersonate Another Window Manager
# > You may use the wmname utility to make the JVM believe you are running a different window manager. This utility is available in the suckless-tools package in Debian (and Ubuntu); this Portage tree provides wmname for Funtoo (and Gentoo).
# > $ wmname LG3D
# > (You must restart the application in question after issuing the wmname command.)
# > This works because the JVM contains a hard-coded list of known non-re-parenting window managers. For maximum irony, many users prefer to impersonate “LG3D,” the non-re-parenting window manager written by Sun, in Java.
# > This does not work for awesome since 3.5, as the JMenuBar is not tracked. The solution is to impersonate Sawfish using
# > $ wmname Sawfish
# Set window manager name to "Sawfish" to make some Java AWT apps work properly.
# Previously we've used "LG3D" but now we need to use "Sawfish" in order to make intellij work.
wmname Sawfish

# TODO: restart xautolock when $firstrun=false.
(cd /home/pjm0616/.config/awesome && tmux new -d -s xautolock && tmux send-keys -t xautolock '/home/pjm0616/.config/awesome/run-xautolock' 'C-m')

# Start gnome services.
case "$(lsb_release -s -c)" in
xenial)
	$firstrun && (
		unity-settings-daemon &
		nm-applet --sm-disable &
		#bluetooth-applet &
		#blueman-applet &
		#gnome-sound-applet &
		system-config-printer-applet &
	)
	;;

bionic)
	$firstrun && (
		unity-settings-daemon &
		nm-applet &
	)
	;;

focal)
	$firstrun && (
		unity-settings-daemon &
		nm-applet &
		gnome-screensaver &
		pasystray &
	)
	;;

*)
	echo "Unknown release: $(lsb_release -s -c)"
	;;
esac

case "$(hostname)" in
pjm0616-laptop)
	# DP is primary.
	xrandr --output DP-1 --primary
	# HDMI is secondary. Mirror display so that we can dynamically change the role of two monitors.
	xrandr --output HDMI-1 --same-as DP-1
	# ...or uncomment to use HDMI as separate display.
	#xrandr --output HDMI-1 --right-of DP-1

	# Switch the monitor to standby mode after 10 minutes.
	xset +dpms
	xset dpms 600 0 0

	# Periodically reset pulseaudio's default sink to my USB sound card.
	# Note that this is unnecessary with PulseAudio 9.0 or later - see https://www.freedesktop.org/wiki/Software/PulseAudio/Notes/9.0/#automaticroutingimprovements
	# After upgrading to Ubuntu bionic this should be removed.
	#tmux new -d -s pafix && tmux send-keys -t pafix 'while sleep 5; do pactl set-default-sink alsa_output.usb-Breeze_audio_SA9023_USB_Audio-01.analog-stereo; done' 'C-m'

	# IRCCloud persist daemon
	#(cd /home/pjm0616/bin && tmux new -d -s irccloud && tmux send-keys -t irccloud './irccloud-persist.py' 'C-m')

	$firstrun && (
		SSH_ASKPASS=/usr/bin/ssh-askpass ssh-add -c </dev/null &
	)
	;;

pjm0616-laptop3)
	# Don't turn off the monitor.
	#xset 0 0 0

	# MacBook Air 2012 touchpad
	xinput set-prop 'bcm5974' 'Synaptics Two-Finger Scrolling' 1 1

	# ibus doesn't seem to be autostarted after upgrading to focal.
	ibus-daemon -r -d &

	$firstrun && (
		SSH_ASKPASS=/usr/bin/ssh-askpass ssh-add -c </dev/null &
	)
	;;

daepodong)
	# Don't turn off the monitor.
	xset -dpms

	# Set monitor position.
	# DVI(rotated clockwise) - HDMI(primary) - DP
	xrandr --output HDMI-A-3 --primary --auto
	xrandr --output DisplayPort-2 --auto --right-of HDMI-A-3
	#xrandr --output DVI-D-0 --left-of HDMI-A-3 --rotate left --mode 1920x1200

	# ibus doesn't seem to be autostarted after upgrading to focal.
	ibus-daemon -r -d &
	;;

*)
	echo "Unknown host: $(hostname)"
	;;
esac

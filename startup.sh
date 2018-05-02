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
		gnome-settings-daemon &
	)
	;;

*)
	echo "Unknown release: $(lsb_release -s -c)"
	;;
esac

case "$(hostname)" in
pjm0616-laptop)
	# Thinkpad fan controller
	(cd /home/pjm0616/bin && tmux new -d -s tpfan && tmux send-keys -t tpfan '/home/pjm0616/bin/thinkfan_start' 'C-m')

	# Periodically reset pulseaudio's default sink to USB sound card.
	tmux new -d -s pafix && tmux send-keys -t pafix 'while sleep 5; do pactl set-default-sink alsa_output.usb-Breeze_audio_SA9023_USB_Audio-01.analog-stereo; done' 'C-m'

	# Twitter notifier
	tmux new -d -s twitter && tmux send-keys -t twitter 'while sleep 10; do userstream; date; done' 'C-m'

	# IRCCloud persist daemon
	(cd /home/pjm0616/bin && tmux new -d -s irccloud && tmux send-keys -t irccloud './irccloud-persist.py' 'C-m')

	$firstrun && (
		SSH_ASKPASS=/usr/bin/ssh-askpass ssh-add -c </dev/null &
		dropbox start &
	)
	;;

pjm0616-laptop3)
	# MacBook Air 2012 touchpad
	xinput set-prop 'bcm5974' 'Synaptics Two-Finger Scrolling' 1 1

	# For some reason ibus doesn't work without this.
	(sleep 3; killall ibus-daemon; ibus-daemon &) &

	$firstrun && (
		SSH_ASKPASS=/usr/bin/ssh-askpass ssh-add -c </dev/null &
		dropbox start &
	)
	;;

daepodong)
	;;

*)
	echo "Unknown host: $(hostname)"
	;;
esac

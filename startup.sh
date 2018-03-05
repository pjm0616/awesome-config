#!/bin/sh

if [ "$1" = "auto" ]; then
	if test -e /tmp/.awesome_initialized; then
		exit
	fi
	touch /tmp/.awesome_initialized
fi

#gnome-settings-daemon &
unity-settings-daemon &

xmodmap /home/pjm0616/.Xmodmap

tmux new -d -s xautolock && tmux send-keys -t xautolock 'cd /home/pjm0616/.config/awesome' 'C-m' '/home/pjm0616/.config/awesome/run-xautolock' 'C-m'
tmux new -d -s tpfan && tmux send-keys -t tpfan 'cd /home/pjm0616/bin' 'C-m' '/home/pjm0616/bin/thinkfan_start' 'C-m'

nm-applet --sm-disable &
#bluetooth-applet &
#blueman-applet &
#gnome-sound-applet &
system-config-printer-applet &
xinput set-prop 'bcm5974' 'Synaptics Two-Finger Scrolling' 1 1

SSH_ASKPASS=/usr/bin/ssh-askpass ssh-add -c </dev/null &

dropbox start &

tmux new -d -s twitter && tmux send-keys -t twitter 'while sleep 10; do userstream; date; done' 'C-m'
tmux new -d -s irccloud && tmux send-keys -t irccloud 'cd /home/pjm0616/bin' 'C-m' './irccloud-persist.py' 'C-m'

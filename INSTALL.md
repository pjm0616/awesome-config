### Required packages
```
apt install playerctl libnotify-bin xautolock pasystray python3-gi
#python3 -m pip install --user mpris_server
```

### setup fix-xmodmap
1. ln -s ../.config/awesome/fix-xmodmap ~/bin/
2. Create /etc/udev/rules.d/99-my-xmodmap-on-new-keyboard.rules as described by fix-xmodmap script.

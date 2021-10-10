#!/usr/bin/env python3
"""
Controls the media player using MPRIS protocol and fb2k command line.
When fb2k is Playing/Paused, it controls fb2k and pauses other MPRIS clients.
When fb2k is Stopped/not running, it controls MPRIS clients.

Note that it assumes 1) fb2k's executable name of "foobar2000.exe", and 2) a wrapper script for fb2k in $PATH.
The wrapper script should look like this:
> exec wine /home/pjm0616/.wine/drive_c/apps/foobar2000/foobar2000.exe "$@"
"""
import sys
import subprocess

def fb2k_active():
	"""Checks whether fb2k's status is Playing or Paused"""
	output = subprocess.check_output(['pactl', 'list', 'sink-inputs'], encoding='utf8')
	for entry in output.split('\n\n'):
		entry = entry.strip()
		if not entry.startswith('Sink Input #'):
			continue
		if '\t\tapplication.name = "foobar2000.exe"' in entry:
			return True
	return False

def mpris_cmd(cmd):
	output = subprocess.check_output(['playerctl', cmd], encoding='utf8').strip()
	return output

fb2k_cmdmap = {
	'play': '/play',
	'pause': '/pause',
	'play-pause': '/playpause',
	'stop': '/stop',
	'next': '/next',
	'previous': '/prev',

	# Note: this command is not present in playerctl - it's fb2k only.
	#'rand': '/rand',
}
def fb2k_cmd(cmd):
	fb2k_cmd = fb2k_cmdmap[cmd]
	subprocess.check_output(['foobar2000', fb2k_cmd], stderr=subprocess.DEVNULL, encoding='utf8')

if __name__ == '__main__':
	cmd = sys.argv[1]
	assert cmd in ['play', 'pause', 'play-pause', 'stop', 'next', 'previous']
	if fb2k_active():
		fb2k_cmd(cmd)
		if mpris_cmd('status') == 'Playing':
			mpris_cmd('pause')
	else:
		mpris_cmd(cmd)

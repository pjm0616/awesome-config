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
import re
import requests
import urllib.parse

# Use foo_beefweb component for controlling fb2k. (https://github.com/hyperblast/beefweb)
# Set to None to disable beefweb and fallback to fb2k command line.
# To use, 1) install foo_beefweb component, and 2) configure beefweb to listen on 127.0.0.1:12321 without auth.
fb2k_beefweb_url = 'http://127.0.0.1:12321'

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
	if cmd == 'random':
		return False
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
	'random': '/rand',
}
fb2k_apimap = {
	'play': '/play',
	'pause': '/pause',
	'play-pause': '/pause/toggle',
	'stop': '/stop',
	'next': '/next',
	'previous': '/previous',

	# Note: this command is not present in playerctl - it's fb2k only.
	'random': '/play/random',
}
def fb2k_beefweb_cmd(cmd):
	assert fb2k_beefweb_url
	path = fb2k_apimap[cmd]
	try:
		r = requests.post('%s/api/player%s' % (fb2k_beefweb_url, path), timeout=0.5)
	except requests.ConnectionError as err:
		return False
	if not r.ok:
		return False

def fb2k_beefweb_status():
	assert fb2k_beefweb_url
	try:
		r = requests.get('%s/api/player' % fb2k_beefweb_url, timeout=0.5)
	except requests.ConnectionError as err:
		return False
	if r.status_code != 200:
		return False
	data = r.json()
	status = data['player']['playbackState']
	status = {'playing': 'Playing', 'paused': 'Paused', 'stopped': 'Stopped'}[status]
	return status

def md_sanitize_str(s):
	return re.sub('[\x00\r\n]', '', s)

def fb2k_beefweb_metadata():
	assert fb2k_beefweb_url
	cols = ['album', 'artist', 'title', 'length']
	colreqstr = ','.join('%'+col+'%' for col in cols)
	try:
		r = requests.get('%s/api/player?columns=%s' % (fb2k_beefweb_url, urllib.parse.quote(colreqstr)), timeout=0.5)
	except requests.ConnectionError as err:
		return False
	if r.status_code != 200:
		return False
	data = r.json()
	active = data['player']['activeItem']
	fb2k_metadata = dict(zip(cols, active['columns']))

	# Convert metadata to mpris format.
	# See: https://www.freedesktop.org/wiki/Specifications/mpris-spec/metadata/
	mpris_metadata = {}
	for col in ['album', 'artist', 'title']:
		mpris_metadata['xesam:' + col] = md_sanitize_str(fb2k_metadata[col])
	if fb2k_metadata['length']:
		# Convert length in "5:00.123" form to usecs.
		m = re.match(r'^(\d+):(\d+)(\.\d+)?$', fb2k_metadata['length'])
		val = int(m.group(1)) * 60 + int(m.group(2))
		if m.group(3):
			val += float(m.group(3))
		val = int(val * 1000000)
		mpris_metadata['mpris:length'] = val

	player_name = 'foobar2000.exe'
	buf = []
	for key, val in mpris_metadata.items():
		buf.append('%s %s %s' % (player_name, key, val))
	return '\n'.join(buf)

def fb2k_native_cmd(cmd):
	fb2k_cmd = fb2k_cmdmap[cmd]
	subprocess.check_output(['foobar2000', fb2k_cmd], stderr=subprocess.DEVNULL, encoding='utf8')

def fb2k_cmd(cmd):
	if cmd == 'status':
		return fb2k_beefweb_status()
	if cmd == 'metadata':
		return fb2k_beefweb_metadata()

	ret = False
	if fb2k_beefweb_url:
		ret = fb2k_beefweb_cmd(cmd)
	if ret is False:
		ret = fb2k_native_cmd(cmd)
	return ret

def docmd(cmd):
	if fb2k_active():
		ret = fb2k_cmd(cmd)
		if mpris_cmd('status') == 'Playing':
			mpris_cmd('pause')
	else:
		ret = mpris_cmd(cmd)
	return ret

if __name__ == '__main__':
	cmd = sys.argv[1]
	assert cmd in [
		'play', 'pause', 'play-pause', 'stop', 'next', 'previous', 'status', 'metadata',
		'random', # fb2k only
	]
	ret = docmd(cmd)
	if ret:
		print(ret)
	if ret is False:
		sys.exit(1)

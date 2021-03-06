
local gametype
if os.getenv "SERVER"
	gametype = 'server'
elseif os.getenv "CLIENT"
	gametype = 'client'
else
	gametype = 'single_player'

player_name = (os.getenv "player") or "ludamad"

{
headless: false
server_ip: (os.getenv "IP") or 'localhost'
server_port: 6112
frames_per_second: 60
frames_per_second_csp: 50
use_cursor_sprite: true

:gametype
:player_name

regen_on_death: false

--Online settings
network_lockstep: true
username: 'User'
lobby_server_url: 'http://localhost:8080'

--Window settings
fullscreen: false
window_size: {800, 600}
frame_action_repeat: 0 -- 0 is ideal

--Font settings
font: 'Gudea-Regular.ttf'
menu_font: 'alagard_by_pix3m-d6awiwp.ttf'

--Debug settings
network_debug_mode: false
draw_diagnostics: false
verbose_output: false
keep_event_log: false

}

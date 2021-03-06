import abs, min, max, floor, ceil from math
import game_camera, display_size from require '@Display_components'
user_io = require "user_io"

local map_size, map_tile_size, map_tile_pixels -- Lazy imported

do 
	local map_state -- Last imported
	map_size = () -> 
		map_state = map_state or require "core.map_state"
		return map_state.map_size()
	map_tile_size = () -> 
		map_state = map_state or require "core.map_state"
		return map_state.map_tile_size()
	map_tile_pixels = () -> 
		map_state = map_state or require "core.map_state"
		return map_state.map_tile_pixels()

CAMERA_SUBW,CAMERA_SUBH = 100, 100
CAMERA_SPEED = 8

camera_wh = display_size

_get_components = (_x = nil, _y = nil, _w = nil, _h = nil) ->
	x, y = game_camera\getLoc()
	-- Do we have overrides for x & y?
	x, y = (_x or x), (_y or y)

	w, h = camera_wh()
	-- Do we have overrides for w & h?
	w, h = (_w or w), (_h or h)
	ww, wh = map_size()
	return x-w/2, y-h/2, w, h, ww, wh

-- Are we outside of the centre of the camera enough to warrant snapping the camera ?
camera_is_off_center = (px, py) ->
	x,y,width,height,world_width,world_height = _get_components()
	dx, dy = px - width /2 - x, py - height/2 - y

	return (abs(dx) > width / 2 or abs(dy) > height / 2)

camera_move_towards = (px, py, speed = CAMERA_SPEED) ->
	x,y,width,height,world_width,world_height = _get_components()

	dx, dy = px - x, py - y
	if (abs dx) > CAMERA_SUBW / 2 
		if px > x 
			x = min px - CAMERA_SUBW / 2, x + speed
		 else
			x = max px + CAMERA_SUBW / 2, x - speed
		x = max -width/2, (min world_width - width / 2, x)

	if (abs dy) > CAMERA_SUBH / 2 
		if py > y 
			y = min py - CAMERA_SUBH / 2, y + speed
		 else 
			y = max py + CAMERA_SUBH / 2, y - speed
		y = max -height/2, (min world_height - height / 2, y)

	-- Note, it is very bad to have the camera not on an integral boundary
	game_camera\setLoc(math.floor(x+width/2), math.floor(y+height/2))
	
camera_center_on = (px, py) ->
	x,y,width,height,world_width,world_height = _get_components()

	camera_move_towards(px - width / 2, py - height / 2)

camera_sharp_center_on = (px, py) ->
	print "sharp_center_on"
	x,y,width,height,world_width,world_height = _get_components()

	dx,dy = px - x, py - y
	if dx < width / 2
		dx = width / 2
	elseif dx > world_width - width / 2
		dx = world_width - width / 2

	if dy < height / 2
		dy = height / 2
	elseif dy > world_height - height / 2
		dy = world_height - height / 2

	-- Note, it is very bad to have the camera not on an integral boundary
	game_camera\setLoc(math.floor(px+dx  - width / 2), math.floor(py+dy - height / 2))

camera_move_delta = (dx, dy, speed = CAMERA_SPEED) ->
	x, y = _get_components()
	camera_move_towards(x + dx, y + dy, speed)

camera_region_covered = () ->
	x,y,width,height,world_width,world_height = _get_components()

	return x,y, x+width, x+height

camera_tile_region_covered = (_x = nil, _y = nil, _w = nil, _h = nil) ->
	x,y,width,height,world_width,world_height = _get_components(_x, _h, _w, _h)
	tw, th = map_tile_pixels()
	min_x = max(1, x / tw)
	min_y = max(1, y / th)
	max_x = (min(world_width, x + width)) / tw
	max_y = (min(world_height, y + height)) / th

	return (floor min_x), (floor min_y), (ceil max_x), (ceil max_y)

camera_rel_xy = (px, py) ->
	x, y = game_camera\getLoc()
	return px - x, py - y

camera_xy = () ->
	x, y = game_camera\getLoc()
	w, h = camera_wh()
	return x - w/2, y - h/2

mouse_game_xy = () ->
    mx,my = user_io.mouse_xy() 
    cx,cy = camera_xy()
    -- TODO Find out why this is so finnicky
    return mx+cx+64, my+cy

return {
	:camera_is_off_center, :camera_move_towards, :camera_center_on, :camera_sharp_center_on
	:camera_move_delta, :camera_region_covered, :camera_tile_region_covered, :camera_rel_xy, :camera_xy
	:camera_wh, :mouse_game_xy
}
res = require "resources"
util_draw = require "core.util_draw"

data = {
	-- Sprite data
	sprites: {}, 
	id_to_sprite: {}, 
	next_sprite_id: 1, 

	-- Tile data
	tiles: {}, 
	id_to_tile: {}, 
	next_tile_id: 1,

	-- Tile variation data
	id_to_tilelist: {},
	next_tilelist_id: 1, 

	-- Level data
	levels: {}, 
	id_to_level: {}
	next_level_id: 1, 
}

-------------------------------------------------------------------------------
-- Graphic and tileset data
-------------------------------------------------------------------------------

TileGrid = with newtype()
	.init = (w, h) => 
		@w, @h = w,h
		@grid = [0 for i=1,w*h]
	.set = (x, y, val) => 
		@grid[y * (@h-1) + x] = val
	.get = (x, y) => 
		@grid[y * (@h-1) + x]

-- Represents a single image sublocation
TexPart = with newtype()
	.init = (texture, x, y, w, h) =>
		@texture, @x, @y, @w, @h = texture, x, y, w, h
	.update_quad = (quad) =>
		texw, texh = @texture\getSize()
		with quad 
			\setTexture @texture
            \setUVRect @x/texw, @y/texh,
             	(@x+@w)/texw, (@y+@h)/texh
            -- Center tile on origin:
            \setRect -@w/2, -@h/2, 
                @w/2, @h/2

-- Represents a single tile
Tile = with newtype()
	.init = (id, grid_id, solid) => 
		@id, @grid_id, @solid= id, grid_id, solid 

-- Represents a list of variant tiles (from same tile-set)
TileList = with newtype()
	.init = (id, name, tiles, texfile) => 
		@id, @name, @tiles, @texfile = id, name, tiles, texfile

Sprite = with newtype()
	.init = (tex_parts, kind, w, h) => 
		@tex_parts, @kind, @w, @h = tex_parts, kind, w, h
	.update_quad = (quad, frame = 1) =>
		@tex_parts[frame]\update_quad(quad)
	.n_frames = () =>
		return #@tex_parts
	.get_quad = (frame = 1) =>
		quad = util_draw.get_quad()
		@update_quad(quad, (math.floor(frame)-1) % @n_frames() + 1)
		return quad
	.put_prop = (layer, x, y, frame, priority = 0) =>
		return with util_draw.put_prop(layer)
            \setDeck(@get_quad(frame))
            \setLoc(x, y)
            \setPriority(priority)

-------------------------------------------------------------------------------
-- Level data
-------------------------------------------------------------------------------

LevelData = with newtype()
	.init = (name, generator) => 
		@name, @generator = name, generator

-------------------------------------------------------------------------------
-- Part iteration
-------------------------------------------------------------------------------

-- Iterates numbered tiles
part_xy_iterator = (_from, to, id = 1) ->
	{minx,miny} = _from
	{maxx, maxy} = to
	-- Correct for first x += 1:
	x, y = minx - 1, miny
	-- Correct for first id += 1:
	id -= 1
	return () ->
		x, id = x + 1, id + 1
		if x > maxx then x, y = minx, y+1
		-- Finished
		if y > miny then return nil
		-- Valid
		return x, y, id

-- Wraps default values, to be used by chained .define statements
-- See modules/ folder for examples.
-- Eg, with tiledef <defaults>
--         .define <values1>
--         .define <values2>
define_wrapper = (func) ->
	return setmetatable {define: func}, { 
			-- Metatable, makes object callable
			-- when called, incorporate as 'defaults'
			__call: (defaults) =>
				return define: (values) ->
					copy = table.clone(defaults)
					table.merge(copy, values)
					return func(copy)
		}

TILE_WIDTH, TILE_HEIGHT = 32, 32

setup_define_functions = (fenv, module_name) ->
	-- Tile definition
	fenv.tiledef = define_wrapper (values) ->
		{:file, :solid, :name, :to} = values
		file = res.get_resource_path(file)
		_from = values["from"] -- skirt around Moonscript keyword

		-- Default to 1 tile
		to = to or _from

		first_id = data.next_tile_id
		list_id = data.next_tilelist_id

		texture = res.get_texture(file)
		-- Width and height in pixels
		pix_w, pix_h = texture\getSize()
		-- With and height in tiles
		tex_w, tex_h = (pix_w / TILE_WIDTH), (pix_h / TILE_HEIGHT)

		-- Gather the tile list
		tiles = for x, y, id in part_xy_iterator(_from, to, first_id) 
			Tile.create id, 
				(y-1) * tex_w + x,
				solid

		tilelist = TileList.create(list_id, name, tiles, file)

		-- Assign to the tile name
		data.tiles[name] = tilelist
		data.id_to_tilelist[list_id] = tilelist

		-- Assign by tile id
		for tile in *tiles 
			data.id_to_tile[tile.id] = tile

		-- Skip the amount of tiles added
		data.next_tile_id += #tiles
		data.next_tilelist_id += 1

	-- Sprite definition
	fenv.spritedef = define_wrapper (values) ->
		{:file, :size, :tiled, :kind, :name, :to} = values
		{w, h} = size
		kind = kind or variant

		_from = values["from"] -- skirt around Moonscript keyword

		-- Default to 1 sprite
		to = to or _from

		-- Gather the sprite frames
		frames = for x, y in part_xy_iterator(_from, to) 
			TexPart.create(res.get_texture(file), (x-1)*w, (y-1)*h, w, h)

		sprite = Sprite.create(frames, kind, w, h)
		data.sprites[name] = sprite
		data.id_to_sprite[data.next_sprite_id] = sprite

		-- Increment sprite number
		data.next_sprite_id += 1

	-- Level generation data definition
	fenv.leveldef = define_wrapper (values) ->
		{:name, :generator} = values
		level = LevelData.create(name, generator)
		data.levels[name] = level
		data.id_to_level[data.next_sprite_id] = level

		-- Increment sprite number
		data.next_level_id += 1

-- TODO: Actually setup by-module searching
setup_define_functions(_G, "NotUsedYet")

-------------------------------------------------------------------------------

return { 
	:load,
	get_tilelist: (key) -> 
		if type(key) == 'string' 
			assert(data.tiles[key])
		else 
			assert(data.id_to_tilelist[key])

	get_tilelist_id: (name) -> assert(data.tiles[name].id)
	get_sprite: (name) -> assert(data.sprites[name])
	get_level: (name) -> assert(data.levels[name])
}
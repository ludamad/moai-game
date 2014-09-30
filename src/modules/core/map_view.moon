-------------------------------------------------------------------------------
-- Standard requires from Lanarts engine 
-------------------------------------------------------------------------------

BoolGrid, mtwist = require "BoolGrid", require "mtwist" 

import Display from require 'ui'

import FloodFillPaths, GameInstSet, GameTiles, GameView, util, TileMap, RVOWorld, game_actions,
    ui_minimap, menu_start from require "core"

-------------------------------------------------------------------------------
-- Other requires
-------------------------------------------------------------------------------

import ui_ingame_scroll from require "core.ui"
import ui_sidebar from require "core"

import util_draw from require "core"

json = require 'json'
modules = require 'core.data'
user_io = require 'user_io'
res = require 'resources'
serialization = require 'core.serialization'

-------------------------------------------------------------------------------
-- Set up the camera & viewport
-------------------------------------------------------------------------------
setup_camera = (V) ->
    w,h = V.map.tilemap_width, V.map.tilemap_height
    tw, th = V.map.tile_width, V.map.tile_height

    cx, cy = w * tw / 2, h * th / 2
    V.camera = Display.game_camera
    V.viewport = with Display.game_viewport
        \setSize(V.cameraw - ui_sidebar.SIDEBAR_WIDTH, V.camerah)
        \setScale(V.cameraw - ui_sidebar.SIDEBAR_WIDTH, -V.camerah)
    with Display.ui_viewport
        \setSize(V.cameraw, V.camerah)
        \setScale(V.cameraw, -V.camerah)

-------------------------------------------------------------------------------
-- Set up the layers for the map
-------------------------------------------------------------------------------
setup_tile_layers = (V) ->
    -- Map and tile dimensions
    w,h = V.map.tilemap_width, V.map.tilemap_height
    tw, th = V.map.tile_width, V.map.tile_height

    -- Prop lists, and grid map
    -- There :is one prop and grid for each tile texture used
    props, grids = {}, {}

    -- Get the appropriate grid for a tile ID
    _grid = (tileid) ->
        tilelist = modules.get_tilelist(tileid)
        file = tilelist.texfile

        if not grids[file] 
            grids[file] = with MOAIGrid.new()
                \setSize(w, h, tw, th)

            tex = res.get_texture(file)
            tex_w, tex_h = tex\getSize()
            -- Create the tile prop:
            append props, with MOAIProp2D.new()
                \setDeck with MOAITileDeck2D.new()
                    \setTexture(res.get_texture(file))
                    \setSize(tex_w / tw, tex_h / th)
                    \setUVQuad( -0.5, -0.5, 0.5, -0.5, 0.5, 0.5, -0.5, 0.5 )
                \setGrid(grids[file])
        return grids[file]

    -- Assign a tile to the appropriate grid
    _set_xy = (x, y, tileid) ->
        -- 0 represents an empty tile, for now
        if tileid == 0 then return
        -- Otherwise, locate the correct grid instance
        -- and set the tile grid position accordingly
        grid = _grid(tileid)
        tilelist = modules.get_tilelist(tileid)
        -- The tile number
        n = _RNG\random(1, #tilelist.tiles + 1)
        tile = tilelist.tiles[n]

        grid\setTile(x, y, tile.grid_id)

    for y=1,h do for x=1,w
        _set_xy(x, y, V.map.tilemap\get({x,y}).content)

    -- Add all the different textures to the background layer
    for p in *props do Display.game_bg_layer\insertProp(p)

setup_fov_layer = (V) ->
    w,h = V.map.tilemap_width, V.map.tilemap_height
    tw, th = V.map.tile_width, V.map.tile_height
    tex = res.get_texture "fogofwar-dark.png"
    tex_w, tex_h = tex\getSize()

    fov_layer = Display.game_fg_layer1
    V.fov_grid = with MOAIGrid.new()
        \setSize(w, h, tw, th)

    fov_layer\insertProp with MOAIProp2D.new()
        \setDeck with MOAITileDeck2D.new()
            \setTexture(tex)
            \setSize(tex_w / tw, tex_h / th)
        \setGrid(V.fov_grid)

    for y=1,h do for x=1,w 
        -- Set to unexplored (black)
        V.fov_grid\setTile(x,y, 2)

setup_overlay_layers = (V) ->
    setup_fov_layer(V)

    -- Add the UI layer.
    with Display.ui_viewport
        \setOffset(-1, 1)
        \setSize(V.cameraw, V.camerah)
        \setScale(V.cameraw, -V.camerah)

    -- Helpers for layer management
    V.add_ui_prop = (prop) -> Display.ui_layer\insertProp(prop)
    V.remove_ui_prop = (prop) -> Display.ui_layer\removeProp(prop)
    V.add_object_prop = (prop) -> Display.game_obj_layer\insertProp(prop)
    V.remove_object_prop = (prop) -> Display.game_obj_layer\removeProp(prop)

-------------------------------------------------------------------------------
-- Create a map view
-------------------------------------------------------------------------------

create_map_view = (map, cameraw, camerah) ->
    V = {gamestate: map.gamestate, :map, :cameraw, :camerah}

    -- The UI objects that run each step
    V.ui_components = {}

    map_logic = (require 'core.map_logic')

    setup_camera(V)
    setup_tile_layers(V)
    setup_overlay_layers(V)

    V.draw = () ->
        map_logic.draw(V)

    script_prop = (require 'core.util_draw').setup_script_prop(Display.game_obj_layer, V.draw, V.map.pix_width, V.map.pix_height, 999999)

    -- Note: uses script_prop above
    V.pre_draw = () ->
        map_logic.pre_draw(V)

    -- Setup function
    V.start = () -> 
        map_logic.start(V)

    V.sidebar = ui_sidebar.Sidebar.create(V)
    append V.ui_components, ui_ingame_scroll V
    append V.ui_components, () -> V.sidebar\predraw()

    return V

return {:create_map_view}
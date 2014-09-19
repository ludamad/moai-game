
import camera, util_movement, util_geometry, util_draw, game_actions from require "core"
statsystem = require "statsystem"

import ObjectBase, CombatObjectBase, Player, NPC, Projectile from require '@map_object_types'

resources = require 'resources'
modules = require 'core.data'
user_io = require 'user_io'

-- Special movement helper

-- Decide on the path the maximizes distance
player_smart_move = (M, dirx, diry, dist) =>
    
    -- Multiply by '0.72' -- adjustment for directional movement
    total_dx, total_dy, distance = 0,0,0
    for dir_pref=0,1
        altdx, altdy, altdist = util_movement.look_ahead(@, M, dir_pref, dirx, diry)
        if altdist > distance
            total_dx, total_dy, distance = altdx, altdy, altdist
    if dirx ~= 0 and diry ~= 0 and distance ~= @speed
        mag_factor = math.sqrt(dirx*dirx + diry*diry) / math.abs(diry)
        for dir_pref=0,1
            altdx, altdy, altdist = util_movement.look_ahead(@, M, dir_pref, 0, diry * mag_factor)
            if altdist > distance
                total_dx, total_dy, distance = altdx, altdy, altdist

    -- Finally, take that path:
    @x += total_dx
    @y += total_dy
    if dirx ~= 0 or diry ~= 0
        @frame += 0.1

-- Pseudomethod
player_perform_move = (M, dx, dy) =>
    if dx == 0 and dy == 0
        return
    if dx ~= 0 and dy ~= 0 
        dx *= 0.75
        dy *= 0.75
    player_smart_move(@, M, dx, dy, @speed)
    @stats.cooldowns.rest_cooldown = math.max(@stats.cooldowns.rest_cooldown, statsystem.REST_COOLDOWN)

player_perform_action = (M, obj, action) ->
    -- Resolve any special actions queued for this frame
    if action.action_type == game_actions.ACTION_USE_WEAPON
        obj\attack(M)

    -- Finally, resolve the movement component of the action
    id_player, step_number, dx, dy = game_actions.unbox_move_component(action)
    assert(id_player == obj.id_player)
    assert(step_number == M.gamestate.step_number)
    player_perform_move(obj, M, dx, dy)

player_move_with_velocity = (M, vx, vy) =>
    mag = math.sqrt(vx*vx + vy*vy)
    player_action_move(@, M, vx / mag, vy / mag, mag)

-- Step event

-- Exported
-- Step a player for a single tick of the time
-- M: The current map
player_step = (M) =>
    S = @stats

    -- Set up directions of player
    action = M.gamestate.get_action(@id_player)
    if action
        player_perform_action(M, @, action)
    -- Ensure player does not move in RVO
    @set_rvo(M, 0,0)

    -- Default to not resting:
    @is_resting = false
    -- Handling resting due to staying-put
    if @stats.cooldowns.rest_cooldown == 0
        needs_hp = (S.hp < S.max_hp and S.hp_regen > 0)
        needs_mp = (S.mp < S.max_mp and S.mp_regen > 0)
        if needs_hp or needs_mp
            -- Rest if we can, and if its useful
            @is_resting = true

    if @is_resting
        -- Handling healing due to rest
        S.attributes.hp_regen += S.attributes.raw_hp_regen * 7
        S.attributes.mp_regen += S.attributes.raw_mp_regen * 7

MAX_FUTURE_STEPS = 0

-- Exported
-- Handle keyboard and mouse input for a single frame, for this player
-- M: The current map
player_handle_io = (M) =>
    G = M.gamestate
    step_number = G.step_number
    while G.get_action(@id_player, step_number) 
        -- We already have an action for this frame, think forward
        step_number += 1
        if step_number > G.step_number + MAX_FUTURE_STEPS
            -- We do not want to queue up a huge amount of actions to be sent
            return

    dx,dy=0,0
    if (user_io.key_down "K_UP") or (user_io.key_down "K_W") 
        dy = -1
    elseif (user_io.key_down "K_DOWN") or (user_io.key_down "K_S") 
        dy = 1
    if (user_io.key_down "K_RIGHT") or (user_io.key_down "K_D") 
        dx = 1
    elseif (user_io.key_down "K_LEFT") or (user_io.key_down "K_A") 
        dx = -1

    -- if G.gametype ~= "single_player"
    --     if dx==0 and dy==0 then 
    --         dx,dy = rdx,rdy
    --         if _RNG\random(15) == 1
    --             rdx,rdy = _RNG\random(-1,2),_RNG\random(-1,2)

    local action
    if user_io.key_pressed "K_Y"
        action = game_actions.make_weapon_action @, step_number, dx, dy
    else
        action = game_actions.make_move_action @, step_number, dx, dy
    G.queue_action(action)
    -- if G.net_handler
        -- Send last two unacknowledged actions (included the one just queued)
        -- G.net_handler\send_unacknowledged_actions(2)

    if user_io.key_pressed "K_P"
        Projectile.create M, {
            x: @x
            y: @y
            vx: -1
            vy: -1
            action: "TODO"
        }
    if user_io.key_pressed "K_U"
        M.gamestate.local_player()\attack(M)

return {:player_step, :player_handle_io, :player_perform_action}
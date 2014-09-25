
import util_movement, util_geometry, util_draw, game_actions from require "core"

import ObjectBase, CombatObjectBase, Player, NPC, Projectile from require '@map_object_types'

resources = require 'resources'
modules = require 'core.data'
user_io = require 'user_io'

DIST_THRESHOLD = 6

-- Exported
-- Step a player for a single tick of the time
-- M: The current map
npc_step_all = (M) ->
    -- Set up directions of all NPCs
    npcs = [npc for npc in *M.npc_list]
    for obj in *npcs
        p, dist = M.closest_player(obj)
        if p
            x1,y1,x2,y2 = util_geometry.object_bbox(obj)
            dx, dy = p.paths_to_player\interpolated_direction(math.ceil(x1),math.ceil(y1),math.floor(x2),math.floor(y2), obj.speed)
            if dist > 0 and dist < DIST_THRESHOLD 
                dx, dy = 0,0
            obj\set_rvo(M, dx, dy)
            -- Temporary storage, just for this function:
            obj.__vx, obj.__vy = dx, dy
            obj.__dist = dist
            obj.__target = p
            obj.__moved = false

    -- Run the collision avoidance algorithm
    M.rvo_world\step()

    -- Sort NPCs by distance to their target
    table.sort npcs, (a,b) -> a.__dist < b.__dist

    -- Move NPCs
    for obj in *npcs
        local vx, vy
        vx, vy = obj\get_rvo_velocity(M)
        -- Are we close to a wall?
        if M.tile_check(obj, vx, vy, obj.radius)
            -- Then ignore RVO, problematic near walls
            vx, vy = obj.__vx, obj.__vy
        -- Otherwise, proceed according to RVO

        -- If we are on direct course with a wall, adjust heading:
        if M.tile_check(obj, vx, vy)
            -- Try rotations (rationale: guarantee to preserve momentum, and not move directly backwards):
            if not M.tile_check(obj, -vy, vx) then vx, vy = -vy, vx
            elseif not M.tile_check(obj, vy, vx) then vx, vy = vy, vx
            elseif not M.tile_check(obj, vy, -vx) then vx, vy = vy, -vx
            elseif not M.tile_check(obj, -vy, -vx) then vx, vy = -vy, -vx
            else vx, vy = 0,0

        -- Advance forward if we don't hit a solid object
        collided = false
        for col_id in *M.object_query(obj, vx, vy, obj.radius)
            o = M.col_id_to_object[col_id]
            if getmetatable(o) == NPC and o.__target == obj.__target and o.__moved
                collided = true
                break

        if not collided
            obj.x += vx
            obj.y += vy
        obj.__moved = true

    -- Resolve actions
    for obj in M.npc_iter()
        obj\perform_action(M)

return {:npc_step_all}
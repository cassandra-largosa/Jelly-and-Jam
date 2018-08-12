pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--jelly and jam
--by spaghetti time
--cartdata("jelly and jam")

debug = true

--helper functions
function array_concat(arrays)
    --return an array with the elements of all given arrays (should be a shallow copy)
    local result = {}
    for array in all(arrays) do
        for item in all(array) do
            add(result, item)
        end
    end
    return result
end

--animation stuff
function add_sprite(name, anim)
    sprites[name] = {anim=anim, frame=1}
end

function get_sprite(name)
    local sprite = sprites[name]
    return sprite.anim[sprite.frame]
end

function inc_anim(sprite)
    sprite.frame = (sprite.frame%(#sprite.anim))+1
end

--animations {frame1, frame2...}
--slime_a = {0,0,2,2,4,4,6,6,4,4,2,2}

sprites = {}
--add_sprite("slime", slime_a)

sprite_map = {none = 0,
              grass = 65,
              exit = 75,
              exit_closed = 75,
              exit_open = 77,
              rock = 83,
              floor = 85,
              puddle = 86,
              pebble = 90,
              goal = 97}

--hitbox stuff
function make_hitbox(x1, y1, x2, y2)
    return {x1=x1, y1=y1, x2=x2, y2=y2}
end

function make_rect(hitbox, x, y)
    local x1 = hitbox.x1+x
    local y1 = hitbox.y1+y
    local x2 = hitbox.x2+x
    local y2 = hitbox.y2+y
    return make_hitbox(x1, y1, x2, y2)
end

function get_rect(object)
    if hitbox_map[object.name] != nil then
        return make_rect(hitbox_map[object.name], object.x, object.y)
    else
        return nil
    end
end

function collide(r1, r2)
    if r1.x2 < r2.x1 or r1.x1 > r2.x2 or r1.y2 < r2.y1 or r1.y1 > r2.y2 then
        return false
    end
    return true
end

--hitboxes (x1, y1, x2, y2)
hitbox_map = {rock = make_hitbox(0, 0, 7, 7),
              goal = make_hitbox(0, 0, 7, 7),
              exit = make_hitbox(0, 0, 15, 15),
              puddle = make_hitbox(0, 0, 7, 7),
              pebble = make_hitbox(0, 0, 7, 7)}

--menu stuff
menu_items = {"easy", "medium", "hard"}
menu_cursor = 1
menu_choice = 0

--high score stuff
function get_hiscores()
    local scores = {}
    local start = (menu_choice-1)*5
    for i = start,start+4 do
        add(scores, dget(i))
    end
    return scores
end

function set_hiscores()
    function sort(list)
        --reverse bubble sort (shut up)
        for i = #list-1,1,-1 do
            for j = 1,i do
                if list[j] < list[j+1] then
                    local temp = list[j+1]
                    list[j+1] = list[j]
                    list[j] = temp
                end
            end
        end
    end
    
    local scores = get_hiscores()
    add(scores, flr(score))
    sort(scores)
    
    local start = (menu_choice-1)*5
    for i = 1,5 do
        dset(start+i-1, scores[i])
    end
end

--constants
first_level = 1
puddle_growth = -5 --amount to grow mud by when it steps in a puddle
pebble_break_size = 16 --minimum mud size required to break a pebble
exit_size = 16 --maximum mud size allowed to fit through exit

--status stuff
temp = 0

--level stuff
cur_level = -1

function init_level(level)
    --set mud start
    mud.reset(get_start(level))
    
    --set goal
    goal.reset(get_goal(level))
    
    --set exit
    exit.reset(get_exit(level))
    
    --set rocks
    rocks = get_rocks(level)
    
    --set puddles
    puddles = get_puddles(level)
    
    --set pebbles
    pebbles = get_pebbles(level)
end

function next_level()
    cur_level += 1
    init_level(cur_level)
end

function start_game()
    cur_level = first_level
    init_level(cur_level)
end

--map math
function map_to_screen(cel)
    --takes a map cell coordinate (x or y), returns the corresponding position on screen (top-left corner)
    return (cel % 16)*8
end

function screen_to_map(x, y, level)
    --takes a screen position, returns the corresponding map cel coordinates for the given level
    local cel_x = (level % 8)*16 + flr(x/8)
    local cel_y = flr(level/8)*16 + flr(y/8)
    return {cel_x = cel_x, cel_y = cel_y}
end

--map under-object tiles
--key = sprite number of object on map, value = sprite number of tile to draw under object on map
under = {[sprite_map.none] = sprite_map.floor,
         [sprite_map.puddle] = sprite_map.floor,
         [sprite_map.goal] = sprite_map.floor,
         [sprite_map.pebble] = sprite_map.floor,
         [sprite_map.rock] = sprite_map.grass}

--map object stuff
function get_map_objects(name, level)
    --returns a list of objects with the given name found on the map for the given level
    local objects = {}
    local cel = screen_to_map(0, 0, level)
    local start_x = cel.cel_x
    local start_y = cel.cel_y
    local sprite = sprite_map[name]
    
    for cel_y = start_y,start_y+15 do
        for cel_x = start_x,start_x+15 do
            if mget(cel_x, cel_y) == sprite then
                local object = {name = name,
                                x = map_to_screen(cel_x),
                                y = map_to_screen(cel_y)}
                object.rect = get_rect(object)
                add(objects, object)
            end
        end
    end
    return objects
end

function get_start(level)
    --returns an object representing where the mud starts for the level
    return get_map_objects("none", level)[1]
end

function get_rocks(level)
    --returns a list of rock objects found on the map for the level
    return get_map_objects("rock", level)
end

function get_goal(level)
    --returns an object representing where the goal is for the level
    return get_map_objects("goal", level)[1]
end

function get_exit(level)
    --returns an object representing where the exit is for the level
    return get_map_objects("exit", level)[1]
end

function get_puddles(level)
    --returns a list of puddle objects found on the map for the level
    return get_map_objects("puddle", level)
end

function get_pebbles(level)
    --returns a list of pebble objects found on the map for the level
    return get_map_objects("pebble", level)
end

--mud stuff
mud = {name = "mud",
       x = 0, y = 0,
       speed = 4, --step distance in pixels
       size = 8, --diameter in pixels
       growth = 0.5, --how much to grow radius each step in pixels
       alive = true
       }

mud.reset = function(m)
    mud.x, mud.y =  m.x, m.y
    mud.size = 8 --todo: set this per level? set this by multiple empty map spaces?
    mud.growth = 0.5 --todo: same as above
    mud.alive = true
end

mud.get_rect = function()
   return make_hitbox(mud.x, mud.y, mud.x+mud.size-1, mud.y+mud.size-1)
end

mud.fits = function()
    --return whether the mud is allowed to be where it is
    local mud_rect = mud.get_rect()
    
    --check for rocks
    for rock in all(rocks) do
        if collide(mud_rect, rock.rect) then
            return false
        end
    end
    
    --only need to check for pebbles if mud is too small to break them
    if mud.size < pebble_break_size then
        for pebble in all(pebbles) do
            if collide(mud_rect, pebble.rect) then
                return false
            end
        end
    end
    
    return true
end

mud.move = function(dir)
    --todo: if the mud can't move all the way, move as close as possible
    local x, y = mud.x, mud.y
    
    if dir == "up" then
        mud.y -= mud.speed
    elseif dir == "down" then
        mud.y += mud.speed
    elseif dir == "left" then
        mud.x -= mud.speed
    elseif dir == "right" then
        mud.x += mud.speed
    end
    
    local moved = mud.fits()
    if not moved then
        mud.x, mud.y = x, y
    end
    
    return moved
end

mud.grow = function(amount)
    --increase the mud's radius by amount
    mud.size += amount*2
    mud.x -= amount
    mud.y -= amount
    if mud.size <= 0 then mud.kill() end
end

mud.kill = function()
    mud.alive = false
end

--rock stuff
rocks = {}

--pebble stuff
pebbles = {}

--goal stuff
goal = {name = "goal",
        x = 0, y = 0,
        rect = nil,
        collected = false --whether or not the goal has been collected
        }

goal.collect = function()
    goal.collected = true
end

goal.reset = function(g)
    goal.x, goal.y = g.x, g.y
    goal.collected = false
    goal.rect = get_rect(goal)
end

--exit stuff
exit = {name = "exit",
        x = 0, y = 0,
        rect = nil}

exit.reset = function(e)
    exit.x, exit.y = e.x, e.y
    exit.rect = get_rect(exit)
end

--puddle stuff
puddles = {}

function _draw()
    cls()
    
    --map
    local cel = screen_to_map(0, 0, cur_level)
    local cel_x = cel.cel_x
    local cel_y = cel.cel_y
    map(cel_x, cel_y, 0, 0, 16, 16)
    
    --map under objects
    for map_y = cel_y,cel_y+15 do
        for map_x = cel_x,cel_x+15 do
            local sprite = under[mget(map_x, map_y)]
            if sprite != nil then
                spr(sprite, map_to_screen(map_x), map_to_screen(map_y))
            end
        end
    end
    
    --goal
    if not goal.collected then
        spr(sprite_map.goal, goal.x, goal.y)
    end
    
    --exit
    palt(0, false)
    palt(7, true)
    if goal.collected then
        spr(sprite_map.exit_open, exit.x, exit.y, 2, 2)
    else
        spr(sprite_map.exit_closed, exit.x, exit.y, 2, 2)
    end
    palt()
    
    --map objects (rocks, puddles...)
    local objects = array_concat({rocks, puddles, pebbles})
    for object in all(objects) do
        spr(sprite_map[object.name], object.x, object.y)
        if debug then --bounding boxes
            local r = object.rect
            rect(r.x1, r.y1, r.x2, r.y2, 11)
        end
    end
    
    --mud
    --todo maybe: if we round the mud's size down to the nearest even number,
    --then it won't wiggle back and forth when moving in a straight line
    if mud.alive then
        palt(0, false)
        palt(7, true)
        sspr(64, 0, 24, 24, mud.x, mud.y, mud.size, mud.size)
        palt()
    end
    
    --mud bounding box
    local r = mud.get_rect()
    rect(r.x1, r.y1, r.x2, r.y2, 8)
    
    --text
    if debug then print("size: "..mud.size.." x: "..mud.x.." y: "..mud.y, 0, 0, 2) end
    --print("temp: "..temp)
end

function _update()
    --animate sprites
    for key,sprite in pairs(sprites) do
        inc_anim(sprite)
    end
    
    --start game, if necessary
    if cur_level < 0 then start_game() end
    
    --debug reset level
    if debug and btnp(4) then init_level(cur_level) end
    
    if mud.alive then
        --move and grow mud
        local dir = ""
        if btnp(0) then
            dir = "left"
        elseif btnp(1) then
            dir = "right"
        elseif btnp(2) then
            dir = "up"
        elseif btnp(3) then
            dir = "down"
        end
        if dir != "" then
            local moved = mud.move(dir)
            if moved then
                mud.grow(mud.growth)
                --todo: adjust mud position after growth
            end
        end
        
       --collect goal
        if not goal.collected and collide(mud.get_rect(), goal.rect) then
            goal.collect()
        end
        
        --break pebbles
        if mud.size >= pebble_break_size then
            for pebble in all(pebbles) do
                if collide(mud.get_rect(), pebble.rect) then
                    del(pebbles, pebble)
                end
            end
        end
        
        --collide with puddles
        for puddle in all(puddles) do
            if collide(mud.get_rect(), puddle.rect) then
                del(puddles, puddle)
                mud.grow(puddle_growth)
            end
        end
        
        --exit
        if goal.collected and mud.size <= exit_size and collide(mud.get_rect(), exit.rect) then
            next_level()
        end
    end
end

__gfx__
00000000000000000000000000000999999000000000000000000000000000007777777777777777777777770000000000000000000000000000000000000000
00000000000000000000000000044444444440000000000000000000000000007777777777777777777777770000000000000000000000000000000000000000
00700700000000000000000000444444444444000000000044444444000000007777777744444444777777770000000000000000000000000000000000000000
00077000000000000000000004444444444444400000004424444444440000007777774424444444447777770000000000000000000000000000000000000000
00077000000000000000000004444444444444400000444442224444444200007777444442224444444277770000000000000000000000000000000000000000
00700700000000000000000044444444444444440004244424444244424420007774244424444244424427770000000000000000000000000000000000000000
00000000000000f77f00000044444444444444440044422244424422244442007744422244424422244442770000007777000000000000000000000000000000
000000000000af4444fa00004444444444444444024444444424444444244220724444444424444444244227000077aaaa770000000000000000000000000000
00000000000944444444900044444444444444440424444422442444444224207424444422442444444224270007aaaaaaaa7000000000000000000000000000
000000000094444444444900244444444444444224422222442244424424444224422222442244424424444200faaaaaaaaaaf00000000000000000000000000
00000000094444444444449022444444444444222444422222444444224444422444422222444444224444420faaaaaaaaaaaaf0000000000000000000000000
000000002444444444444442042444444444424024444444444444444444444224444444444444444444444209aaaaaaaaaaaa90000000000000000000000000
000000002244444444444422024244444444242042444224444442224444422442444224444442224444422409aaaaaaaaaaaa90000000000000000000000000
0000000022242424242422220024242442424200442224424444244424422424442220024444244424422424099aaaaaaaaaa990000000000000000000000000
00000000022242424242422000024242242420002442422422224444422442422442422422224444422002420099aaaaaaaa9900000000000000000000000000
00000000002222222222220000000222222000004224444444444444444224424224444444444444444224420009999999999000000000000000000000000000
00000000000000000000000000000000000000002444444444444444444442242444444444444444444442240000000000000000000000000000000000000000
00000000000000000000000000000000000000002424422444444222444224422424422444444222444224420000000000000000000000000000000000000000
00000000000000000000000000000000000000000242244244422444222444207242244244422202222444270000000000000000000000000000000000000000
00000000000000000000000000000000000000000244422422244444444424207244422422220212000224270000000000000000000000000000000000000000
00000000000000000000000000000000000000000022244444444444422442007722244420021211122442770000000000000000000000000000000000000000
00000000000000000000000000000000000000000002422442244422244220007772422442211111244227770000000000000000000000000000000000000000
00000000000000f77f00000000000077770000000000224224422244422200007777224224422222422277770000000000000000000000000000000000000000
000000000000aaaaaaaa00000000f7aaaa7f00000000002222222222220000007777772222222222227777770000000000000000000000000000000000000000
000000000009aa4a4aaa9000000aaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000099a4a4a4a4990000aaaaaaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000099a4a4a4a4a499009aaaaaaaaaa4a900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000944444444444490094aa4aaa4a4a4900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000494449449444940099a4a9a49aa49400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000024494494444942009949a49a94a94900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000002242424242420000994994949449000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000222222222200000022422424220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3333c1c33333333b3333333338383833333333330bb0bbb00000000000000000000900000000090000006000fff7a9ffff7a9fffffffffffffffffff00000000
333c1a1cb333333b33333b33338883333e333333b8bbbb8b0009990009090000000009000090000000006000f44a994444a9944ff10101010101010f00000000
33eecee3b33b333333333b33333833333b333333bbbb8bbb099888900009090000900900009900900006d500f44494444449444ff01010000010101f00000000
32ee8ee3333b333333333333333bb3333b3333c3bbbbbbb0988889890099090009990990009909000006d500f44494444449444ff10000000000010f00000000
2a28a83333333b333b333333333b33b3333233b30b8bbbbb98998889099a9a00099a9a90099a9a90006d5550f44444444444444ff01000000000001f00000000
32ee8e733b333b333b33b3333b3333b3333b33b3b8bbb8bb0988888909aaaa9009aaaa9009aaaa90006d5550f44444444444444ff10000000000010f00000000
33eeb7973b3b333b3333b3333b333333333b3333bbb8bbbb0098989009aaaa9009aaaa9009aaaa9006d55555f44444444444444ff00000000000001f00000000
3333b373333b333b3333333333333333333333330bbb0bb000099900009aa900009aa900009aa90006d55555f44444444444444ff10000000000000f00000000
65555565fff9ffff6655666600000000666666665555555500000000000000000000000000cc0cc000000000f44444444444444ff00000000000001f00000000
56666655f9ffff9f6566566600666600665665565556566500cc770000cccc0000cccc000ccccccc00006660f44444444444444ff10000000000000f00000000
65555566ffffffff566665560d66666066666666565556650ccccc7007c7c7c00cccccc0cccccccc00d66616f44444444444444ff01000000000001f00000000
56555655fff9ffff66666665ddd666655666665655555555cc7ccccc7c7c7c7ccccccccccccccccc0ddd6166f444444aa444444ff10000000000010f00000000
55666555fffffff966666665ddddd6556665566655565555cccccc7ccccccccccccccccc0cccccc0ddd11665f44444999944444ff01000000000001f00000000
56555655f9ff9fff66666665dddddd556655556655555555cccc7cccc7c7c7c7ccccccccccccccccdd155155f444474aa494444ff10100000001010f00000000
65555565fffff9ff566666555dddd5556666666556555565077cccc00c7c7c700cccccc0ccccccccd1555155f44449444494444ff01010101010101f00000000
55555556ff9fffff6555556605dd55505665566655556555000ccc00000ccc00000ccc000ccc0cc005555550ffffff9999ffffffffffffffffffffff00000000
00000000000000000000000000000b000000700000fff90000000000000000000000000000000000000000000000000000000000000000000000000000000000
007a980000009000007f0fe00000b3b00070607007aaaa9000007000000000000000000000000000000000000000000000000000000000000000000000000000
0affa980000a820007feeee2000bb3b00006c600faa99aa400007700000000000000000000000000000000000000000000000000000000000000000000000000
89aa9982000f82000fee8ee200bb3bb0076c0c67fa9999a400076700000000000000000000000000000000000000000000000000000000000000000000000000
89999982000f820000e8882000b3bb000006c6009a9999a407066607000000000000000000000000000000000000000000000000000000000000000000000000
08999820000a8200000e8200003bb000007060709aa99aa40666d666000000000000000000000000000000000000000000000000000000000000000000000000
0088820000009000000020000b0000000000700004aaaa200d6dd6d6000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000b0000000000000000044420000ddddd0000000000000000000000000000000000000000000000000000000000000000000000000
ffff11fffff11ffffff11fff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccceeee
fffff11fff1111fffff11fff010000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccceeee
11111111f1f11f1ff1f11f1f101dd1010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccceeee
fffff11ffff11fffff1111ff10dddd010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccceeee
ffff11fffff11ffffff11fff008dd8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeecccc
000440000004400000044000012002100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeecccc
000990000009900000099000102002010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeecccc
000ff000000ff000000ff000100000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeecccc
__map__
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f53535353535353535353535353535353535353535353535353535353535353530000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f53555555535555555555555555555553535555555555555555555555555555530000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f53555555555555555556555555555553535555555555555555555555555555530000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f53535555005555555555555555555553535555555555555555555555555555530000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f5355555555554b555556555555555553535555555555555555555555555555530000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f53555555555555555555555555555553535555555555555555555555555555530000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f535555555a5555555555535555555553535555555555555555555555555555530000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f53555555555555555555555555555553535555555555555555555555555555530000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f53555555555555555555555555555553535555555555550055555555555555530000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f53555555555555555555555553555553535555555555555555555555615555530000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f53555555535555555555555555555553535555555555555555555555555555530000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f535555555555565561555555555555535355555555555555555555554b5555530000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f53555555555555555555555555555553535555555555555555555555555555530000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f53555555555555555555555555555553535555555555555555555555555555530000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f53555555555555555555555555555553535555555555555555555555555555530000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f53535353535353535353535353535353535353535353535353535353535353530000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100041805018050180301803018000180001800018000180001800018000180001800018000180001800018000180001800018000180001800018000180001800018000180001800018000180001800018000
000100081885018850188501885018750187501875018750188001880018800188001870018700187001870018800188001880018800187001870018700187001880018800188001880018700187001870018700
00010410187511875118751187511a7511a7511c7511c7511d7511d7511c7511c7511a7511a75118751187540020100200162000020015a000000014a0013a0013a0000000000000000000000000000000000000
01010008183501835018350183500c3500c3500c3500c350183001830018300183001830018300183001830018300183001830018300183001830018300183001830018300183001830018300183001830018300
000100001855018550185501855029550295501a550235501f5501d550295501f5500d550155502c5501850018500185001850018500185001850018500181001810018100181001810018100181000000000000
000100200e5501355015550185501d5501f550225502355025550265502755028550285502855028550275502655024550225501f5501c550135500e550275502a5502d5502d5502b550265501f5501155007550
010100021805018000180001800018000180001800018000180001800018000180001800018000180001800018000180001800018000180001800018000180001800018000180001800018000180001800500000
0101060a2475123751217511f7511d7511c7511a75118751177511875110f000ef000cf0009f0008f0006f0005f0003f0002f0001f0011b001fd0011b001fd0022c0023c001ed0012d001dd001dd001dd0021e00
0110000018f5018f5018f5023f5023f5021f501af5021f501cf501ff501ff501ff501af501df501df501df5018f501ff501af501ff501cf5021f5021f5021f501ff5023f501cf5023f501af501ff5018f5018f50
001800100c453004030c653004030c453004030c6530c6030c453004030c4530c6030c4530c6530c4530c4030c4030c4030c6030c4030c6030c4030c4030c4030c4030c603004030c4030c6030c4030c40300000
011800002f75000000000002d7502b75000000267500000024750000002675000000237502375023750237502f75000000000002d7502b750000002d750000002f7500000030750000002d7502d7502d7502d750
011800002f75000000000002d7502b750000002675000000247500000026750000002a750000002d750000002b7502b750247002a7002a750000002b750000002a750000002b7502b7502b750000002f70000000
011800002f75000000000003075032750000003275000000347500000032750000002b7502b7502b7502a7052f75000000000002b7502d750000002f75000000327500000030750000002f7502f7502f75000000
011800002f7500000000000307503275000000327500000034750000003475032750000002d7502d750000002f7502f750000002d7502b750000002d7500000030750000002f7502b750000002a7502b75000000
000c00000400004000040000400006000060000600006000070000700007000070000200002000020000200004000040000400004000060000600006000060000700007000070000700000000000000000000000
0109000024b5024b5024b5029b5029b5029b502db502db502db5024b5024b502bb502bb502fb502fb502fb5030b5030b5030b5030b5030b5030b5030b0030b0030b0030b0000b0000b0000c000ec0012c0000c00
000c0000170501d0501e0501a050130501205014050180501c0501b050160500f0500b0500e0500c0500805003050010500100001000010300103001030010300100001000010000100001000010000000000000
01010000261501c15017150101500b1500715004150011500b100081000710004100021000110023a000000024e0024e000000024e0022e0021e00000001be0018e0013e000ee0005e0001e00000000000000000
0001000018450114500d450084500645003450024500265001650016000140001400014000e3000d3000c3000b3000b3000a3000a3000a3000a3000930009300093000a3000a3000a3000b300000000000000000
0101000020f5227f522df5231f5236f5221f5227f522bf522df521cf5234f5222f5229f5231f5236f5233f5201f523df5222f0221f021ff021cf021af0218f0216f0215c001370011700101000e1000d0000c000
010100003085030850308503085030850308503085000800008000080000800008003b850398503b850008003c8503c8503c8503c8503c8503c8503c850008000080000800008000080000800008000080000800
__music__
01 090a4e44
00 090b4f44
00 090c4e44
00 090d4344
02 094e0e44


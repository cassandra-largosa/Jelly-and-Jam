pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--clod's quest
--by team spaghetti
--cartdata("clods_quest")

debug = false

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
    if sprite == nil then
        return nil
    else
        return sprite.anim[sprite.frame]
    end
end

function inc_anim(sprite)
    sprite.frame = (sprite.frame%(#sprite.anim))+1
end

--animations {frame1, frame2...}
puddle_a = {86,86,86,86,86,86,86,86,86,86,86,86,86,86,86,87,87,87,87,87,87,87,87,87,87,87,87,87,87,87,88,88,88,88,88,88,88,88,88,88,88,88,88,88,88}
fire_a = {71,71,71,71,71,71,72,72,72,72,72,72,73,73,73,73,73,73}
goal_a = {97,97,97,97,97,97,97,97,97,97,97,97,105,105,105,105,105,105,105,105,105,105,105,105,97,97,97,97,97,97,97,97,97,97,97,97,106,106,106,106,106,106,106,106,106,106,106,106}

sprites = {}
--add_sprite("slime", slime_a)
add_sprite("puddle", puddle_a)
add_sprite("fire", fire_a)
add_sprite("goal", goal_a)

sprite_map = {none = 0,
              grass = 65,
              fire = 71,
              exit = 75,
              exit_closed = 75,
              exit_open = 77,
              sand = 81,
              rock = 83,
              floor = 85,
              puddle = 86,
              pebble = 90,
              goal = 97,
              leaf = 99,
              snow = 100,
              potion = 104,
              spider = 115,
              beetle = 117}

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
    else --default hitbox is 8x8
        return make_rect(make_hitbox(0, 0, 7, 7), object.x, object.y)
    end
end

function collide(r1, r2)
    if r1.x2 < r2.x1 or r1.x1 > r2.x2 or r1.y2 < r2.y1 or r1.y1 > r2.y2 then
        return false
    end
    return true
end

--hitboxes (x1, y1, x2, y2)
--most things are default size so i'm not including them
hitbox_map = {exit = make_hitbox(0, 0, 15, 15)}

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
first_level = 0
last_level = 21
mud_speed = 4 --default mud step distance in pixels
puddle_growth = -5 --amount to grow mud by when it steps in a puddle
pebble_break_size = 16 --minimum mud size required to break a pebble
exit_size = 16 --maximum mud size allowed to fit through exit
snow_time = 10 --number of steps the snow effect lasts for
potion_time = 10 --number of steps the potion effect lasts for
spider_speed = 8 --number of pixels spiders move per step
beetle_speed = 8 --number of pixels beetles move per step
leaf_mult = 2 --how much the leaf multiplies the mud's speed by
leaf_time = 10 --number of steps the leaf effect lasts for
end_delay = 30 --number of frames between each transition in the ending
moving_time = 5 --number of frames for moving animation

--status stuff
mode = "title" --title, game, end
timer = 0 --timer for anything that wants it
end_timer = 0

function add_snow(time)
    snow += time
    sfx(29)
end

function add_potion(time)
    potion += time
    sfx(27)
end

function add_leaf(time)
    leaf += time
    sfx(22)
end

--moving animation stuff
moving = 0 --timer for moving animation

function start_moving()
    moving = moving_time
end

--level stuff
cur_level = -1

function init_level(level)
    --set timers
    snow = 0
    potion = 0
    leaf = 0
    moving = -1
    
    --set objects from map
    mud.reset(get_map_objects("none", level)[1])
    goal.reset(get_map_objects("goal", level)[1])
    exit.reset(get_map_objects("exit", level)[1])
    rocks = get_map_objects("rock", level)
    puddles = get_map_objects("puddle", level)
    pebbles = get_map_objects("pebble", level)
    fires = get_map_objects("fire", level)
    snows = get_map_objects("snow", level)
    potions = get_map_objects("potion", level)
    leafs = get_map_objects("leaf", level)
    
    spiders = get_map_objects("spider", level)
    beetles = get_map_objects("beetle", level)
    for bug in all(array_concat({spiders, beetles})) do
        bug.dir = 1
        bug.from_x, bug.from_y = bug.x, bug.y
    end
end

function next_level()
    sfx(15)
    cur_level += 1
    if cur_level > last_level then
        end_game()
    else
        init_level(cur_level)
    end
end

function start_game()
    mode = "game"
    cur_level = first_level
    init_level(cur_level)
    music(0)
end

function end_game()
    mode = "end"
    music(5)
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
--default value is floor, i'm not including them
under = {[sprite_map.rock] = sprite_map.sand,
         [sprite_map.pebble] = sprite_map.sand}

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

--mud stuff
mud = {name = "mud",
       x = 0, y = 0,
       speed = mud_speed,
       size = 8, --diameter in pixels
       growth = 0.5, --how much to grow radius each step in pixels
       alive = true,
       dir = "up", --up, down, left, right; for moving animation
       from_x = 0, from_y = 0, --original coordinates for moving animation
       bonked = false --hit a wall while moving
       }

mud.reset = function(m)
    mud.x, mud.y =  m.x, m.y
    mud.from_x, mud.from_y = m.x, m.y
    mud.size = 8 --todo: set this per level? set this by multiple empty map spaces?
    mud.growth = 0.5 --todo: same as above
    mud.alive = true
    mud.bonked = false
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
    mud.from_x, mud.from_y = mud.x, mud.y
    
    local x, y = mud.x, mud.y
    mud.speed = mud_speed
    if leaf > 0 then mud.speed *= leaf_mult end
    
    local moved = false
    for i = 1,mud.speed do
        if dir == "up" then
            mud.y -= 1
        elseif dir == "down" then
            mud.y += 1
        elseif dir == "left" then
            mud.x -= 1
        elseif dir == "right" then
            mud.x += 1
        end
    
        if mud.fits() then
            moved = true
            x, y = mud.x, mud.y
        else
            mud.x, mud.y = x, y
            if moved then mud.bonked = true end
            break
        end
    end
    
    if moved then
        mud.dir = dir
        start_moving()
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

mud.adjust = function(growth)
    --adjust the mud's position after growing by growth if it is inside a solid object
    
    --don't do anything if mud is not stuck
    if mud.fits() then return end
    
    --push up
    mud.y -= growth
    if mud.fits() then return end
    --push up right
    mud.x += growth
    if mud.fits() then return end
    --push right
    mud.y += growth
    if mud.fits() then return end
    --push down right
    mud.y += growth
    if mud.fits() then return end
    --push down
    mud.x -= growth
    if mud.fits() then return end
    --push down left
    mud.x -= growth
    if mud.fits() then return end
    --push left
    mud.y -= growth
    if mud.fits() then return end
    --push up left
    mud.y -= growth
    if mud.fits() then return end
    
    --give up
    mud.x += growth
    mud.y += growth
end

mud.kill = function()
    mud.alive = false
    sfx(16)
end

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

--rock stuff
rocks = {}

--pebble stuff
pebbles = {}

--puddle stuff
puddles = {}

--fire stuff
fires = {}

--snow stuff
snows = {}
snow = 0 --snow timer

--potion stuff
potions = {}
potion = 0 --potion timer

--leaf stuff
leafs = {}
leaf = 0 --leaf timer

--spider stuff
spiders = {}

function move_spider(spider)
    spider.from_x, spider.from_y = spider.x, spider.y
    spider.x += spider.dir*spider_speed
    for rock in all(array_concat({rocks, pebbles})) do
        if collide(get_rect(spider), rock.rect) then --turn around
            spider.dir *= -1
            spider.x += 2*spider.dir*spider_speed
        end
    end
end

--beetle stuff
beetles = {}

function move_beetle(beetle)
    beetle.from_x, beetle.from_y = beetle.x, beetle.y
    beetle.y += beetle.dir*beetle_speed
    for rock in all(array_concat({rocks, pebbles})) do
        if collide(get_rect(beetle), rock.rect) then --turn around
            beetle.dir *= -1
            beetle.y += 2*beetle.dir*beetle_speed
        end
    end
end

function _draw()
    cls()
    
    if mode == "title" then
        print("          clod's quest\n")
        
        print("get  , go to     while small\n\n")
        spr(get_sprite("goal"), 12, 11)
        spr(sprite_map.exit_closed, 50, 7, 2, 2)
        
        print("collect\n")
        spr(get_sprite("puddle"), 31, 28)
        spr(sprite_map.leaf, 41, 28)
        spr(sprite_map.snow, 51, 28)
        spr(sprite_map.potion, 61, 28)
        
        print("crush   while big\n")
        spr(sprite_map.pebble, 22, 40)
        
        print("avoid\n")
        spr(get_sprite("fire"), 24, 52)
        spr(sprite_map.spider, 34, 52)
        spr(sprite_map.beetle, 44, 52)
        
        print("don't shrink down to nothing\n")
        print("use arrow keys to move mud ball\n")
        print("press x to reset level\n")
        print("press x to start game")
    elseif mode == "game" then
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
                else --default to floor tile
                    spr(sprite_map.floor, map_to_screen(map_x), map_to_screen(map_y))
                end
            end
        end
        
        --goal
        if not goal.collected then
            spr(get_sprite("goal"), goal.x, goal.y)
        end
        
        --exit
        palt(0, false)
        if goal.collected then
            spr(sprite_map.exit_open, exit.x, exit.y, 2, 2)
        else
            spr(sprite_map.exit_closed, exit.x, exit.y, 2, 2)
        end
        palt()
        
        --map objects (rocks, puddles...)
        local objects = array_concat({rocks, puddles, pebbles, fires, snows, potions, leafs})
        for object in all(objects) do
            local sprite = 0
            if get_sprite(object.name) != nil then
                sprite = get_sprite(object.name) --animated sprites
            else
                sprite = sprite_map[object.name] --static sprites
            end
            spr(sprite, object.x, object.y, 1, 1)
            
            --if debug then --bounding boxes
                --local r = object.rect
                --rect(r.x1, r.y1, r.x2, r.y2, 11)
            --end
        end
        
        --spiders and beetles
        for bug in all(array_concat({spiders, beetles})) do
            local flip_x, flip_y = false, false
            if bug.name == "beetle" and bug.dir == -1 then flip_y = true end
            if moving >= 0 then
                local draw_x, draw_y = bug.from_x, bug.from_y
                local portion = (moving_time - moving)/moving_time
                if bug.name == "spider" then
                    if bug.dir == 1 then --spider going right
                        draw_x += abs(bug.x - bug.from_x)*portion
                    elseif bug.dir == -1 then --spider going left
                        draw_x -= abs(bug.x - bug.from_x)*portion
                    end
                elseif bug.name == "beetle" then
                    if bug.dir == 1 then --beetle going down
                        draw_y += abs(bug.y - bug.from_y)*portion
                    elseif bug.dir == -1 then --beetle going up
                        draw_y -= abs(bug.y - bug.from_y)*portion
                    end
                end
                spr(sprite_map[bug.name], draw_x, draw_y, 1, 1, flip_x, flip_y)
            else
                spr(sprite_map[bug.name], bug.x, bug.y, 1, 1, flip_x, flip_y)
            end
        end
        
        --mud
        --todo maybe: if we round the mud's size down to the nearest even number,
        --then it won't wiggle back and forth when moving in a straight line
        if mud.alive then
            palt(0, false)
            palt(7, true)
            if snow > 0 or potion > 0 then
                pal(4, 12) --brown to light blue
                pal(2, 1) --purple to dark blue
                pal(1, 13) --dark blue to... uh... grey?
            elseif leaf > 0 then
                pal(4, 11) --brown to light green
                pal(2, 3) --purple to dark green
            end
            if moving >= 0 then
                local draw_x, draw_y = mud.from_x, mud.from_y
                local portion = (moving_time - moving)/moving_time
                if mud.dir == "up" then
                    draw_y -= abs(mud.y - mud.from_y)*portion
                elseif mud.dir == "down" then
                    draw_y += abs(mud.y - mud.from_y)*portion
                elseif mud.dir == "left" then
                    draw_x -= abs(mud.x - mud.from_x)*portion
                elseif mud.dir == "right" then
                    draw_x += abs(mud.x - mud.from_x)*portion
                end
                sspr(64, 0, 24, 24, draw_x, draw_y, mud.size, mud.size)
            else
                sspr(64, 0, 24, 24, mud.x, mud.y, mud.size, mud.size)
            end
            pal()
            palt()
        end
        
        --mud bounding box
        if debug then
            local r = mud.get_rect()
            rect(r.x1, r.y1, r.x2, r.y2, 8)
        end
        
        --text
        if debug then print("size: "..mud.size.." x: "..mud.x.." y: "..mud.y, 0, 0, 2) end
    elseif mode == "end" then
        print("        victory is yours.\n")
        print("you have collected the pieces of\n")
        print("    the philosopher's stone.\n")
        print(" you are now made of solid gold.\n")
        print(" you are unable to move, because\n")
        print("       you are too heavy.\n")
        print("            the end")
        
        local x, y = 56, 100 --bottom left of the 2x2 mud sprite
        
        --philosopher's stone
        spr(96, x+20, y)
        
        --ending animation
        if end_timer <= end_delay then
            palt(0, false)
            palt(7, true)
            spr(8, x-4, y-16, 3, 3)
            palt()
        elseif end_timer <= end_delay*2 then
            spr(5, x-4, y-16, 3, 3)
        elseif end_timer <= end_delay*3 then
            spr(3, x, y-8, 2, 2)
        elseif end_timer <= end_delay*4 then
            spr(1, x, y-8, 2, 2)
        elseif end_timer <= end_delay*5 then
            spr(33, x, y-8, 2, 2)
        elseif end_timer <= end_delay*6 then
            spr(35, x, y-8, 2, 2)
        else
            spr(11, x, y-8, 2, 2)
        end
    end
end

function _update()
    --animate sprites
    for key,sprite in pairs(sprites) do
        inc_anim(sprite)
    end
    
    --update timer
    timer += 1
    
    --start game
    if mode == "title" then
        if btnp(5) then
            start_game()
        else
            return --no need to do anything else on the title screen
        end
    end
    
    --reset level
    if mode == "game" and btnp(5) then
        init_level(cur_level)
        return
    end
    
    --debug skip level
    if debug and mode == "game" and btnp(4) then
        next_level()
        return
    end
    
    if mode == "end" then end_timer += 1 end
    
    --if mud is not alive, then don't bother updating the game state
    if not mud.alive then return end
    
    --only check for player movement if mud is not currently moving
    if moving <= -1 then
        --move mud
        local dir = ""
        if btn(0) then
            dir = "left"
        elseif btn(1) then
            dir = "right"
        elseif btn(2) then
            dir = "up"
        elseif btn(3) then
            dir = "down"
        end
        if dir != "" then
            mud.move(dir)
        end
        
        if moving > 0 then --move spiders and beetles if mud moved
            foreach(spiders, move_spider)
            foreach(beetles, move_beetle)
        end
    end
        
    --do the "normal" game updates only if the mud just finished moving
    if moving == 0 then
        --moving is done
        moving -= 1
        
        --play sound if mud hit a wall
        if mud.bonked then
            sfx(17)
            mud.bonked = false
        end
        
        --update effect timers
        if potion > 0 then potion -= 1 end
        if snow > 0 then snow -= 1 end
        if leaf > 0 then leaf -= 1 end
        
        --break pebbles
        if mud.size >= pebble_break_size then
            local crushed = false
            for pebble in all(pebbles) do
                if collide(mud.get_rect(), pebble.rect) then
                    crushed = true
                    del(pebbles, pebble)
                end
            end
            if crushed then sfx(18) end
        end
        
        --grow mud
        local growth = 0
        if potion > 0 then
            growth = -mud.growth
        elseif snow <= 0 then
            growth = mud.growth
        end
        mud.grow(growth)
        
        if not mud.alive then return end --if mud is killed (by growth), we're done
        
        --adjust mud
        mud.adjust(growth)
        
        --collect goal
        if not goal.collected and collide(mud.get_rect(), goal.rect) then
            goal.collect()
            sfx(20)
        end
        
        --collide with snow
        for snow in all(snows) do
            if collide(mud.get_rect(), snow.rect) then
                add_snow(snow_time)
                del(snows, snow)
            end
        end
        
        --collide with potions
        for potion in all(potions) do
            if collide(mud.get_rect(), potion.rect) then
                add_potion(potion_time)
                del(potions, potion)
            end
        end
        
        --collide with leafs
        for leaf in all(leafs) do
            if collide(mud.get_rect(), leaf.rect) then
                add_leaf(leaf_time)
                del(leafs, leaf)
            end
        end
        
        --collide with puddles
        local shrinks = 0
        for puddle in all(puddles) do
            if collide(mud.get_rect(), puddle.rect) then
                shrinks += 1
                del(puddles, puddle)
            end
        end
        if shrinks > 0 then
            for i = 1,shrinks do
                mud.grow(puddle_growth)
            end
            sfx(19)
        end
        if not mud.alive then return end --if mud is killed, we're done
        
        --collide with fire
        for fire in all(fires) do
            if collide(mud.get_rect(), fire.rect) then
                mud.kill()
                sfx(24)
                return --if mud is killed, we're done
            end
        end
        
        --collide with bugs
        for bug in all(array_concat({spiders, beetles})) do
            if collide(mud.get_rect(), get_rect(bug)) then
                mud.kill()
                sfx(24)
                return --if mud is killed, we're done
            end
        end
        
        --exit
        if goal.collected and mud.size <= exit_size and collide(mud.get_rect(), exit.rect) then
            next_level()
        end
    elseif moving > 0 then --do the moving animation updates
        moving -= 1
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
65555565333333336655666600000000666666665555555500000000000000000000000000cc0cc000000000f44444444444444ff00000000000001f00000000
5666665533333b336566566600666600665665565556566500cc770000cccc0000cccc000ccccccc00006660f44444444444444ff10000000000000f00000000
6555556633333b33566665560d66666066666666565556650ccccc7007c7c7c00cccccc0cccccccc00d66616f44444444444444ff01000000000001f00000000
565556553333333366666665ddd666655666665655555555cc7ccccc7c7c7c7ccccccccccccccccc0ddd6166f444444aa444444ff10000000000010f00000000
556665553b33333366666665ddddd6556665566655565555cccccc7ccccccccccccccccc0cccccc0ddd11665f44444999944444ff01000000000001f00000000
565556553b33b33366666665dddddd556655556655555555cccc7cccc7c7c7c7ccccccccccccccccdd155155f444474aa494444ff10100000001010f00000000
655555653333b333566666555dddd5556666666556555565077cccc00c7c7c700cccccc0ccccccccd1555155f44449444494444ff01010101010101f00000000
55555556333333336555556605dd55505665566655556555000ccc00000ccc00000ccc000ccc0cc005555550ffffff9999ffffffffffffffffffffff00000000
00000000000000000000000000000b000000700000fff90000000000002277000777777000009000000000000000000000000000000000000000000000000000
007a980000009000007f0fe00000b3b00070607007aaaa90000070000722222000700700000a8200000000000000000000000000000000000000000000000000
0affa980000a820007feeee2000bb3b00006c600faa99aa4000077007727722700700700000f8200000090000000000000000000000000000000000000000000
89aa9982000f82000fee8ee200bb3bb0076c0c67fa9999a4000767002227722207000070000f8200000a82000000000000000000000000000000000000000000
89999982000f820000e8882000b3bb000006c6009a9999a407066607072222707cccccc7000a8200000f82000000000000000000000000000000000000000000
08999820000a8200000e8200003bb000007060709aa99aa40666d666000dd0007cccccc700009000000f82000000000000000000000000000000000000000000
0088820000009000000020000b0000000000700004aaaa200d6dd6d60006600007cccc7000000000000a82000000000000000000000000000000000000000000
000000000000000000000000b0000000000000000044420000ddddd0000770000077770000000000000090000000000000000000000000000000000000000000
ffff11fffff11ffffff11fff000000000077770020111102000000000000000000000000000000000000000000000000000000000000000000000000cccceeee
fffff11fff1111fffff11fff010000100778877020111102000000000000000000000000000000000000000000000000000000000000000000000000cccceeee
11111111f1f11f1ff1f11f1f101dd1017781687722111122000000000000000000000000000000000000000000000000000000000000000000000000cccceeee
fffff11ffff11fffff1111ff10dddd017811168700111100000000000000000000000000000000000000000000000000000000000000000000000000cccceeee
ffff11fffff11ffffff11fff008dd8007811118722dddd22000000000000000000000000000000000000000000000000000000000000000000000000eeeecccc
000440000004400000044000012002107781187720111102000000000000000000000000000000000000000000000000000000000000000000000000eeeecccc
000990000009900000099000102002010778877020311302000000000000000000000000000000000000000000000000000000000000000000000000eeeecccc
000ff000000ff000000ff000100000010077770000100100000000000000000000000000000000000000000000000000000000000000000000000000eeeecccc
35353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535
35353535353535353535353535353535353535353535353535353535353535350000000000000000000000000000000000000000000000000000000000000000
3500555555555555555555b455555535356565655557555555553565656565353555865535555555555535555555553535555555555555555555555555555535
3555555555355555555555555555553535865555553555b455553555555555350000000000000000000000000000000000000000000000000000000000000000
355555555755555555555555555555353565b4555555555555553565363665353555555555555555555535550055553535555555865555005555555555365535
35555555553555555555555516555535355555555535555555553555555555350000000000000000000000000000000000000000000000000000000000000000
35555555555555555555555555555535356555555555555555553565555565353555555555555555555535555555553535555555865555555555555555555535
35550055555555557474747474555535355555555555355555355555555555350000000000000000000000000000000000000000000000000000000000000000
3555655555555555556555655565553535555555555555553755a5a5a5a5a5353555555555555555375535555555553535555555555555555555555555555535
35555555555555555555555555555535355555555555555537555555865555350000000000000000000000000000000000000000000000000000000000000000
35555555555555555555555555555535355555555555555555555555555555353555555535555555555535555555553535747474747474747474743555555535
35555555355555a5a5a5a5a5a5555535355555550055555555555555555555350000000000000000000000000000000000000000000000000000000000000000
355536555555555555555555555555353555555555555555555555555555553535555555355555b4555555555555553535555555555555555555555555555535
355555553555555555a5b455a5553735355555555555555555555555553655350000000000000000000000000000000000000000000000000000000000000000
35555555555555555555555555555535355555555555554655553555555555353555555535655555555565555555553535551655555555465555555755655535
355555553555558686a55555a5555535355555865555555555865555555555350000000000000000000000000000000000000000000000000000000000000000
35355535353555555555375555555535355555555555555555553555165555353555555535366555555555555555553535555555555555555555555555555535
355555555555555555a5555555555535355555555555555555555555555555350000000000000000000000000000000000000000000000000000000000000000
35555555555555555555555555555535355555555555555555553555555555353555555555353535353535558655353535555555557474747474747474747435
355555555555555555a5465555555535355555555555555555553535353555350000000000000000000000000000000000000000000000000000000000000000
355555555555555555555555555555353555555555555555555535353555553535555555555555555555a5555555553535556555555555555555555555555535
35a5a5a5a5a565555546464655656535355555555586555555553555555555350000000000000000000000000000000000000000000000000000000000000000
355516555555555555555555555555353555555555555500555555555555553535555555555555555555a5555555553535555555655555556555555555556535
3555576565a5a5a5a5a5a5a5a5a5a535355555555555555555553555555555350000000000000000000000000000000000000000000000000000000000000000
35555555555555555555555555555535355555555555555555555555555555353555465555555516555555556555553535655555556555555555655555555535
3557555765a565655555555555653735355555555555365555555555165555350000000000000000000000000000000000000000000000000000000000000000
355565555555555555655565556555353555555555555555555555558655553535555555555555555555a5555555553535556565555565555555555555b45535
3555555557a565555555375555555535355555555555555555553555555555350000000000000000000000000000000000000000000000000000000000000000
355555555555555555555555555555353555555555555555555555555555553535555555555555555555a5555555553535555555555555555555375555555535
3555555555a555555555555755375735355555555555555555553555555586350000000000000000000000000000000000000000000000000000000000000000
35353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535
35353535353535353535353535353535353535353535353535353535353535350000000000000000000000000000000000000000000000000000000000000000
__map__
5353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353
53555555555a555555555555555555535355555553555555555555555555555353555555555555555555555555555553535655555555555555555555555561535300555556555555555555555555555353555555555a555555555a5555556153535a5a5a5a5a5a4b555a5a5a5a5a5a5353555a5a5a5a5a5a5a5a5a5a5a5a5553
53555556555a556155555555555555535355555555555555555655555555555353555555555555555555555555555553535555555555555555555555555555535355555555555555555555555555555353555555555a555555555a555555555353555a5a5a5a5a55555a5a5a5a5a555353555a56555555555555556455550053
53555655555a555555555555555555535353555500555555555555555555555353555555555555565555555555555553535555555555555555555555555555535355555556555555555555555555555353555555555a555555555a55555555535355555a5a5a5a5a5a5a5a5a5a5a555353555a55555555555555555555555553
53565556555a5a5a5a5a5a55555555535355555555554b5555565555555555535355565555555555555555555655555353555555555555555555555a5a5a5a5353565556555555555555555555555553535555555553555555555a5555555553535555555a555a5a5a555a5a5a55555353555a55555a5a5a5a5a5a5a5a5a5553
535556555555555555555a555555555353555555555555555555555555555553535555555555555555555555555555535355555555535353535355555555555353555555555555555555555555555553535555555553556455555a55555555535355555556555555555555555555555353555a55555a55555555555555555553
535655565555555555555a5555555553535555555a555555555553555555555353555555555555555555555555555553535655555555554b555555555655555353555555555555555555555555555553535555555553555555555a55555555535355555655555556555555555556555353555a55555a554b5555555555555553
535556555555555555555a554b555553535555555555555555555555555555535355555555555555555555555555555353565555555555555555555555555553535a5a5a5a5a535353535a5a5a5a5a53535555555553555555555355555555535355555555555655555555555655555353555a56555a55555555555555555553
535655565555550055555a55555555535355555555555555555555555555555353555555555555005555555555555553535555555555550055555555555555535355555555555353535355555555555353555555555a550055555355555555535355555555555555555555555555555353555a55555a5555555a555568555553
535556555655555555555a55555555535355555555555555555555555355555353555655555555555555555561555553535555555555555555555555555555535355555555555353535355555555555353555555555a555555555355565655535355555555555555555655555555555353555a55555a555a5a55555555555553
535655565556555555555a5a5a5a5a535355555553555555555555555555555353555555555555555555555555555553535a5a5a5a5a5a5a5a5a5a5a5a5a5a535355555555555555555555555555555353555555555a555555555355565655535355555655555555615555555555555353555a55555a5a555555555555555553
53555655565556555555555555555553535555555555565561555555555555535355555555555555555555554b555553535555555555555555555555555555535355555555555555555555555555555353555555555a555656555a55555555535355565555555555555555555555555353555a55555555555555555555555553
535655565556555655555555555555535355555555555555555555555555555353555555555555565555555555555553535555565556555655565556555655535355555555555555565555555656565353555555555a555656555a55555555535355555555555555555555555556555353555a56555555555655555555556153
53555655565556555655565556555553535555555555555555555555555555535355555555555555555555555555555353555655565556555655565556555553535555555555555555555555564b5553534b5555555a555555555a55555555535355555555565555555555555655555353555a5a5a5a5a5a5a5a5a5a5a5a5553
535555565556555655565556555655535355555555555555555555555555555353555555555555555555555555555553535555555555555555555555555555535361555555555555555555555655555353555555555a555555555a55555555535355555556555500555555555555555353555555565555565555565555565553
5353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353
5353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353
535555555555554b555555555555555353555555555555555555555555556853534b555555555555555555555555555353555555554755555555535555535553535555555555554b5555555555555553535555555555555555555575555555535368555568535555555547554b55555353555555735555555555555555555553
53555555555555555555555555555553535555555555555555555568555555535355555555555555555555555555555353555561555555555555534b5553555353555555555555555555555555555553535555555555555575555555555555535355555555535555555547555555555353555573555555555555555555555553
5355555555556868686855555555555353555555555555685555555555555553535555555555555555555555555555535355555555555564555555555555555353555555555555685555555555555553535555555575555555555555555555535355555555535555555547555555555353735555555555555555555555555553
53555555555353535353535555555553535353535355555555685555556855535355555555555555555555555555555353554747475555555555535a5a53555353555555555555555555555555557353535555555555555555555555555555535355555555535555557347555555555353555555735555555555555555555553
5353615353535555555553555555555353555555555555555555555555555553535555474747474747474747474747535355555555555555555555555555555353555555555555555555555555555553535555555555565555565555565555535355555555535555555547555555555353557355555555555555555555555553
53555555555a55555555555555555553535561555a5555005555556855555553535655555547555555555555555555535355555555565555555555555555555353555555555555555555555555555553534b55555555555555555555555555535355555555535555555547555555555353735555555555555555555555555553
53555555555a55555555555555555553535555555a55555555555555555555535355555555475555555555555555555353555555555555555555556455555553535555555555550055555555555555535355555555555555555555555555555353555555555355555555475555555553535555735555555555555555554b5553
53555555555a55005555555564555553535555555a5555555555555555685553535655555547555555555555555555535355555555005555555555555555555353555555555555555555555555555553530055555655555655555655555661535355555555535555555547555555555353557355550063555555615556555553
53555555555a55555555555555555553535353535353535553535a5a5a5a5a53535555555547555555555555555555535355555555555555555555555555555353555555555555555555555555555553535555555555555555555555555555535355555555555568685555555555555353735555555555555555555555555553
53555555555a5555555555555555555353555555555555555555555555555553535655555547555555555555555555535355555555555555555555645555555353735555555555555555555555555553535555555555555555555555555555535355555555555555555555555555555353555573555555555555555555555553
53555555555a5555555555555555555353555555555555555555555555555553535555555555555555556455555555535355555555555555555555555555555353555555555555685555555555555553535555555555555555555555555555535355555555555500555555555555555353557355555555555555555555555553
53565656555a5555555555555656565353555555555555555555555555555553535655615555555555555555555555535355565556555655565556555655565353555555555555555555555555555553535555555555555555555555555555535355555573555555555555555555555353555555735555555555555555555553
53565656555a55555555555556565653535555555555554b5555555555555553535555555555555555555555555555535355555555555555555555555555555353555555555555615555555555555553535555555555555555555555555555535355645555555555555555555555555353557355555555555555555555555553
53565656555a555555555555565656535355555555555555555555555555555353565555555a555555555555555500535355555555555555555555555555555353555555555555555555555555555553535555555555555555555555555555535355555555555561555555555555555353555555735555555555555555555553
5353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353
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
011800100c433004030c633004030c433004030c6330c6030c433004030c4330c6030c4330c6330c4330c4030c4030c4030c6030c4030c6030c4030c4030c4030c4030c603004030c4030c6030c4030c40300000
011800002f73000000000002d7302b73000000267300000024730000002673000000237302373023730237302f73000000000002d7302b730000002d730000002f7300000030730000002d7302d7302d7302d730
011800002f73000000000002d7302b730000002673000000247300000026730000002a730000002d730000002b7302b730247002a7002a730000002b730000002a730000002b7302b7302b730000002f70000000
011800002f73000000000003073032730000003273000000347300000032730000002b7302b7302b7302a7052f73000000000002b7302d730000002f73000000327300000030730000002f7302f7302f73000000
011800002f7300000000000307303273000000327300000034730000003473032730000002d7302d730000002f7302f730000002d7302b730000002d7300000030730000002f7302b730000002a7302b73000000
000c00000400004000040000400006000060000600006000070000700007000070000200002000020000200004000040000400004000060000600006000060000700007000070000700000000000000000000000
0109000024b3024b3024b3029b3029b3029b302db302db302db3024b3024b302bb302bb302fb302fb302fb3030b3030b3030b3030b3030b3030b3030b0030b0030b0030b0000b0000b0000c000ec0012c0000c00
000c0000170501d0501e0501a050130501205014050180501c0501b050160500f0500b0500e0500c0500805003050010500100001000010300103001030010300100001000010000100001000010000000000000
01010000261501c15017150101500b1500715004150011500b100081000710004100021000110023a000000024e0024e000000024e0022e0021e00000001be0018e0013e000ee0005e0001e00000000000000000
00010000206501b6501765013650126500f6500d6500c6500c6500b6500b6500b6500b6500c6500c6500b6500b6500a640086300662001610016002d0002d00009600036000a300056000b300000000000000000
0101000020f5227f522df5231f5236f5221f5227f522bf522df521cf5234f5222f5229f5231f5236f5233f5201f523df5222f0221f021ff021cf021af0218f0216f0215c001370011700101000e1000d0000c000
010100001185030850308503085030850308503085000800008000080000800008003b850398503b850008003c8503c8503c8503c8503c8503c8503c850008000080000800008000080000800008000080000800
000100003e7503e750000003e7503e750000003d750000000000037750377500000037750377503775000000000003c7503c75000000000003c7503b75000000000003a7500000000000000003b7503975000000
00030000040500a05010050170500a0500f050160501e0500f050160501c05026050190501e050250502c0501d050260502e05036050280502d050340503d0503f0003d0000200001000010000f0002200036000
0001000002e5004e5007e5007e5006e5005e5003e5003e5004e5006e5007e5008e5008e5006e5005e5004e5002e5001e5001e5002e5002e5022e0024e0001e0004e0007e000ee000be000ee0010e000ce0015e00
010300003c6443c6453c6343c6343c6253c6243c6253c615300053000530005300053000500004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000323502e3502a35027350253502235021350223502435025350273502635024350213501e3501a350173501535014350123501235015350193501c3501d3501e3501e3501d3501b3501a3501735014350
0001000036550335502e5502e550195501b5501e5501f550225501e55016550145502b5502e5503455034550325502d5502b55025550215501f55035550315502f55024550275502b55030550355503a5503d550
0002000014f5038f5038f5016f5037f501ef5037f5037f501af5039f5027f5037f5037f502ff5038f5020f5030f5025f5027f503af502af503bf503bf502ef5037f502ef5034f5025f5038f501ef501bf503df50
00010000182501c250292502e250302001b2501e25032200332502c2503925039250372501d20020250242502c2502c25022200222002420025200262002720025200292002b2002b2002d2002d2002f20032200
0004000034c5039c5034c502dc5026c5024c5027c502bc5032c5036c503bc503fc503cc5038c5034c502ec5000c0000c0000c0000c00000000000000000000000000000000000000000000000000000000000000
013200001a55018550135501555011550115500c5500e5501155015550135500c5501555015550135501355015550155501855018550165501655015550155501a5501c55021550215501c5501c5501855018550
0132000015550155501a5501c5501f550215501d550215501f5501d5501c5501f5501d5501d5501a5501c5501d5502255022550215501f5501d550185501a5500000000000000000000000000000000000000000
__music__
01 090a4e44
00 090b4f44
00 090c4e44
00 090d4344
02 094e0e44
01 1e424344
02 1f424344


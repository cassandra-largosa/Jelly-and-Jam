pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--jelly and jam
--by spaghetti time
--cartdata("jelly and jam")

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
slime_a = {0,0,2,2,4,4,6,6,4,4,2,2}

sprites = {}
add_sprite("slime", slime_a)

--hitbox stuff
function make_hit(x1, y1, x2, y2)
    return {x1=x1, y1=y1, x2=x2, y2=y2}
end

function make_rect(hit, x, y)
    local x1 = hit.x1+x
    local y1 = hit.y1+y
    local x2 = hit.x2+x
    local y2 = hit.y2+y
    return make_hit(x1, y1, x2, y2)
end

function get_rect(object)
    local name = object.name
    --if n == "fire"
        --return make_rect(fire_h, object.x, object.y)
    --elseif ...
end

function collide(r1, r2)
    if r1.x2 < r2.x1 or r1.x1 > r2.x2 or r1.y2 < r2.y1 or r1.y1 > r2.y2 then
        return false
    end
    return true
end

--hitboxes (x1, y1, x2, y2)
slime_h = make_hit(4,2,11,7)

--constants
--...

--status stuff
score = 0
mode = "title" --title, menu, play, dead
title_time = 0
dead_time = 0
song = "main" --main, rainbow

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

--spawning objects
function spawn(name)
    
end

function _draw()
    cls()
end

function _update()
    --animate sprites and bg
    for key,sprite in pairs(sprites) do
        inc_anim(sprite)
    end
end

__gfx__
00000000000068000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000060680000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700006860600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000006666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000006060600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700006666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000066646660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000066646660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000001010100000001010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000001000101000001010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000001000001000100010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000010000010001010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100001e0501f0501f0501f05020050210500000022050230500000024050000002605027050000002805000000280502705023050210501d0500000018050110500b050070500705000000000000000000000
001000001805018050180501a0501c0501d0501a0501a0501c0501a05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 01424344


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
--slime_a = {0,0,2,2,4,4,6,6,4,4,2,2}

sprites = {}
--add_sprite("slime", slime_a)

sprite_map = {none = 0,
              rock = 83,
              floor = 85}

--hitbox stuff
function make_hitbox(x1, y1, x2, y2)
    return {x1=x1, y1=y1, x2=x2, y2=y2}
end

function make_rect(hit, x, y)
    local x1 = hit.x1+x
    local y1 = hit.y1+y
    local x2 = hit.x2+x
    local y2 = hit.y2+y
    return make_hitbox(x1, y1, x2, y2)
end

function get_rect(object)
    local name = object.name
    --if name == "fire"
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
hitbox_map = {rock = make_hitbox(0, 0, 7, 7)}

--constants
--...

--status stuff
temp = 0

--level stuff
cur_level = -1

function get_start(level)
    --returns an object representing where the mud starts for the level
    return get_map_objects("none", level)[1]
end

function next_level()
    cur_level += 1
    local start = get_start(cur_level)
    mud.x, mud.y = start.x, start.y
    local cel = screen_to_map(mud.x, mud.y, cur_level)
    mset(cel.cel_x, cel.cel_y, sprite_map.floor)
end

function start_game()
    cur_level = 0
    next_level()
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

--object stuff
function spawn(name)
    
end

function get_map_objects(name, level)
    --returns a list of objects with the given name found on the map for the given level
    local objects = {}
    local cel = screen_to_map(0, 0, level)
    local start_x = cel.cel_x
    local start_y = cel.cel_y
    local sprite = sprite_map[name]
    local hitbox = hitbox_map[name]
    
    for cel_y = start_y,start_y+15 do
        for cel_x = start_x,start_x+15 do
            if mget(cel_x, cel_y) == sprite then
                local object = {name = name,
                                x = map_to_screen(cel_x),
                                y = map_to_screen(cel_y)}
                if hitbox != nil then
                    object.rect = make_rect(hitbox, object.x, object.y)
                end
                add(objects, object)
            end
        end
    end
    return objects
end

--mud stuff
mud = {x = 0, y = 0, --x and y as pixel values
       speed = 4, --step distance in pixels
       size = 8, --mud diameter in pixels
       growth = 0.5 --how much to grow radius each step in pixels
       }
mud.get_rect = function()
                   return make_hitbox(mud.x, mud.y, mud.x+mud.size-1, mud.y+mud.size-1)
               end

function move_mud(dir)
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
    
    local moved = mud_fits()
    if not moved then
        mud.x, mud.y = x, y
    end
    
    return moved
end

function mud_fits()
    --return whether the mud is allowed to be where it is
    local mud_rect = mud.get_rect()
    
    for rock in all(get_rocks(cur_level)) do
        if collide(mud_rect, rock.rect) then
            return false
        end
    end
    
    return true
end

function grow_mud()
    mud.size += mud.growth*2
    mud.x -= mud.growth
    mud.y -= mud.growth
end

--rock stuff
function get_rocks(level)
    return get_map_objects("rock", level)
end

function _draw()
    cls()
    
    --background
    local cel = screen_to_map(0, 0, cur_level)
    local cel_x = cel.cel_x
    local cel_y = cel.cel_y
    map(cel_x, cel_y, 0, 0, 16, 16)
    
    --mud
    --todo maybe: if we round the mud's size down to the nearest even number,
    --then it won't wiggle back and forth when moving in a straight line
    sspr(64, 0, 24, 24, mud.x, mud.y, mud.size, mud.size)
    
    --mud bounding box
    local r = mud.get_rect()
    rect(r.x1, r.y1, r.x2, r.y2, 8)
    
    --rock bounding boxes
    for rock in all(get_rocks(cur_level)) do
        rect(rock.rect.x1, rock.rect.y1, rock.rect.x2, rock.rect.y2, 11)
    end
    
    --text
    print("size: "..mud.size.." x: "..mud.x.." y: "..mud.y, 0, 0, 2)
    --print("temp: "..temp)
end

function _update()
    --animate sprites
    for key,sprite in pairs(sprites) do
        inc_anim(sprite)
    end
    
    --start game, if necessary
    if cur_level < 0 then start_game() end
    
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
        local moved = move_mud(dir)
        if moved then
            grow_mud()
            --todo: adjust mud position after growth
        end
    end
end

__gfx__
00000000000000000000000000000ff77ff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000aa444444aa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000944444444449000000000044444444000000000000000044444444000000000000000000000000000000000000000000000000
00077000000000000000000009444444444444900000004424444444440000000000004424444444440000000000000000000000000000000000000000000000
00077000000000000000000009444444444444900000444442224444444200000000444442224444444200000000000000000000000000000000000000000000
00700700000000000000000094444444444444490004244424444244424420000004244424444244424420000000000000000000000000000000000000000000
00000000000000f77f00000044444444444444440044422244424422244442000044422244424422244442000000000000000000000000000000000000000000
000000000000af4444fa000044444444444444440244444444244444442442200244444444244444442442200000000000000000000000000000000000000000
00000000000944444444900044444444444444440424444422442444444224200424444422442444444224200000000000000000000000000000000000000000
00000000004444444444440024444444444444422442222244224442442444422442222244224442442444420000000000000000000000000000000000000000
00000000044444444444444022444444444444222444422222444444224444422444422222444444224444420000000000000000000000000000000000000000
00000000244444444444444204244444444442402444444444444444444444422444444444444444444444420000000000000000000000000000000000000000
00000000224444444444442202424444444424204244422444444222444442244244422444444222444442240000000000000000000000000000000000000000
00000000222424242424222200242424424242004422244244442444244224244422200244442444244224240000000000000000000000000000000000000000
00000000022242424242422000024242242420002442422422224444422442422442422422224444422002420000000000000000000000000000000000000000
00000000002222222222220000000222222000004224444444444444444224424224444444444444444224420000000000000000000000000000000000000000
00000000000000000000000000000000000000002444444444444444444442242444444444444444444442240000000000000000000000000000000000000000
00000000000000000000000000000000000000002424422444444222444224422424422444444222444224420000000000000000000000000000000000000000
00000000000000000000000000000000000000000242244244422444222444200242244244422202222444200000000000000000000000000000000000000000
00000000000000000000000000000000000000000244422422244444444424200244422422220212000224200000000000000000000000000000000000000000
00000000000000000000000000000000000000000022244444444444422442000022244420021211122442000000000000000000000000000000000000000000
00000000000000000000000000000000000000000002422442244422244220000002422442211111244220000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000224224422244422200000000224224422222422200000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000002222222222220000000000002222222222220000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3333c1c33333333b3333333338383833333333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
333c1a1cb333333b33333b33338883333e3333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33eecee3b33b333333333b33333833333b3333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
32ee8ee3333b333333333333333bb3333b3333c30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2a28a83333333b333b333333333b33b3333233b30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
32ee8e733b333b333b33b3333b3333b3333b33b30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33eeb7973b3b333b3333b3333b333333333b33330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3333b373333b333b3333333333333333333333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65555565055555056655666600000000666666665555555500000000000000000000000000cc0cc0000000000000000000000000000000000000000000000000
56666655500000556566566600666600665665565556566500cc770000cccc0000cccc000ccccccc000000000000000000000000000000000000000000000000
6555556605555500566665560d66666066666666565556650ccccc7007c7c7c00cccccc0cccccccc000000000000000000000000000000000000000000000000
565556555055505566666665ddd666655666665655555555cc7ccccc7c7c7c7ccccccccccccccccc000000000000000000000000000000000000000000000000
556665555500055566666665ddddd6556665566655565555cccccc7ccccccccccccccccc0cccccc0000000000000000000000000000000000000000000000000
565556555055505566666665dddddd556655556655555555cccc7cccc7c7c7c7cccccccccccccccc000000000000000000000000000000000000000000000000
6555556505555505566666555dddd5556666666556555565077cccc00c7c7c700cccccc0cccccccc000000000000000000000000000000000000000000000000
55555556555555506555556605dd55505665566655556555000ccc00000ccc00000ccc000ccc0cc0000000000000000000000000000000000000000000000000
00000000000000000000000000000b000000700000fff90000000000000000000000000000000000000000000000000000000000000000000000000000000000
007a980000009000007f0fe00000b3b00070607007aaaa9000007000000000000000000000000000000000000000000000000000000000000000000000000000
0affa980000a820007feeee2000bb3b00006c600faa99aa400007700000000000000000000000000000000000000000000000000000000000000000000000000
89aa9982000f82000fee8ee200bb3bb0076c0c67fa9999a400076700000000000000000000000000000000000000000000000000000000000000000000000000
89999982000f820000e8882000b3bb000006c6009a9999a407066607000000000000000000000000000000000000000000000000000000000000000000000000
08999820000a8200000e8200003bb000007060709aa99aa40666d666000000000000000000000000000000000000000000000000000000000000000000000000
0088820000009000000020000b0000000000700004aaaa200d6dd6d6000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000b0000000000000000044420000ddddd0000000000000000000000000000000000000000000000000000000000000000000000000
ffff11fffff11ffffff11fff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccceeee
fffff11fff1111fffff11fff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccceeee
11111111f1f11f1ff1f11f1f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccceeee
fffff11ffff11fffff1111ff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccceeee
ffff11fffff11ffffff11fff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeecccc
000440000004400000044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeecccc
000990000009900000099000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeecccc
000ff000000ff000000ff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeecccc
__map__
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f55555555555555555555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f55555555535555555555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f55555555555555555555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f55535555005555555555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f55555555555555555555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f55555555555555555555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f55555555535555555555535555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f55555555555555555555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f55555555555555555555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f55555555555555555555555553555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f55555555535555555555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f55555555555555555555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f55555555555555555555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f55555555555555555555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f55555555555555555555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f55555555555555555555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100041805018050180301803018000180001800018000180001800018000180001800018000180001800018000180001800018000180001800018000180001800018000180001800018000180001800018000
000100081885018850188501885018750187501875018750188001880018800188001870018700187001870018800188001880018800187001870018700187001880018800188001880018700187001870018700
00010410187511875118751187511a7511a7511c7511c7511d7511d7511c7511c7511a7511a75118751187540020100200162000020015a000000014a0013a0013a0000000000000000000000000000000000000
00010008183501835018350183500c3500c3500c3500c350183001830018300183001830018300183001830018300183001830018300183001830018300183001830018300183001830018300183001830018300
0001000f1855018550185501855029550295501a550235501f5501d550295501f5500d550155502c5501850018500185001850018500185001850018500185001850018100181001810018100181001810018100
000100200e5501355015550185501d5501f550225502355025550265502755028550285502855028550275502655024550225501f5501c550135500e550275502a5502d5502d5502b550265501f5501155007550
010100021805018000180001800018000180001800018000180001800018000180001800018000180001800018000180001800018000180001800018000180001800018000180001800018000180001800500000
0101060a2475123751217511f7511d7511c7511a75118751177511875110f000ef000cf0009f0008f0006f0005f0003f0002f0001f0011b001fd0011b001fd0022c0023c001ed0012d001dd001dd001dd0021e00
0110000018f5018f5018f5023f5023f5021f501af5021f501cf501ff501ff501ff501af501df501df501df5018f501ff501af501ff501cf5021f5021f5021f501ff5023f501cf5023f501af501ff5018f5018f50
__music__
00 01424344


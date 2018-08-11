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
gridsize = 4 --size of grid for moving in pixels

--status stuff
--...

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

--mud stuff
mud = {x = 7, y = 7, --x and y as grid values
       size = 8, --mud diameter in pixels
       growth = 1 --how much to grow each step in pixels
       }

function move_mud(dir)
    if dir == "up" then
        mud.y -= 1
    elseif dir == "down" then
        mud.y += 1
    elseif dir == "left" then
        mud.x -= 1
    elseif dir == "right" then
        mud.x += 1
    end
end

function _draw()
    cls()
    
    --background
    map(0, 0, 0, 0, 16, 16)
    
    --mud
    --padding = half the difference between the mud size and its smallest grid bounding box,
    --eg, the whitespace if the mud is centered on a bounding grid area
    local padding = (ceil(mud.size/gridsize)*gridsize - mud.size)/2
    sspr(24, 0, 16, 16, mud.x*gridsize + padding, mud.y*gridsize + padding, mud.size, mud.size)
    
    --text
    print("size: "..mud.size)
end

function _update()
    --animate sprites and bg
    for key,sprite in pairs(sprites) do
        inc_anim(sprite)
    end
    
    --move and grow mud
    local dx, dy = 0, 0
    if btnp(0) then
        move_mud("left")
        dx -= 1
    end
    if btnp(1) then
        move_mud("right")
        dx += 1
    end
    if btnp(2) then
        move_mud("up")
        dy -= 1
    end
    if btnp(3) then
        move_mud("down")
        dy += 1
    end
    if dx != 0 then mud.size += mud.growth end
    if dy != 0 then mud.size += mud.growth end
    
    --test stuff
    --chicksize += 1
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccceeee
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccceeee
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccceeee
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccceeee
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeecccc
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeecccc
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeecccc
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeecccc
__map__
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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


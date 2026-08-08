function chunk_load (name)
    --local save = love.filesystem.read ('maps/'..name..'.map')
    local save = love.filesystem.read (name..'.map')
    
    if not save then
        save = love.filesystem.read ('maps/'..name..'.map')
    end
    
    save = binser.deserialize(save)
    return save[1]
end

function chunk_map (y,x,a,border,chunk)

    border = border or 0
    chunk = chunk or {}
    
    local av,vv
    av = #a
    vv = #a[1]

    --for i=y-av-border,y+av*2+border do
    --for ii=x-vv-border,x+vv*2+border do

    for i=y-border,y+av+border do
    for ii=x-border,x+vv+border do

            --writemap (i,ii,neibors(i,ii),'n')
            writemap (i,ii,255,'n')
            writemap(i,ii,1,'r')
    
    end 
    end


    for i,v in ipairs(a) do
        for ii,vi in ipairs(v) do
        

            local wa = tabledeepcopy(a[i][ii])

            wa.g = nil
            wa.g = readmap (y+i-1,x+ii-1,'g')
            wa.n = 255

            if chunk and chunk.replace and chunk.replace[wa.b] then
                local r = chunk.replace[wa.b]
                if type (r)=='table' then r = loot_make (r) end
                wa.b = r 
            end

            if wa.b == 53 and chunk and chunk.mob then
                wa.mob = chunk.mob
            end


            if wa.t then wa.t = 0 end

            --writemap (y+i-1,x+ii-1,{},'clear')
            if chunk.ignore==nil or chunk.ignore~=wa.b then
                writemap (y+i-1,x+ii-1,wa,'all')
            end

        end
    end




end


function chunk_check (x,y,w,h,no)
    
    local f = false

    for i=1,h do
        for ii=1,w do
            local b = readmap (x+i-1,y+ii-1,'b') or 0

            if no == 0 and b == 0 then
                return true
            end

            if no == 1 and b ~= 0 then
                return true
            end

        end
    end

end




function make_biome (x,y,radius,rep,repg)
    rep = rep or {}
    repg = repg or {}

    for ix=math.max(1,x-radius),math.min(x+radius,cf.wmax) do
        for iy=math.max(1,y-radius),math.min(y+radius,cf.wmax) do
        
            local dist = math.ceil (math.dist (x,y,ix,iy))
            if dist<radius then

                local r = rep[readmap (ix,iy,'b')]

                if type(r) == 'table' then r = loot_make (r) end

                if r then
                    writemap (ix,iy,r)
                else

                        local b = readmap (ix,iy,'b')
                        local g = readmap (ix,iy,'g')
                        local r = repg[g]

                        if type(r) == 'table' then 

                                if (b==0 and g==-1) or g~=-1 then

                                    r = loot_make (r)
                                    if r then 
                                        writemap (ix,iy,r) 
                                    end
                                    
                                end

                        end
                    
                end

            end
        
        end
    end
end


-- MAPGEN
--------------------------------------------------------------

function do_map ()

    ::redo::
    world = {}

    love.thread.getChannel( 'geninfo' ):push(1)
    mapgen.new ()
    mapgen.fill (1,1,cf.wmax,cf.wmax,{seed = os.time(), line=10, line2=0, pc=0.6})
    mapgen.pass (1,1,cf.wmax,cf.wmax,{r=0.15, rpass=2, pass=5, seed=1, grow=1})
   -- mapgen.supersize (1,1,cf.wmax,cf.wmax)
    mapgen.pass (1,1,cf.wmax,cf.wmax,{r = 0.21, rpass = 0, pass = 2, dpass = 9})

    

    -- for ix=1,cf.wmax do
    --     for iy=1,cf.wmax do
    --         local dist = math.floor (math.dist (pl.startx,pl.starty,iy,ix))

    --         if dist<10 then
    --             mapgen.grid[iy][ix] = 1
    --         end
    --     end
    -- end

    


    -- 1st fill 
    love.thread.getChannel( 'geninfo' ):push(2)
    for ix=1,cf.wmax do
    for iy=1,cf.wmax do
            
        if world[ix]==nil then world[ix] = {} end
        if world[ix][iy]==nil then world[ix][iy] = {} end

        local g = mapgen.grid[iy][ix]
        world[ix][iy].g = g

        if g<1 then
            world[ix][iy].b = 0
        else
            world[ix][iy].b = 1
        end


    end
    end



    love.thread.getChannel( 'geninfo' ):push(3)

    -- finding start loc
    local br
    local xs, ys
    local ll = {}

    for iy=pl.starty-50,pl.starty+50 do
    for ix=pl.startx-50,pl.startx+50 do
    
        local cm = world[iy][ix]
        local cm2 = world[iy][ix+3]


        --if cm.cave and cm.cave>200 and 
        if cm.g == -1 and cm2.g == -1 
        and chunk_check (ix-1,iy-9,10,6,1)==nil
        then
                table.insert (ll,{ix,iy})
            

        end

    end
    end
    
-- HERE
    
    if #ll == 0 then
        love.thread.getChannel( 'geninfo' ):push(4)
        goto redo
    end

    love.thread.getChannel( 'geninfo' ):push(5)
    ll = ll[love.math.random (1,#ll)]
    xs = ll[1]
    ys = ll[2]


    pl.starty = ys - 8
    pl.startx = xs

    game.start = {}
    game.start.truex = pl.startx * cf.w - 32
    game.start.truey = pl.starty * cf.h + 32


    vi.xtile   = pl.startx
    vi.ytile   = pl.starty

    pl.startheight1 = pl.starty + 1
    pl.startheight2 = pl.starty + 12





-- CAVE COUNT
love.thread.getChannel( 'geninfo' ):push(6)
function mapgen.cavecount (x,y,min)

   if readmap (x,y,'b')==0 then
     return math.min (readmap (x+1,y,'cave') or min,
     readmap (x-1,y,'cave') or min,
     readmap (x,y+1,'cave') or min,
     readmap (x,y-1,'cave') or min)
   end

   return nil

end


local cmax = 1
for i=1,5 do

    for ix=1,cf.wmax do
    for iy=1,cf.wmax do

        local m = mapgen.cavecount (ix,iy,cmax)

        if m then
            local cm = readmap (ix,iy,'cave') or 0

            cmax = cmax + 1

            if m~=cm then 
             writemap (ix,iy,m,'cave')
            end
        end

    end
    end

    for ix=cf.wmax,1,-1 do
    for iy=cf.wmax,1,-1 do

        local m = mapgen.cavecount (ix,iy,cmax)

        if m then
            local cm = readmap (ix,iy,'cave') or 0

            cmax = cmax + 1

            if m~=cm then 
             writemap (ix,iy,m,'cave')
            end
        end

    end
    end



end

cave = {}
for ix=1,cf.wmax do
for iy=1,cf.wmax do
    local cm = readmap (ix,iy,'cave') or 0
    cave[cm] = (cave[cm] or 0) + 1
end
end

--dump (cave)

for ix=1,cf.wmax do
for iy=1,cf.wmax do
    local cm = readmap (ix,iy,'cave') or 0
    writemap (ix,iy,cave[cm],'cave')
    if readmap (ix,iy,'b')==1 then
        writemap (ix,iy,0,'cave')
    end
end
end




love.thread.getChannel( 'geninfo' ):push(7)

if true then

    -- fill 
    for ix=1,cf.wmax do
    for iy=1,cf.wmax do

        g = world[ix][iy].g
        world[ix][iy].b = 0

        -- path
        if ix > pl.startheight1 and ix < pl.startheight2 then

            
            local b = loot_make ({
            {i=1,p=70},
            {i=8,p=10},
            {i=9,p=5},
            {i=99,p=10},
            })

            if g<0 then
                b = 0
            end

            if g == 0 then 
                b = 0 
            end

            if g == 1 or g == 2 then
                b = 1
            end

            if g>2 then
                 b = loot_make ({
                {i=1,p=20}, -- dirt
                {i=99,p=10}, --thin dirt
                {i=35,p=5}, --stone
                {i=9,p=2}, --clay
                {i=136,p=1}, --pure clay
                {i=18,p=1}, --water
                {i=8,p=5}, --stones
                

                --{i=147,p=5}, --ectoplasm
                })
            end
            
            --world[ix][iy].b = b
            writemap (iy,ix,b)


        else

            local b = loot_make ({
            {i=1,p=70},
            {i=8,p=10},
            {i=9,p=5},
            {i=99,p=10},
            })

            if g < 1 then 
                b = 0 
            end

            local dist = math.dist (pl.startx,pl.starty,iy,ix)
            
            if g==-1 and dist>20 then
                b = loot_make ({
                {i=0,p=130},
                {i=95,p=20}, --spiny
                {i=37,p=10}, --clover
                {i=188,p=5}, --stacked rocks
                {i=127,p=20}, --manna
                --{i=147,p=5}, --ectoplasm
                })
            end

            

            -- local done
            -- dist = dist / 2
            -- dist = math.log (dist)


            if g == 2 then
                b = loot_make ({
                {i=177,p=5}, -- stonelouse
                {i=1,p=70},
                {i=8,p=30}, --stone
                {i=9,p=2}, --clay
                {i=136,p=2}, --pure clay
                })
            end


            if g == 3 then

                b = loot_make ({
                {i=1,p=95},
                {i=99,p=5},
                {i=9,p=2}, --clay
                {i=136,p=2}, --pure clay
                {i=60,p=10}, --sand
                })

            end


            if g == 4 then -- dense ground
                b = loot_make ({
                {i=32,p=60},
                {i=31,p=20},
                {i=1,p=5},
                {i=8,p=10}, --stone
                {i=9,p=4}, --clay
                {i=99,p=5}, --thin dirt
                {i=63,p=4}, --copper
                {i=35,p=2}, --stone block
                {i=19,p=2}, --salt
                {i=18,p=1}, --water
                {i=80,p=1}, --coal
                


                })
            end

            if g >= 5 then -- denser ground
                b = loot_make ({
                {i=32,p=10},
                {i=31,p=70},
                {i=1,p=5},
                {i=9,p=2}, --clay
                {i=107,p=2}, --peat
                {i=99,p=5},
                {i=63,p=3}, --copper
                {i=79,p=3}, --tin
                {i=80,p=1}, --coal
                {i=65,p=2}, --limestone
                {i=47,p=1}, --ice
                {i=120,p=1}, --much water
                

                

                })
            end

            if g==7 then
                b = loot_make ({
                {i=103,p=50},
                {i=65,p=10}, --limestone
                {i=35,p=10}, --stone block
                {i=19,p=5}, --salt
                {i=63,p=10}, --copper
                {i=79,p=5}, --tin
                {i=136,p=5}, --pure clay

                })
            end

            if g > 7 then -- denser ground
                b = loot_make ({
                {i=103,p=200},
                {i=65,p=1}, --limestone
                {i=47,p=5} --ice cube
                --{i=35,p=5}, --stone block
                

                })
            end

            local done

            local replace = {1,32,31,103}

            local node = {
                [9] = 20,  --clay
                [63] = 40, --copper
                [79] = 30, --tin
                [80] = 60, --coal
                [35] = 10, --stone block
                [19] = 5, --salt
                [65] = 20, --limestone
                [136] = 20, --pure clay
                [47] = 20, --ice cube

                --[60] = 40, --sand

            }

            if in_array (replace,b) then

                local r1 = readmap (iy,ix-1,'b')
                local r2 = readmap (iy-1,ix,'b')
                local st = 0
                local ch = 0

                if node[r1] then 
                    st = r1 
                    ch = ch + node[r1]
                end

                if node[r2] then 
                    st = r2
                    ch = ch + node[r2]
                end
                
                if ch>0 and love.math.random (0,100)<ch then
                    b = st
                end 

            end
           
            --world[ix][iy].b = b
            writemap (iy,ix,b)
            --writemap (iy,ix,b)

        end


        -- on top (mobs)
        if world[ix][iy].b == 0 and g == -1 then

            local dist = math.dist (pl.startx,pl.starty,iy,ix)

            if dist>30 and love.math.random (0,100) < 15 then 
               writemap (iy,ix,53)
               writemap (iy,ix,9,'mob') --ameba
            end

            if dist>50 and love.math.random (0,100) < 3 then 
               writemap (iy,ix,53)
               writemap (iy,ix,11,'mob') --robot
            end

        end

        if world[ix][iy].b == 0 and g == -2 then

            local dist = math.dist (pl.startx,pl.starty,iy,ix)

            if dist>50 and love.math.random (0,100) < 3 then 
               writemap (iy,ix,53)
               writemap (iy,ix,14,'mob') --spinner
            end

        end



        -- easy dirt
        if ix > pl.startheight1 and ix < pl.startheight2 
        and world[ix][iy].b == 1 and g==1 and readmap (iy-1,ix,'b')==0 then
            world[ix][iy].b = 99
        end


    end
    end


end 


    chunk_map (pl.startx,pl.starty,chunk_load ('0'),10)
    breaks = {}
    

    function roomcheck (ix,iy,w,h,chunk)

         local dist = math.dist (pl.startx,pl.starty,ix,iy)

            -- if chunk.dist and dist<chunk.dist[1] then
            --     return
            -- end
            

            -- another room
            local f
            for i=ix,ix+h do
            for ii=iy,iy+w do
                if readmap (i,ii,'r')~=nil then
                    return
                end
            end
            end

            
            local f = false
            local cavecheck
            if chunk.cavemax then
                for i=ix,ix+h do
                for ii=iy,iy+w do
                    local g = readmap (i,ii,'cave')
                    if g and g > chunk.cavemax then
                       return
                    end
                end
                end
            end

         
            local f = false
            local botcheck
            if chunk.bot then
                for i=ix,ix+h do
                    local g = readmap (i,iy+w,'g')
                    if g ~= chunk.bot then
                        return
                    end
                end
            end

      
            
            local f = false
            local topcheck
            if chunk.top then
                for i=ix,ix+h do
                    local g = readmap (i,iy,'g')
                    if g ~= chunk.top then
                        return
                    end
                end
            end


           
            local f = false
            local rightcheck
            if chunk.right then
                for i=iy,iy+w do
                    local g = readmap (ix+h,i,'g')
                    if g ~= chunk.right then
                        return
                    end
                end
            end


            
            local f = false
            local leftcheck
            if chunk.left then
                for i=iy,iy+w do
                    local g = readmap (ix,i,'g')
                    if g ~= chunk.left then
                       return
                    end
                end
            end





            if chunk.no then 
                if chunk_check (ix,iy,w,h,chunk.no) ~= nil then
                    return
                end
            end

            return true

    end


    local roomsc = {}
    chunks_count = {}




    -- rooms
    love.thread.getChannel( 'geninfo' ):push(8)

    local filtered = 0

    spiral_ini (pl.startx,pl.starty)

    --2000000
    for ci=1,cf.wmax*cf.wmax*2 do

        local mx = 0

        local ix,iy,z = spiral_spin (1)

        if ix>mx then mx = ix end

        if ci%100 == 1 then
            chunkloot_set ()

            local pc = ci/(cf.wmax*cf.wmax*2)

            if pc>=1 then 
                pc=0.99 
            end

            love.thread.getChannel( 'geninfo' ):push(8+pc)

            if #chunkloot==0 then
                break
            end

        end


        for try = 1,10 do

            local i = loot_make(chunkloot)
            local chunk = chunks[i]


            local addsx = 0
            local addsy = 0

            roomsc[i] = roomsc[i] or {}
            chunks_count[i] = chunks_count[i] or 0
            
            if chunks_count[i]<chunk.cnt then
                
                local w = chunk.w
                local h = chunk.h
           
                if roomcheck (ix,iy,w,h,chunk) then
          
                    table.insert (roomsc[i],{ix,iy})
                    chunks_count[i] = chunks_count[i] + 1

                    local dist = math.floor (math.dist (pl.startx,pl.starty,ix,iy))
                    chunk_map (ix+chunk.xo,iy+chunk.yo,chunk.map,chunk.border,chunk)

                    if chunk.biome or chunk.biome_g then
                        make_biome (ix+chunk.xo+chunk.biome_x,iy+chunk.yo+chunk.biome_y,chunk.biome_r,chunk.biome,chunk.biome_g)
                    end

                    break

                end
            end
        end
    end


    for k,v in pairs(roomsc) do
       print(chunks[k].name.."="..#v)
    end
    
    local a =
    {
        [1] = 48, --frozen dirt
        [8] = 47, --stone to ice
        [9] = 47, -- clay to ice
        [102] = 47
    }

    --make_biome (pl.startx+60,pl.starty+5,10,a)


    love.thread.getChannel( 'geninfo' ):push(9)


        -- border
    for ix=1,cf.wmax do
            
        world[1][ix].b = 3
        world[cf.wmax][ix].b = 3
        world[ix][1].b = 3
        world[ix][cf.wmax].b = 3

    end

    love.thread.getChannel( 'geninfo' ):push(10)


    local mn = 0

    --corners
    for ix=1,cf.wmax do
    for iy=1,cf.wmax do

        local n,nn = neibors(ix,iy)
        writemap (ix,iy,n,'n')
        writemap (ix,iy,nn,'nn')
        local b = readmap (ix,iy,'b')

        --fall fix
        if maptile (ix,iy,'fall')~=nil and maptile (ix,iy,'fall')~=0 and readmap (ix,iy+1,'b')==0 then
            writemap (ix,iy,99)
        end


        if b==1 or b==99 then

            -- if n==255 then
            --     if love.math.random (0,100)<5 then
            --         writemap (ix,iy,177) --stonelouse
            --     end
            -- end


            --

            if n==244 and love.math.random (0,100)<40  then
                writemap (ix,iy,175) --minerals 175
                mn = mn + 1
            end

            if n==233 and love.math.random (0,100)<40 then
                writemap (ix,iy,176) --minerals
            end

            if n==22 or n==47 then --22
                writemap (ix,iy,47) --ice
            end

            if n==144 or n==40 then
                writemap (ix,iy,47) --ice
            end

            if n==144 or n==43 or n==47 then
                writemap (ix,iy,99)
            end

            if n==148 or n==23 or n==150 then
                writemap (ix,iy,99)
            end

        end


    end
    end

    print (mn)

    love.thread.getChannel( 'gendata' ):push(pl.starty)
    love.thread.getChannel( 'gendata' ):push(pl.startx)
    love.thread.getChannel( 'gendata' ):push(world)
    love.thread.getChannel( 'geninfo' ):push(11)
    




end


chunks_count = {}

chunks = {}

local chunk
local hl = 25


chunk = { 
    name = 'dungeon',
    map = chunk_load ('1'),
    dist = {3,30},
    cnt = 20,
    border = 0,
    no = 0, -- 0 - under ground, excluding blocks #, 0 - excluding empty
    --top = -2, -- -1 on ground, -2 ceiling, 1-6 depth
    bot = -2,   --
    yo = 0, --offset
    xo = 0, --offset,
}

table.insert (chunks, chunk)

chunk = { 
    name = 'ice shard',
    map = chunk_load ('2'),
    dist = {1,5},
    cnt = 25,
    border = 0,
    no = 1,
    --top = -2,
    bot = -1,
    yo = 2,
    xo = 0,
    biome = 
    {
        [1] = 48, --frozen dirt
        [8] = 47, --stone to ice
        [9] = 47, -- clay to ice
        [102] = 47 -- loam to ice
    },
    biome_r = 6,
    biome_x = 2, --biome offset
    biome_y = 0
}
table.insert (chunks, chunk)


chunk = { 
    pc = 1000,
    name = 'force ice shard',
    map = chunk_load ('2'),
    dist = {0,0.5},
    border = 0,
    cnt = 10,
    no = 1,
    --top = -2,
    bot = -1,
    yo = 2,
    xo = 0,
    biome = 
    {
        [1] = 48, --frozen dirt
        [8] = 47, --stone to ice
        [9] = 47, -- clay to ice
        [102] = 48 --
    },
    biome_r = 4,
    biome_x = 2, --biome offset
    biome_y = 0
}
table.insert (chunks, chunk)


chunk = { 
    pc = 50,
    name = 'table cave',
    map = chunk_load ('3'),
    dist = {0,5},
    border = 1,
    cnt = 10,
    no = 0,
    top = 2,
    --bot = 1,
    yo = -1,
    xo = 0,
    mob = 2,
}
table.insert (chunks, chunk)




chunk = { 
    pc = 2,
    name = 'marsh',
    map = chunk_load ('4'),
    dist = {5,10},
    border = 10,
    cnt = 10,
    no = 1,
    --top = 1,
    bot = -1,
    --left = 1,
    yo = 4,
    xo = 0,
    replace = {
    [107] = {
        {i = 107,p = 1},
        {i = 111,p = 1},
    },
    [1] = {
        {i = 107,p = 1},
        {i = 111,p = 1},
    },
    },

    biome_x = 2, --biome offset
    biome_y = 0,
    biome_r = 15,

    biome = 
    {
        [1] = 107,
        [8] = {
        {i = 8, p = 1},
        {i = 18,p = 1},
        },
        [9] = 19,
    },
    biome_g =
    {
        [-1] = 

        {
        {i=0,p=2},
        {i=108,p=3},
        {i=101,p=1},
        {i=114,p=2},

        }
    },
    mob = 5

}
table.insert (chunks, chunk)



chunk = { 
    name = 'marsh shroom',
    map = chunk_load ('5'),
    dist = {7,12},
    border = 10,
    cnt = 10,
    no = 1,
    --top = 1,
    bot = -1,
    --left = 1,
    yo = 1,
    xo = 0,
    replace = {
    [107] = {
        {i = 107,p = 1},
        {i = 111,p = 1},
    },
    [1] = {
        {i = 107,p = 1},
        {i = 111,p = 1},
    },
    },

    biome_x = 2, --biome offset
    biome_y = 0,
    biome_r = 15,

    biome = 
    {
        [1] = 107,
        [8] = {
        {i = 8, p = 1},
        {i = 18,p = 1},
        },
        [9] = 19,
    },
    biome_g =
    {
        [-1] = 

        {
        {i=0,p=2},
        {i=108,p=3},
        {i=101,p=1},
        {i=114,p=2},

        }
    },
    mob = 5
}
table.insert (chunks, chunk)


chunk = { 
    name = 'water lake',
    map = chunk_load ('6'),
    dist = {5,10},
    border = 10,
    cnt = 50,
    no = 1,
    --top = 1,
    bot = -1,
    --right = 1,
    yo = 1,
    xo = 0,
    cavemax = 90,
}
table.insert (chunks, chunk)


chunk = { 
    pc = 1.5,
    name = 'firewood forest',
    map = chunk_load ('7'),
    dist = {5,20},
    border = 3,
    cnt = 30,
    no = 1,
    --top = 1,
    bot = -1,
    --right = 1,
    yo = 2,
    xo = 0,
    --cavemax = 100,

    biome = 
    {
        [1] = 102, --dirt to earth
        [8] = 80, --stone to coal
        [9] = 103, -- clay to rock
    },
    biome_g =
    {
        [-1] = 

        {
            {i=0,p=10},
            {i=37,p=10}, --clover
            {i=95,p=10}, --spiny
        }
    },

    biome_r = 8,
    biome_x = 2,
    biome_y = 1,
    mob = 2,

}
table.insert (chunks, chunk)


chunk = { 
    name = 'water pool',
    map = chunk_load ('8'),
    dist = {3,12},
    border = 0,
    cnt = 5,
    no = 0,
    top = 4,
    --bot = -1,
    --right = 1,
    yo = -1,
    xo = 0,

}
table.insert (chunks, chunk)


chunk = { 
    pc = 2,
    name = 'spider cave',
    map = chunk_load ('9'),
    dist = {2,15},
    border = 3,
    cnt = 20,
    no = 0,
    --top = 4,
    --bot = -1,
    --right = 1,
    yo = 0,
    xo = 0,
    mob = 2,
    ignore = 3
}
table.insert (chunks, chunk)


chunk = { 
    pc = 2,
    name = 'tech',
    map = chunk_load ('10'),
    dist = {7,12},
    border = 0,
    cnt = 10,
    no = 1,
    --top = 1,
    bot = -1,
    --left = 1,
    yo = 2,
    xo = 0,
    biome_x = 0, --biome offset
    biome_y = 0,
    biome_r = 10,

    biome = 
    {
        [1] =   
        {
        {i=1,p=1},
        {i=52,p=3},
        },
        [8] = 
        {
        {i=60,p=1},
        {i=4,p=3},
        },
        [9] = 52,
    },
    biome_g =
    {
        [-1] = 

        {
        {i=0,p=1},
        {i=117,p=1},
        }
    },
    mob = 3

}
table.insert (chunks, chunk)





chunk = { 

    pc = 5,
    name = 'digging site',
    map = chunk_load ('11'),
    dist = {2,5},
    border = 1,
    cnt = 10,
    no = 0,
    top = 2,
    --bot = 1,
    yo = -1,
    xo = 0,
    mob = 11,
}
table.insert (chunks, chunk)


chunk = { 
    pc = 1.5,
    name = 'desert',
    map = chunk_load ('12'),
    dist = {3,10},
    border = 10,
    cnt = 20,
    no = 1,
    --top = 1,
    bot = -1,
    --right = 1,
    yo = 5,
    xo = 0,
    --cavemax = 100,

    biome = 
    {
        [1] = 60, --dirt to earth
        [8] = 9, --stone to coal
    },
    biome_g =
    {
        [-1] = 

        {
            {i=0,p=50},
            {i=128,p=10}, --clover
        }
    },

    biome_r = 4,
    biome_x = 2,
    biome_y = 3,
    mob = 8,

}
table.insert (chunks, chunk)




chunk = { 
    name = 'sand pit',
    map = chunk_load ('13'),
    dist = {4,12},
    border = 1,
    cnt = 15,
    no = 0,
    top = 2,
    --bot = 1,
    yo = -1,
    xo = 0,
    mob = 8,
}
table.insert (chunks, chunk)



chunk = { 
    name = 'clay pit',
    map = chunk_load ('14'),
    dist = {3,20},
    border = 1,
    cnt = 25,
    no = 0,
    top = 2,
    --bot = 1,
    yo = -1,
    xo = 0,
    mob = 8,
}
table.insert (chunks, chunk)


chunk = { 
    p = 0.5,
    name = 'salt lake',
    map = chunk_load ('15'),
    dist = {3,10},
    border = 1,
    cnt = 20,
    no = 0,
    top = 2,
    --bot = 1,
    yo = 0,
    xo = 0,
    mob = 8,
}
table.insert (chunks, chunk)


chunk = { 
    name = 'underground shrooms w mob',
    map = chunk_load ('16'),
    dist = {5,15},
    border = 1,
    cnt = 30,
    no = 0,
    top = 5,
    --bot = 1,
    yo = 0,
    xo = 0,
    mob = 5,
}
table.insert (chunks, chunk)


--chunks = {}

chunk = { 
    name = 'desert in a cave',
    p = 2,
    map = chunk_load ('17'),
    dist = {5,25},
    border = 10,
    cnt = 10,
    no = 1,
    --top = 1,
    bot = -1,
    --right = 1,
    yo = 2,
    xo = 0,
    cavemax = 100,

    biome_g =
    {
        [-1] = 

        {
            {i=0,p=50},
            {i=128,p=20},
            {i=134,p=10},
            {i=95,p=10},
        },

        [1] =
        {
            {i=60,p=5},
        },

        [2] =
        {
            {i=136,p=5},
        },

        [-2] =
        {
            {i=136,p=5},
        },
        
    },

    biome_r = 7,
    biome_x = 0,
    biome_y = 3,
    mob = 8,

}
table.insert (chunks, chunk)



chunk = { 
    name = 'swamp in a cave',
    map = chunk_load ('18'),
    dist = {5,25},
    border = 10,
    cnt = 30,
    no = 1,
    --top = 1,
    bot = -1,
    --right = 1,
    yo = 2,
    xo = 0,
    cavemax = 200,

    biome_g =
    {
        [-1] = 

        {
            {i=0,p=40},
            {i=114,p=20},
            {i=108,p=10},
            {i=101,p=5},
            {i=18,p=30},
            {i=134,p=5},
            

        },

        [1] =
        {
            {i=111,p=5},
        },

        [2] =
        {
            {i=111,p=5},
        },

        [-2] =
        {
            {i=65,p=5},
        },
        
    },

    biome_r = 5,
    biome_x = 0,
    biome_y = 0,
    mob = 5,

}
table.insert (chunks, chunk)



chunk = { 
    name = 'firewood tree',
    map = chunk_load ('19'),
    dist = {3,10},
    border = 3,
    cnt = 12,
    no = 1,
    --top = 1,
    bot = -1,
    --right = 1,
    yo = 2,
    xo = 0,
    --cavemax = 100,

    biome = 
    {
        [1] = 102, --dirt to earth
        [8] = 80, --stone to coal
        [9] = 103, -- clay to rock
    },
    biome_g =
    {
        [-1] = 

        {
            {i=0,p=10},
            {i=37,p=10}, --clover
            {i=95,p=10}, --spiny
        }
    },

    biome_r = 3,
    biome_x = 0,
    biome_y = 1,
    mob = 2,

}
table.insert (chunks, chunk)



chunk = { 
    pc = 3,
    name = 'frozen chest',
    map = chunk_load ('20'),
    dist = {3,15},
    cnt = 20,
    border = 0,
    no = 0, -- 0 - under ground, excluding blocks #, 0 - excluding empty
    --top = -2, -- -1 on ground, -2 ceiling, 1-6 depth
    bot = -2,   --
    yo = 0, --offset
    xo = 0, --offset,
    mob = 7,
}
table.insert (chunks, chunk)



for i,v in ipairs(chunks) do
    chunks[i].h = #chunks[i].map
    if chunks[i].h == 0 then
        chunks[i].w = 0
    else
        chunks[i].w = #chunks[i].map[1]
    end
end


function chunkloot_set ()
    chunkloot = {}
    local t = 0
    for k,v in pairs(chunks) do

        local pm = (chunks_count[k] or 0)/chunks[k].cnt
        local lpc = v.pc or 1
        lpc = lpc * 100000
        lpc = lpc - lpc*pm
        lpc = math.floor (lpc)

        if lpc>0 then
            table.insert (chunkloot, {i=k, p=lpc})
            t = t + lpc
        end

    end

    return t

end


local t = chunkloot_set ()


for k,v in pairs(chunkloot) do
    v.pc = (v.p/t)*100*#chunkloot
end

table.sort (chunkloot,function (k1,k2) return k1.p>k2.p end)

for k,v in pairs(chunkloot) do
    print (chunks[v.i].name.." = "..v.pc)
end




mapgen = {}

function mapgen.gen( ... )
    -- body
end



--------------------------------------------------------------------------------------------------



function mapgen.draw (size)

    for x = 1, #mapgen.grid do
        for y = 1, #mapgen.grid[x] do

            local f
            if mapgen.grid[x] and mapgen.grid[x][y] then
            
                f = 1 * mapgen.grid[x][y]

            else
                f = 0.5

            end

            love.graphics.setColor( f, f, f, 1 )
            love.graphics.rectangle( 'fill', x * (size + 1), y * (size + 1), size, size )
            love.graphics.setColor( 1, 1, 1, 1 )
        end
    end
end

function mapgen.swap (a,b)

    for x = 1, #a do
        for y = 1, #a do

            b[x][y] = a[x][y]

        end
    end
end


function mapgen.clear ()

    for x = 1, #mapgen.grid do
        for y = 1, #mapgen.grid[x] do

            local f
            if mapgen.grid[x] and mapgen.grid[x][y] then
                mapgen.grid[x][y] = 0
            end

        end
    end
end

function mapgen.near (x,y)

    local m = 0
    local n =
    mapgen.grid[x-1][y-1] + mapgen.grid[x-1][y] + mapgen.grid[x-1][y+1] +
    mapgen.grid[x][y-1] + mapgen.grid[x][y]*0 + mapgen.grid[x][y+1] +
    mapgen.grid[x+1][y-1] + mapgen.grid[x+1][y] + mapgen.grid[x+1][y+1]

    if mapgen.grid[x-1][y-1]>0 then m = m + 1 end
    if mapgen.grid[x-1][y]>0 then m = m + 1 end
    if mapgen.grid[x-1][y+1]>0 then m = m + 1 end

    if mapgen.grid[x][y-1]>0 then m = m + 1 end
    if mapgen.grid[x][y+1]>0 then m = m + 1 end
    
    if mapgen.grid[x+1][y-1]>0 then m = m + 1 end
    if mapgen.grid[x+1][y]>0 then m = m + 1 end
    if mapgen.grid[x+1][y+1]>0 then m = m + 1 end

    return m, n 
end

function mapgen.new ()
    
    mapgen.grid = {}
    mapgen.tgrid = {}

end


function mapgen.supersize (x1,y1,x2,y2)
     
    mapgen.swap (mapgen.grid,mapgen.tgrid)

    for x = x1, (x1+x2)/2 do
    for y = y1, (y1+y2)/2 do

    --print (mapgen.grid[x][y])

        mapgen.tgrid[x1 + (x - x1)*2][y1 + (y - y1)*2] = mapgen.grid[x][y]
        mapgen.tgrid[1+ x1 + (x - x1)*2][y1 + (y - y1)*2] = mapgen.grid[x][y]
        mapgen.tgrid[x1 + (x - x1)*2][1+ y1 + (y - y1)*2] = mapgen.grid[x][y]
        mapgen.tgrid[1+ x1 + (x - x1)*2][1+ y1 + (y - y1)*2] = mapgen.grid[x][y]

    end
    end

    mapgen.swap (mapgen.tgrid,mapgen.grid)

        --mapgen.clear ()
        --print (#mapgen.tgrid)
        --mapgen.grid = mapgen.tgrid

end


function mapgen.fill (x1,y1,x2,y2,a)
-- a.line
-- a.pc
-- a.seed
-- a.fill
-- a.add

-- 0.42 line = 7

    a = a or {}
    a.fill = a.fill or 1
    a.pc = a.pc or 0.525

    if (a.seed) then love.math.setRandomSeed (a.seed) end

    for x = x1, x1+x2 do
        
        mapgen.grid[x] = mapgen.grid[x] or {}
        mapgen.tgrid[x] = mapgen.tgrid[x] or {}
        
        for y = y1, y1+y2 do
    
            if a.add then
                    if love.math.random ()<a.pc then else mapgen.grid[x][y] = 1 end
                else
                    if love.math.random ()<a.pc and mapgen.grid[x][y] ~= 1 then mapgen.grid[x][y] = 0 else mapgen.grid[x][y] = 1 end
                end

            if a.line and y % a.line == 1 then mapgen.grid[x][y] = 1 end
            if a.line2 and x % a.line2 == 1 then mapgen.grid[x][y] = 1 end

            if a.line and a.line<0 and x % (a.line*-1) == 1 then mapgen.grid[x][y] = 0 end
            if a.line2 and a.line2<0 and x % (a.line2*-1) == 1 then mapgen.grid[x][y] = 0 end
            
            if x == x1 or x == x1+x2 or y == y1 or y == y1+y2 then mapgen.grid[x][y] = a.fill end
        
        end
    end

end


function mapgen.pass (x1,y1,x2,y2,a)

    a = a or {}
    a.r = a.r or 1
    a.rpass = a.rpass or 0
    a.pass = a.pass or 3
    if (a.seed) then love.math.setRandomSeed (a.seed) end
   
    local p = math.floor ((x2+x1)*(y2+y1)*a.r*a.rpass)
    
    -- random pass
    for i = 1, a.rpass do

        --mapgen.tgrid = mapgen.grid
        mapgen.swap (mapgen.grid,mapgen.tgrid)

        for i = 1, p do

            --mapgen.tgrid = mapgen.grid


            x = love.math.random (2,x2-2) + x1
            y = love.math.random (2,y2-2) + y1

            --print (x,y)

            local n,m = mapgen.near(x,y)


            if mapgen.grid[x][y]>0 and n >= 4 then mapgen.tgrid[x][y]=1 else
            if mapgen.grid[x][y] == 0 and n >= 5 then mapgen.tgrid[x][y]=1 else
                mapgen.tgrid[x][y]=0
            end
            end

            -- if mapgen.grid[x][y]>0 and n >= 8 and m > 4 then mapgen.tgrid[x][y]=0.5 end
            -- if mapgen.grid[x][y]>0 and n >= 8 and m <= 4 then mapgen.tgrid[x][y]=0.2 end


        end

        --mapgen.grid = mapgen.tgrid
        mapgen.swap (mapgen.tgrid,mapgen.grid)
    end


    

    a.grow = a.grow or 0
    if a.grow > 0 then
    
        for i = 1, a.grow do

        --mapgen.tgrid = mapgen.grid
        mapgen.swap (mapgen.grid,mapgen.tgrid)

            for x = x1+1, x1+x2-1 do
            for y = y1+1, y1+y2-1 do
        
                local n, m = mapgen.near(x,y)

                if mapgen.grid[x][y]==0 and n >= 4 then mapgen.tgrid[x][y]=1 end
                

            
            end
            end

        --mapgen.grid = mapgen.tgrid
        mapgen.swap (mapgen.tgrid,mapgen.grid)

        end
    end


    for i = 1, a.pass do

    --mapgen.tgrid = mapgen.grid
    mapgen.swap (mapgen.grid,mapgen.tgrid)

        for x = x1+1, x1+x2-1 do
        for y = y1+1, y1+y2-1 do
    
            local n, m = mapgen.near(x,y)

            if mapgen.grid[x][y]>0 and n >= 4 then mapgen.tgrid[x][y]=1 else
            if mapgen.grid[x][y] == 0 and n >= 5 then mapgen.tgrid[x][y]=1 else
                mapgen.tgrid[x][y]=0
            end
            end

            -- if mapgen.grid[x][y]==0 and n >= 4 then mapgen.tgrid[x][y]=1 end
            -- if mapgen.grid[x][y]>0 and n >= 8 and m <= 4 then mapgen.tgrid[x][y]=0.3 end
            -- if mapgen.grid[x][y]>0 and n >= 8 and m <= 3 then mapgen.tgrid[x][y]=0.2 end



        
        end
        end

    --mapgen.grid = mapgen.tgrid
    mapgen.swap (mapgen.tgrid,mapgen.grid)

    end




    local bl = {}
    
    a.dpass = a.dpass or 0
    local max = 0


    if a.dpass>0 then

            for i = 1, a.dpass do

                mapgen.swap (mapgen.grid,mapgen.tgrid)

                    for x = x1+1, x1+x2-1 do
                    for y = y1+1, y1+y2-1 do
                
                        local n, m = mapgen.near(x,y)
                        local min = math.floor (m/8)+i
                        if min>max then max = min end
                        if mapgen.grid[x][y]>0 and n >= 8 and min>= max then mapgen.tgrid[x][y]=min end

                    end
                    end

                mapgen.swap (mapgen.tgrid,mapgen.grid)

            end

            for x = x1+1, x1+x2-1 do
            for y = y1+1, y1+y2-1 do

                local m = mapgen.grid[x][y]
                if m>=1 then
                    m = math.floor (m^0.5*1.55 - 0.1)
                    mapgen.grid[x][y] = m
                else

                local na, ma = mapgen.near(x,y)
                if mapgen.grid[x][y]==0 and na >= 2 then
                    if mapgen.grid[x][y+1]~=0 then mapgen.grid[x][y]=-1 end
                    if mapgen.grid[x][y-1]~=0 then mapgen.grid[x][y]=-2 end
                end

                      

            end
            end

        end

    end




    

    --table.sort(bl)
    --print (dumpvar (bl))
 
    

end

local scene = storyboard.newScene()
local app = require('lib.app')
local api = app.api
local vec3 = require('lib.vec3')

local s = 250
local function position3d(v)
    return s * v.x / v.z + _CX, s * v.y / v.z + _CY
end

local function dot(group, pos, color)
    local c = display.newCircle(group, 0, 0, 3)
    if color then
        c:setFillColor(unpack(color))
    else
        c:setFillColor(1, 0, 0)
    end
    c.pos = pos
    c.rot = {0, 0, 0}
    c.isDot = true
    return c
end

local function newPlane(group)
    local plane = display.newSprite(group, graphics.newImageSheet('images/plane.png', {width = 100, height = 100, numFrames = 9, sheetContentWidth = 300, sheetContentHeight = 300}),{
            name = 'normal',
            start = 1,
            count = 9
        })
    plane.horizont, plane.vertical = 0, 0
    function plane:setOrientation()
        self:setFrame(5 + self.horizont + 3 * self.vertical)
    end
    plane:setFrame(5)
    return plane
end

local function newSlicedImage(filename, params)
    local n = params.numSlices or 2
    local rp = params.rp
    local sw = math.floor(params.w / n)
    local sh = math.floor(params.h / n)
    local sheet = graphics.newImageSheet(filename, {width = sw, height = sh, numFrames = n * n, sheetContentWidth = params.w, sheetContentHeight = params.h})
    
    local slicedImage = {numSlices = n, map = {}, pos = vec3(0, 0, 0)}  
    
    local slices = {}
    local ind, s
    for y = 1, n do
        for x = 1, n do
            ind = x + (y - 1) * n
            s = display.newImage(params.g, sheet, ind)
            if rp then
                app.setRP(s, rp)
            end
            s.mX, s.mY = x - 1, y - 1
            s.pivot = slicedImage
            slices[ind] = s
        end
    end
    
    function slicedImage:toFront()
        for i = 1, #slices do
            slices[i]:toFront()
        end
    end
    function slicedImage.__newindex(t, key, value)
        if key == 'isVisible' then
            for i = 1, #slices do
                slices[i].isVisible = value
            end
        elseif key == 'faceSize' then
            for i = 1, #slices do
                slices[i].faceSize = value / n
            end
        end
    end
    setmetatable(slicedImage, slicedImage)
    return slicedImage
end

local function newCube(group)
    local cube = {}
    local back, front, left, right, up, down
    local n = 4
    local s = 1024
    local box = 'images/box2/'
    back = newSlicedImage(box .. 'back-z.png', {g = group, w = s, h = s, numSlices = n, rp = 'TopLeft'})
    left = newSlicedImage(box .. 'left-x.png', {g = group, w = s, h = s, numSlices = n, rp = 'TopLeft'})
    right = newSlicedImage(box .. 'right+x.png', {g = group, w = s, h = s, numSlices = n, rp = 'TopLeft'})
    up = newSlicedImage(box .. 'up-y.png', {g = group, w = s, h = s, numSlices = n, rp = 'TopLeft'})
    down = newSlicedImage(box .. 'down+y.png', {g = group, w = s, h = s, numSlices = n, rp = 'TopLeft'})
    front = newSlicedImage(box .. 'front+z.png', {g = group, w = s, h = s, numSlices = n, rp = 'TopLeft'})
    
    local faces = {back, front, left, right, up, down}
    
    cube.back, cube.front, cube.left, cube.right, cube.up, cube.down = back, front, left, right, up, down
    front.isVisible = false
    
    back.faceSize = s
    front.faceSize = s
    left.faceSize = s
    right.faceSize = s
    down.faceSize = s
    up.faceSize = s
    
    local dots = {}
    
    local d = 1/n
    for x = 0, n do
        for y = 0, n do
            back.map[x + y * (n + 1)] = vec3((x * d - 0.5) * 2, (y * d - 0.5) * 2, 1)
            dots[#dots + 1] = dot(group, back.map[x + y * (n + 1)], {0, 1, 0})
        end
    end
    for x = 0, n do
        for y = 0, n do
            front.map[x + y * (n + 1)] = vec3(((n - x) * d - 0.5) * 2, (y * d - 0.5) * 2, -1)
        end
    end
    for z = 0, n do
        for y = 0, n do
            left.map[z + y * (n + 1)] = vec3(-1, (y * d - 0.5) * 2, (z * d - 0.5) * 2)
        end
    end
    for z = 0, n do
        for y = 0, n do
            right.map[z + y * (n + 1)] = vec3(1, (y * d - 0.5) * 2, ((n - z) * d - 0.5) * 2)
        end
    end
    for x = 0, n do
        for z = 0, n do
            down.map[x + z * (n + 1)] = vec3((x * d - 0.5) * 2, 1, ((n - z) * d - 0.5) * 2)
        end
    end
    for x = 0, n do
        for z = 0, n do
            up.map[x + z * (n + 1)] = vec3((x * d - 0.5) * 2, -1, (z * d - 0.5) * 2)
        end
    end
    
    dots[#dots + 1] = dot(group, vec3(-1, -1, -1))
    dots[#dots + 1] = dot(group, vec3(1, -1, -1))
    dots[#dots + 1] = dot(group, vec3(-1, -1, 1))
    dots[#dots + 1] = dot(group, vec3(1, -1, 1))
    dots[#dots + 1] = dot(group, vec3(-1, 1, -1))
    dots[#dots + 1] = dot(group, vec3(1, 1, -1))
    dots[#dots + 1] = dot(group, vec3(-1, 1, 1))
    dots[#dots + 1] = dot(group, vec3(1, 1, 1))
    
    function cube:rotate(axis, angle)
        local f, map
        for i = 1, #faces do
            f = faces[i]
            map = f.map
            for j = 0, #f.map do
                f.map[j] = f.map[j]:rot_around(axis, angle)
            end
            f.pos = f.pos:rot_around(axis, angle)
        end
        self:zOrder()
        
        local d
        for i = 1, #dots do
            d = dots[i]
            d.pos = d.pos:rot_around(axis, angle)
            d:toFront()
        end
    end
    
    local tSort = table.sort
    function cube:zOrder()
        tSort(faces, function(a, b) return a.pos.z < b.pos.z end)
        for i = #faces, 1, -1 do
            faces[i]:toFront()
        end
    end
    
    return cube
end

function scene:render()
    local group = self.view
    local obj
    for i = 1, group.numChildren do
        obj = group[i]
        if obj.isDot then
            if obj.pos.z < 0 or not self.showDots then
                obj.isVisible = false
            else
                obj.isVisible = true
                obj.x, obj.y = position3d(obj.pos)
            end
        elseif obj.mX then
            local map = obj.pivot.map
            local mX, mY = obj.mX, obj.mY
            local n = obj.pivot.numSlices + 1

            local topLeft = map[mX + mY * n]
            local bottomLeft = map[mX + (mY + 1) * n]
            local bottomRight = map[mX + 1 + (mY + 1) * n]
            local topRight = map[mX + 1 + mY * n]

            if topLeft.z < 0 or bottomLeft.z < 0 or bottomRight.z < 0 or topRight.z < 0 then
                obj.isVisible = false
            else
                local path = obj.path
                local s = obj.faceSize
                obj.isVisible = true
                local x, y
                x, y = position3d(topLeft)
                path.x1, path.y1 = x, y
                x, y = position3d(bottomLeft)
                path.x2, path.y2 = x, y - s
                x, y = position3d(bottomRight)
                path.x3, path.y3 = x - s, y - s
                x, y = position3d(topRight)
                path.x4, path.y4 = x - s, y
            end
        elseif obj.isBullet then
            if obj.pos.z < 0 then
                obj.isVisible = false
            else
                obj.isVisible = true
                obj.x, obj.y = position3d(obj.pos)
                obj.xScale = 1 / obj.pos.z
                obj.yScale = obj.xScale
            end
        end
    end
    for i = 1, #self.bullets do
        self.bullets[i]:toFront()
    end
    self.plane:toFront()
end

local gun_sound = audio.loadSound('sounds/gun.wav')
function scene:fire()
    local group = self.view
    local bullet = app.newImage('images/bullet.png', {g = group, w = 32, h = 32})
    bullet.pos = vec3(0, 0.05, 0.3)
    bullet.x, bullet.y = position3d(bullet.pos) 
    bullet.isBullet = true
    bullet.blendMode = 'add'
    bullet:rotate(math.random(0, 360))
    table.insert(self.bullets, bullet)
    audio.play(gun_sound)
    timer.performWithDelay(1, function()
             bullet.pos = bullet.pos + bullet.pos:unit() * 0.04 + vec3(0, -0.002, 0)
        end, 300)
    timer.performWithDelay(5000, function()
            table.remove(self.bullets, table.indexOf(self.bullets, bullet))
            bullet:removeSelf()
        end)
    -- Having so many timers is not advices, better to have single enterFrame function which does all the stuff
end

function scene:rotate(axis, angle)
    self.cube:rotate(axis, angle)
    for i = 1, #self.bullets do
        self.bullets[i].pos = self.bullets[i].pos:rot_around(axis, angle)
    end
end

function scene:createScene (event)
    local group = self.view
    local stage = display.getCurrentStage()
    local r = display.newRect(group, _L, _T, _R - _L, _B - _T)
    r.x, r.y = _CX, _CY
    self.cube = newCube(group)
    
    self.plane = newPlane(group)
    self.plane.x, self.plane.y = _CX, _H - 100
    
    self.bullets = {}
    
    local function navigationControl()
        if self.kW then
            self:rotate(vec3(1, 0, 0), -0.01)
        end
        if self.kA then
            self:rotate(vec3(0, 1, 0), 0.01)
        end
        if self.kS then
            self:rotate(vec3(1, 0, 0), 0.01)
        end
        if self.kD then
            self:rotate(vec3(0, 1, 0), -0.01)
        end
        self:render()
    end
    self.t = timer.performWithDelay(1, navigationControl, 0)
    
    local function keyListener(event)
        local key = event.keyName
        local down = event.phase == 'down'
        if key == 'w' then
            self.kW = down
            if down then
                self.plane.vertical = 1
            else
                self.plane.vertical = 0
            end
        elseif key == 'a' then
            self.kA = down
            if down then
                self.plane.horizont = -1
            else
                self.plane.horizont = 0
            end
        elseif key == 's' then
            self.kS = down
            if down then
                self.plane.vertical = -1
            else
                self.plane.vertical = 0
            end
        elseif key == 'd' then
            self.kD = down
            if down then
                self.plane.horizont = 1
            else
                self.plane.horizont = 0
            end
        elseif key == ' ' or key == 'space' then
            if down then
                if not self.fireTimer then
                    self.fireTimer = timer.performWithDelay(100, function() self:fire() end, 0)
                end
            else
                timer.cancel(self.fireTimer)
                self.fireTimer = nil
            end
        elseif key == 't' and down then
            self.showDots = not self.showDots
        end
        self.plane:setOrientation()
    end
    Runtime:addEventListener('key', keyListener) -- remove listener on scene exit
end

function scene:didExitScene()
    timer.cancel(self.t)
    storyboard.removeScene('scenes.demo')
end

scene:addEventListener('didExitScene', scene)
scene:addEventListener('createScene', scene)
return scene


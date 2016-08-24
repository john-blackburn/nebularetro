--[[------------------------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Layout API ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Layout.new{...} -- new layout with optional settings and/or children
Layout:update{...} -- update layout with settings and/or children
Layout(id) -- access child layout by it's unique id or it's draw order
Layout(col, row) -- access cell by it's row and column numbers
Layout.select(sprite) -- set focus and selector to that sprite
Layout.newAnimation(frames, mark, strength, seed)
	-- returns random animation, all parameters are optional
	-- 'seed' is used for randomizer to get same animation each time
Layout:play(anim, [newstate], [callback])
	-- plays animation, see description at Animation section
	-- newstate is a table with numeric parameters of layout
	-- callback is a function which will be called at the end of animation
Layout:with{...}
	-- extend Layout class (or subclass) with additional parameters
	-- 'init' and 'upd' functions will be inherited from all parents
	-- resulting class can be instantiated (new) or extended (with)

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Resource Loader ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Layout has optional resource loader	to automatically load various resources.
From the box it supports .jpg, .png, .wav, .mp3, .ttf, .otf, .lua, .json.
Resource Loader returs a table with resources, their names and indexes where
resources can be accessed with t[integer_number] or t[resource_name] and
resource name can be received with negative index i.e. t[-integer_number].
It has following interface:
Layout.newResources{...} where {...} is a table with following parameters:
	path    = string  -- path to directory with resources
	subdirs = boolean -- load resources from subdirectories
	names   = string  -- table of names to filter directory files
	from    = number  -- index of first resource file to load
	to      = number  -- index of last resource file to load
	output  = boolean -- print list of resource files
	namemod = function(name, path, base, ext, i) -- to filter file names
	onlynames = boolean -- instead of resources return filenames
	
	textureFiltering = boolean
	textureOptions   = table
	fontSize         = number
	fontText         = text
	fontFiltering    = boolean

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Animation ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
to describe animation a table with the following keys must be used:
-- 'frames' key --
defines animation length
if 'frames' is not exist or is 0 or less then you will get error message

-- 'mark' key --
defines the type of animation
it accepts following values: [-1|0|0..1|1..]
if 'mark' is -1 then it's ending animation (from initial state to new)
if 'mark' is 0 then it's opening animation (from new state to initial)
if 'mark' is greater than 0 then animation will be played as
initial -> new -> initial and 'mark' defines 'initial -> new' length
if 'mark' is in [0..1] range then it will relative to 'frames'
if 'mark' is in [1..frames] then it will be used as is
if 'mark' is in [frames..] then their values will be swapped

-- 'strength' key --
defines multiplier for t (time) parameter to change animation range
equal to 1 if not defined

-- other animation keys --
key names are same as Sprite.set accepts:
	x, y, anchorX, anchorY,
	rotationX, rotationY, scaleX, scaleY,
	rotation, alpha,
	redMultiplier, greenMultiplier, blueMultiplier, alphaMultiplier
key values can be [nil|number|function]
all keys are relative to initial state of layout i.e. 0 means no change

-- numeric keys --
each number will be multiplied by t (time) and added to origin,
where t is time (frame / frames) in range [0..1]

-- function-keys --
function must accept one parameter t (time), where t = [0..1]
function must return a number (delta) based on that parameter t
result of function will be multiplied by t and added to original value

-- x, y, anchorX, anchorY --
this parameters are relative to width and height of the layout

-- rotation --
rotation will be multiplied by 360 (1.0 = 360, -0.5 = -180, etc)
--]]------------------------------------------------------------------------

Layout = Core.class(Mesh)

-- scale modes for Layout.texM and Layout.sprM
Layout.FIT_ALL    = 0
Layout.STRETCH    = 1
Layout.FIT_WIDTH  = 2
Layout.FIT_HEIGHT = 3
Layout.CROP       = 4

-- default parameters for each new layout (can be modified)
local default = {
	-- anchored (to width and height of parent) positioning
	ancX = 0.5, 
	ancY = 0.5,
	
	-- relative (to width and height of parent) positioning
	relX = false,
	relY = false,
	
	-- absolute positioning (disables relative and anchored one)
	absX = false, -- absolute X
	absY = false, -- absolute Y
	
	-- absolute size (disables relative and anchored one)
	absW = false,
	absH = false,
	
	-- relative (to width and height of parent) size
	relW = 1.0,
	relH = 1.0,
	
	-- 	width/height restriction 
	limW = false, -- maximal width/height aspect ratio, [0..]
	limH = false, -- maximal height/width aspect ratio, [0..]
	
	-- relative content size
	conRelW = 1, -- content width relative to parent, [false|number]
	conRelH = 1, -- content height relative to parent, [false|number]
	
	-- absolute content size (disables relative width and/or height)
	conAbsW = false, -- content absolute width (in pixels), [false|number]
	conAbsH = false, -- content absolute height (in pixels), [false|number]
	
	-- background
	bgrC = 0x000000, -- background color
	bgrA =      0.0, -- background alpha
	
	-- selector color settings
	selLineC = 0x000000, -- selector line color
	selLineA = 1.0,      -- selector line alpha
	selFillC = 0x000000, -- selector fill color
	selFillA = 0.1,      -- selector fill alpha
	
	-- texture
	texture = false, -- texture object (from Texture.new)
	texM = Layout.FIT_ALL, -- texture scale mode
	texC = 0xFFFFFF, -- texture color
	texA = 1.0,      -- texture alpha
	texS = 1.0,      -- texture scale
	texAncX = 0.5,   -- texture anchored X, [0..1]
	texAncY = 0.5,   -- texture anchored Y, [0..1]
	texOffX = 0,     -- texture X offset (in pixels)
	texOffY = 0,     -- texture Y offset (in pixels)
	
	-- non-layout sprites
	sprM = Layout.FIT_ALL, -- sprite scale mode, [false|number]
	sprS = 1.0, -- sprite scale
	sprX = 0.5, -- sprite X
	sprY = 0.5, -- sprite Y
	
	-- relative center (affects rotation and scaling)
	centerX = 0.5, -- [0..1]
	centerY = 0.5, -- [0..1]
	
	-- template grid
	template = false, -- Layout or Layout-based class
	database = false, -- list of cells' parameters
	colsFill = false, -- columns will be filled first if true
	
	-- borders for cells
	borderW = 0, -- cell border width in pixels
	borderH = 0, -- cell border height in pixels
	
	cols = 0, -- grid columns (integer) number, [0..]
	rows = 0, -- grid rows (integer) number, [0..]
	
	cellRelW = 1, -- cell relative width
	cellRelH = 1, -- cell relative width
	
	cellAbsW = false, -- cell absolute width
	cellAbsH = false, -- cell absolute height
	
	-- cell
	col  = false, -- cell column number (integer|false)
	row  = false, -- cell row number (integer|false)
	colW =   1.0, -- cell width relative to default cell width
	rowH =   1.0, -- cell height relative to default cell height
	
	-- identification
	id  = nil, -- to get child by id with 'layout(id)' call
	
	-- inheritance
	init = false, -- callback at instantiation (useful for custom classes)
		-- [false|function(self, parameters)]
	ext  = false, -- callback at children adding (to modify them)
		-- [false|function(self, child)]
	upd  = false, -- callback at updating (useful for custom classes)
		-- [false|function(self, parameters)]
	
	-- keyboard control, can have multiple keys for the same action
	keys = { -- [realCode] = action
		[16777234] =   "LEFT", -- jump to leftward cell
		[16777235] =     "UP", -- jump to upward cell
		[16777236] =  "RIGHT", -- jump to rightward cell
		[16777237] =   "DOWN", -- jump to downward cell
		[16777220] = "SELECT", -- enter the layout or press it
		[16777219] =   "BACK", -- return to parent layout or stage
		
		-- mouse wheel for "UP" and "DOWN" actions
		mouseWheel = true,
	},
	
	-- gamepad control, can have multiple buttons for the same action
	buttons = { -- [keyCode] = action
		[21]  =     "UP",
		[22]  =   "DOWN",
		[105] =  "RIGHT",
		--[???] = "LEFT", -- controller plugin is broken for desktop
		[96]  = "SELECT",
		[97]  =   "BACK",
		
		-- left stick for "UP", "DOWN", "RIGHT", "LEFT" actions
		stickDeadzone = 0.5, -- [0..1], stick disabled at 1
	},
	
	-- moving/scrolling
	moveReactionX =   1, -- reaction coefficient for X while layout dragged
	moveReactionY =   1, -- reaction coefficient for Y while layout dragged
	moveDeadzone  =   5, -- moving/scrolling starts outside this zone, [0..]
	moveFriction  = 0.5, -- friction coefficient while layout dragged
	moveDamping   = 0.9, -- damping coefficient while layout released
	moveDelta     =   1, -- area side to detect moving/scrolling, [0..]
	
	-- scrolling
	scrollFrames = 20, -- animation frames for keyboard or joystick scroll
	
	-- scaling
	scaleMouseResp = 0.005, -- scale response for mouse
	scaleTouchResp = 0.005, -- scale response for touch
	scaleMin       =   0.2, -- scale minimal value
	scaleMax       =   2.0, -- scale maximal value
	
	-- tilting
	tiltMouseResp = 1, -- tilt response for mouse
	tiltTouchResp = 1, -- tilt response for touch

	events = true, -- enable mouse/touch events, [false|true]
	
	-- event callbacks
	onAdd    = false, -- callback at added to stage event, [false|function]
	onRemove = false, -- callback at removed from stage event, [false|function]
	onHover  = false, -- callback at mouse hovering, [false|function]
	onPress  = false, -- callback at LMB or touch press, [false|function]
	onHold   = false, -- callback at LMB or touch while hold, [false|function]
	onMove   = false, -- callback at layout moving, [false|function]
	onScroll = false, -- callback at layout scrolling, [false|function]
	onBack   = false, -- callback at "BACK" action, [false|function]
	
	-- built-in callbacks
	scroll = false, -- move children with mouse or touch, [false|true]
	move   = false, -- move layout with mouse or touch, [false|true]
	scale  = false, -- scale layout with RMB or double touch, [false|true]
	tilt   = false, -- tilt layout with RMB or double touch, [false|true]
	
	-- animation
	anAdd    = false, -- opening animation (mark=0)
	anRemove = false, -- ending animation (mark=-1)
	anPress  = false, -- press animation (mark>0)
	anHover  = false, -- hover animation (mark>0) 
}

for k,v in pairs(default) do Layout[k] = v end

local internal = {
	isLayout = true,
	getClass = function() return "Layout" end,
	
	-- events
	IDLE        = 0,
	HOVER       = 1,
	PRESS_HOLD  = 2,
	MOVE_SCROLL = 3,
	SCALE_TILT  = 4,
	ADD         = 5,
	REMOVE      = 6,
	PLAY        = 7,
	
	event = 0, -- IDLE
	onPlay = false,
	
	isMouseMove = false,
	
	parent = false,
	
	x = 0,
	y = 0,
	w = 0,
	h = 0,
	
	parW = 0,
	parH = 0,
	
	parCellW = 0,
	parCellH = 0,
	
	parBorderW = 0,
	parBorderH = 0,
	
	selectedCol = 0,
	selectedRow = 0,
	
	offX = 0,
	offY = 0,
	
	scrW = 0,
	scrH = 0,
	
	conW = 0,
	conH = 0,
	
	frame  = 0,
	mark   = 0,
	frames = 0,
	
	newstate = false,
	oldstate = false,

	pointerX  = 0, -- current X of pointer
	pointerY  = 0, -- current Y of pointer
	pointerDX = 0, -- delta X value
	pointerDY = 0, -- delta Y value
	pointerAX = 0, -- accumulated X value
	pointerAY = 0, -- accumulated Y value
}

for k,v in pairs(internal) do Layout[k] = v end

function Layout:with(d)
	local s = self.superclass
	if s then
		for k,v in pairs(s) do if d[k] == nil then d[k] = v end end
		if s.init ~= d.init then
			local initS, initD = s.init, d.init
			d.init = function(self, p) initS(self, p); initD(self, p) end
		end
		if s.upd ~= d.upd then
			local updS, updD = s.upd, d.upd
			d.upd = function(self, p) updS(self, p); updD(self, p) end
		end
		if s.ext ~= d.ext then
			local extS, extD = s.ext, d.ext
			d.ext = function(self, p) extS(self, p); extD(self, p) end
		end		
	end
	return {
		new = function(p)
			for k,v in pairs(d) do if p[k] == nil then p[k] = v end end
			local layout = Layout.new(p)
			return layout
		end,
		superclass = d,
		with = Layout.with,
	}
end

function Layout.new(p)
	local self = Mesh.new()
	Mesh.setIndexArray(self, 1, 2, 3, 1, 3, 4)
	Mesh.setVertices(self, 1,0,0, 2,0,0, 3,0,0, 4,0,0)
	setmetatable(self, Layout)
	
	self.backup = {}
	
	for k,v in pairs(p) do
		if tonumber(k) then
			self:addChild(self.ext and self:ext(v) or v) 
		else
			self[k] = v
		end
	end
	
	if self.init then self:init(p) end
	
	if self.texture then self:setTexture(self.texture) end
	local c = self.texture and self.texC or self.bgrC
	local a = self.texture and self.texA or self.bgrA
	Mesh.setColorArray(self, c, a, c, a, c, a, c, a)
	
	self:addEventListener(Event.ENTER_FRAME, self.enterFrame, self)
	
	return self
end

function Layout:enterFrame(e)	
	if not self.__parent then return end
	local parent = self.__parent

	local update = false
	
	local parW, parH = self.parW, self.parH
	if parent.isLayout then
		if parent.w == 0 or parent.h == 0 then return end
		self.parW, self.parH = parent.w, parent.h
		self.parBorderW, self.parBorderH = parent.borderW, parent.borderH
		self.parCellW = parent.cellAbsW or parent.cellRelW * parent.w
		self.parCellH = parent.cellAbsH or parent.cellRelH * parent.h
	elseif parent == stage then
		if application:getScaleMode() == "noScale" then
			self.parW = application:getDeviceWidth()
			self.parH = application:getDeviceHeight()			
		else
			self.parW = application:getContentWidth()
			self.parH = application:getContentHeight()
		end
	else
		Sprite.removeFromParent(self)
		self.parW = parent:getWidth()
		self.parH = parent:getHeight()
		parent:addChild(self)
	end
	
	if self.parW ~= parW or self.parH ~= parH then update = true end
	
	if self.onHold and self.event == Layout.PRESS_HOLD then self:onHold() end
	
	if self.frame < self.frames then
		self.frame = self.frame + 1
		if self.mark == 0 then
			self:animate(1 - self.frame / self.frames)
		elseif self.mark == -1 then
			self:animate(self.frame / self.frames)
		elseif self.frame < self.mark then
			self:animate(self.frame / self.mark)
		elseif  self.frame == self.mark+1 and self.event == Layout.PRESS_HOLD then
			self.frame = self.frame - 1
			return
		elseif self.frame ~= self.frames then
			self:animate(1 - (self.frame - self.mark) / (self.frames - self.mark))
		end
		
		if self.frame == self.frames then
			update = true
			self:restoreState()
			if self.event == Layout.ADD then
				if self.onAdd then self:onAdd() end
				if self.events then self:enableEvents() end
			elseif self.event == Layout.REMOVE then
				if self.onRemove then self:onRemove() end
				if self == Layout.selected then
					Layout.select(self.__parent)
				end
				self.parent = nil
				Sprite.removeFromParent(self)
				return
			elseif self.event == Layout.HOVER then
				if self.onHover then self:onHover() end
			elseif self.event == Layout.PLAY then
				if self.onPlay then self:onPlay() end
				if self.events then self:enableEvents() end
			end
			if self.event ~= Layout.HOVER and self.event ~= Layout.MOVE_SCROLL then
				self.event = self.IDLE
			end
		end
	end
	
	if self.scroll or self.move or self.scale or self.tilt then
		if self.event == Layout.MOVE_SCROLL then
			local f = self.moveFriction
			self.pointerAX = f * (self.pointerAX + self.pointerDX)
			self.pointerAY = f * (self.pointerAY + self.pointerDY)
			if self.pointerDX ~= 0 or self.pointerDY ~= 0 then
				local rx, ry = self.moveReactionX, self.moveReactionY
				if self.scroll then
					self:updateScroll(rx*self.pointerDX, ry*self.pointerDY)
				end
				if self.move then
					self:updateMove(rx*self.pointerDX, ry*self.pointerDY)
					if self.parent and self.parent.scroll then
						self.parent:updateScroll(-2 * rx * self.pointerDX,
							- 2 * ry * self.pointerDY)
						self.parent.pointerAX, self.parent.pointerAY = 0, 0
					end
				end
				self.pointerX = self.pointerX + self.pointerDX
				self.pointerY = self.pointerY + self.pointerDY
				self.pointerDX, self.pointerDY = 0, 0
			end
		elseif self.event == Layout.SCALE_TILT then
			if self.pointerDX ~= 0 or self.pointerDY ~= 0 then
				if self.scale then
					local minS, maxS = self.scaleMin, self.scaleMax
					local k = self.isMouseMove and -self.scaleMouseResp
						or self.scaleTouchResp
					local s = self:getScale() + k * self.pointerDY
					if s < minS then s = minS
					elseif s > maxS then s = maxS end
					self:setScale(s)
					self.backup.scaleX, self.backup.scaleY = s, s
				end
				if self.tilt then
					local k = self.isMouseMove and self.tiltMouseResp
						or -57.3 * self.tiltTouchResp
					local r = self:getRotation() + k * self.pointerDX
					self:setRotation(r)
					self.backup.rotation = r
				end
				self.pointerX = self.pointerX + self.pointerDX
				self.pointerY = self.pointerY + self.pointerDY
				self.pointerDX, self.pointerDY = 0, 0
			end
		elseif self.scroll or self.move then
			self.pointerAX = math.abs(self.pointerAX) > self.moveDelta and
				self.moveDamping * self.pointerAX or 0
			self.pointerAY = math.abs(self.pointerAY) > self.moveDelta and
				self.moveDamping * self.pointerAY or 0
			if self.pointerAX ~= 0 or self.pointerAY ~= 0 then
				if self.scroll then
					self:updateScroll(self.pointerAX, self.pointerAY)
				end
				if self.move then
					self:updateMove(self.pointerAX, self.pointerAY)
				end
			end
		end
	end
	
	if self.parent ~= parent then
		self.parent = parent
		self:update()
		if self.anAdd then
			self.event = Layout.ADD
			if self.events then self:disableEvents() end
			self:play(self.anAdd, nil, 0)
			self:animate(1)
		else
			if self.onAdd then self:onAdd() end
			if self.events then self:enableEvents() end
		end
	elseif update then
		self:update()
	end
end

function Layout:removeFromParent()
	if self.anRemove then
		self.event = Layout.REMOVE
		self:disableEvents()
		self:play(self.anRemove, nil, -1)
	else
		if self.onRemove then self:onRemove() end
		if self == Layout.selected then
			Layout.select(self.__parent)
		end
		self.parent = nil
		Sprite.removeFromParent(self)
	end
end

-- MOUSE AND TOUCH EVENTS --

function Layout:enableEvents()
	local hoverEvents = self.anHover or self.onHover
	local moveEvents = self.scroll or self.move or self.scale or self.tilt
	local pressEvents = self.onPress or self.onHold or self.anPress
	if hoverEvents then
		self:addEventListener(Event.MOUSE_HOVER, self.onMouseHover, self)
	end
	if pressEvents or moveEvents then
		self:addEventListener(Event.MOUSE_DOWN, self.onMouseDown, self)
		self:addEventListener(Event.MOUSE_UP, self.onRelease, self)
		self:addEventListener(Event.TOUCHES_BEGIN, self.onTouchesBegin, self)
		self:addEventListener(Event.TOUCHES_END, self.onRelease, self)
	end
	if moveEvents then
		self:addEventListener(Event.MOUSE_MOVE, self.onMouseMove, self)
		self:addEventListener(Event.TOUCHES_MOVE, self.onTouchesMove, self)
	end
end

function Layout:disableEvents()
	self:removeEventListener(Event.MOUSE_DOWN, self.onMouseDown, self)
	self:removeEventListener(Event.MOUSE_UP, self.onRelease, self)
	self:removeEventListener(Event.MOUSE_MOVE, self.onMouseMove, self)
	self:removeEventListener(Event.MOUSE_HOVER, self.onMouseHover, self)
	self:removeEventListener(Event.TOUCHES_BEGIN, self.onTouchesBegin, self)
	self:removeEventListener(Event.TOUCHES_MOVE, self.onTouchesMove, self)
	self:removeEventListener(Event.TOUCHES_END, self.onRelease, self)	
end

function Layout:hitTestPoint(x, y)
	local parent = self.__parent
	if not parent then return false end
	
	if parent.events then
		if parent.frame < parent.frames then return false end
		if not parent:hitTestPoint(x, y) then return false end
	end
	
	if self.scale or self.tilt then
		local r = Sprite.getRotation(self)
		local s = Sprite.getScale(self)
		local lx, ly = Sprite.globalToLocal(self, x, y)
		Sprite.setRotation(self, 0)
		Sprite.setScale(self, 1)
		x, y = Sprite.localToGlobal(self, lx, ly)
		Sprite.setRotation(self, r)
		Sprite.setScale(self, s)
	end
	
	local x0, y0 = Sprite.localToGlobal(parent, self.x, self.y)
	return x >= x0 and y >= y0 and x <= x0 + self.w and y <= y0 + self.h
end

function Layout:bringToFront()
	local parent = self.__parent
	if parent.template then return end
	if parent:getChildIndex(self) ~= parent:getNumChildren() then
		Sprite.removeFromParent(self)
		parent:addChild(self)
	end
end

function Layout:onMouseHover(e)
	if Layout.selected:hitTestPoint(e.x, e.y) then
		return e:stopPropagation()
	end
	local focus = self:hitTestPoint(e.x, e.y)
	if self.event == Layout.HOVER then
		if not focus then self.event = Layout.IDLE end
	elseif focus then
		self:atHover()
		e:stopPropagation()
	end
end

function Layout:atHover()
	self:bringToFront()
	Layout.select(self)
	if self.onHover then self.onHover(self) end
	if self.anHover then
		if self.frame < self.frames and self.event == Layout.HOVER then
			self:continueAnimation()
		else
			self:play(self.anHover, nil, -2)
		end
	end
	self.event = Layout.HOVER
end

function Layout:onMouseDown(e)
	if e.button == 1 or e.button == 2 then
		self.pointerX, self.pointerY = e.x, e.y
		self.pointerDX, self.pointerDY = 0, 0
		if self:hitTestPoint(e.x, e.y) then
			if e.button == 1 then
				self:atPress()
			else
				self:atScaleOrTilt()
				self.isMouseMove = true
			end
			e:stopPropagation()
		end
	end
end

function Layout:onTouchesBegin(e)
	if #e.allTouches == 1 then
		self.pointerX, self.pointerY = e.touch.x, e.touch.y
		self.pointerDX, self.pointerDY = 0, 0
		if self:hitTestPoint(e.touch.x, e.touch.y) then
			self:atPress()
			e:stopPropagation()
		end
	elseif #e.allTouches == 2 then
		local t1, t2 = e.allTouches[1], e.allTouches[2]
		local x, y = (t1.x + t2.x) / 2, (t1.y + t2.y) / 2
		if self:hitTestPoint(x, y) then
			self.pointerY = math.sqrt((t1.x - t2.x)^2 + (t1.y - t2.y)^2)
			self.pointerX = math.atan2(t1.x - t2.x, t1.y - t2.y)
			self:atScaleOrTilt()
			self.isMouseMove = false
			e:stopPropagation()
		end
	end
end

function Layout:atPress()
	local parent = self.__parent
	if parent and parent.isLayout then
		parent.pointerX, parent.pointerY = self.pointerX, self.pointerY
		parent.pointerDX, parent.pointerDY = 0, 0
		parent.event = Layout.PRESS_HOLD
	end
	self:bringToFront()
	if self.anHover or self.onHover then Layout.select(self) end
	local event = self.event
	self.event = Layout.PRESS_HOLD
	if self.anPress then
		if self.frame < self.frames and event == Layout.PRESS_HOLD then
			self:continueAnimation()
		else
			self:play(self.anPress, nil, -2)
		end
	end
end

function Layout:atScaleOrTilt(e)
	self:bringToFront()
	self.pointerAX, self.pointerAY = 0, 0
	if self.frame < self.frames then
		self.frame = self.frames
		self:restoreState()
	end
	self.event = Layout.SCALE_TILT
end

function Layout:onMouseMove(e)
	self.pointerDX = e.x - self.pointerX
	self.pointerDY = e.y - self.pointerY
	if self.event == Layout.PRESS_HOLD and (
		math.abs(self.pointerDX) > self.moveDeadzone or
		math.abs(self.pointerDY) > self.moveDeadzone
	) then
		if self.frame < self.mark then self:continueAnimation() end
		self.event = Layout.MOVE_SCROLL
	end
end

function Layout:onTouchesMove(e)
	if #e.allTouches == 1 then
		self.pointerDX = e.touch.x - self.pointerX
		self.pointerDY = e.touch.y - self.pointerY
		if self.event == Layout.PRESS_HOLD and (
			math.abs(self.pointerDX) > self.moveDeadzone or
			math.abs(self.pointerDY) > self.moveDeadzone
		) then
			if self.frame < self.mark then self:continueAnimation() end
			self.event = Layout.MOVE_SCROLL
		end	
	elseif self.event == Layout.SCALE_TILT then
		local t1, t2 = e.allTouches[1], e.allTouches[2]
		self.pointerDY = math.sqrt((t1.x - t2.x)^2 + (t1.y - t2.y)^2) - self.pointerY
		self.pointerDX = math.atan2(t1.x - t2.x, t1.y - t2.y) - self.pointerX
		e:stopPropagation()
	end
	
end

local eventsToHover = {
	[Layout.PRESS_HOLD] = true,
	[Layout.MOVE_SCROLL] = true,
	[Layout.SCALE_TILT] = true,
}

function Layout:onRelease(e)
	if eventsToHover[self.event] then
		if self.event == Layout.PRESS_HOLD then
			if self.onPress then self:onPress() end
			if self.event == Layout.REMOVE then return end
			if self.frame < self.frames then self:continueAnimation() end
		end
		self.event = Layout.HOVER
		local parent = self.__parent
		if parent and parent.isLayout then
			if eventsToHover[parent.event] then
				parent.event = Layout.HOVER
			end
		end
		e:stopPropagation()
	end
end

-- UPDATING --

function Layout:update(p)
	if p then
		if self.upd then self:upd(p) end
		if p.texture ~= nil then
			local c, a
			if p.texture then
				self:setTexture(p.texture)
				c, a = self.texC, self.texA
			else
				self:clearTexture()
				c, a = self.bgrC, self.bgrA
			end
			Mesh.setColorArray(self, c, a, c, a, c, a, c, a)
		end
		if p.events ~= nil then
			if p.events then
				self:enableEvents()
			else
				self:disableEvents()
			end
		end
		if p.database ~= nil then
			self.offX, self.offY = 0, 0
			self.w, self.h = 0, 0
			self:selectCell(0, 0)
			if self.__children then
				for i, child in pairs(self.__children) do
					child:removeFromParent()
				end
			end
		end
		for k,v in pairs(p) do
			if tonumber(k) then
				self:addChild(self.ext and self:ext(v) or v) 
			else
				self[k] = v
			end
		end
		self:updateColor(p.texC, p.texA, p.bgrC, p.bgrA)
	end
	
	local w = self.col and self.parCellW * self.colW or self.absW or
		self.relW * self.parW
	local h = self.row and self.parCellH * self.rowH or self.absH or
		self.relH * self.parH
	
	if self.limW and w / h > self.limW then w = self.limW * h end
	if self.limH and h / w > self.limH then h = self.limH * w end
	
	if w ~= self.w or h ~= self.h then
		--Mesh.setVertices(self, 1,0,0, 2,w,0, 3,w,h, 4,0,h)
		Mesh.setVertices(self, 1,-1,-1, 2,w+1,-1, 3,w+1,h+1, 4,-1,h+1)
		self.w, self.h = w, h
		if self.template then
			local cols, rows = self:getGridSize()
			local w = self.cellAbsW or self.cellRelW * self.w
			local h = self.cellAbsH or self.cellRelH * self.h
			local fw, fh = w + self.borderW, h + self.borderH
			self.conW = fw * cols - self.borderW
			self.conH = fh * rows - self.borderH
		else
			if self.cols > 0 then
				self.conW = (self.cellAbsW or self.cellRelW * self.w) * self.cols
			else
				self.conW = self.conAbsW or self.conRelW * self.w
			end
			if self.rows > 0 then
				self.conH = (self.cellAbsH or self.cellRelH * self.h) * self.rows
			else
				self.conH = self.conAbsH or self.conRelH * self.h
			end
		end
		self.scrW = math.max(0, self.conW - self.w)
		self.scrH = math.max(0, self.conH - self.h)
		self.offX = math.min(self.offX, self.scrW)
		self.offY = math.min(self.offY, self.scrH)
	end
	
	local offX, offY = self.offX, self.offY
	self:setClip(offX, offY, w, h)
	
	local x = self.col and (self.parCellW + self.parBorderW) * self.col or self.absX or
		(self.relX and self.relX * self.parW or self.ancX * (self.parW - w))
	local y = self.row and (self.parCellH + self.parBorderH) * self.row or self.absY or
		(self.relY and self.relY * self.parH or self.ancY * (self.parH - h))
	
	local ax, ay = self.centerX * w, self.centerY * h
	self:setAnchorPosition(ax, ay)
	
	local rx, ry = x - offX + ax, y - offY + ay
	self:setPosition(rx, ry)
	
	self.x, self.y = x, y
	self.backup.x, self.backup.y = rx / w, ry / h
	
	if self == Layout.selected then
		Layout.selector:setSize(self.w, self.h)
	end
	
	if self.texture then self:updateTexture(self.texture) end
	
	if self.template then return self:updateTemplateGrid() end
	
	if self.sprM and self.__children then
		for _,child in pairs(self.__children) do
			if not child.isLayout then self:updateSprite(child) end
		end
	end
end

function Layout.__call(self, p, q)
	if q then
		if self.template then
			local cols, rows = self:getGridSize()
			local i = self.colsFill and p*rows + q + 1 or q*cols + p + 1
			return self.database[i]
		end
		for i = 1, self:getNumChildren() do
			local child = self:getChildAt(i)
			if child.col == p and child.row == q then return child end
		end
		return error("cell ("..tostring(p)..","..tostring(q)..") not found")
	else
		for i = 1, self:getNumChildren() do
			local child = self:getChildAt(i)
			if child.id == p then return self:getChildAt(i) end
		end
		if tonumber(p) == p then return self:getChildAt(p) end
		return error("child ("..tostring(p)..") not found")
	end
end

function Layout:updateColor(texC, texA, bgrC, bgrA)
	if self.texture then
		if texC or texA then
			local c, a = texC or self.texC, texA or self.texA
			Mesh.setColorArray(self, c, a, c, a, c, a, c, a)
		end
	elseif bgrC or bgrA then
		local c, a = bgrC or self.bgrC, bgrA or self.bgrA
		Mesh.setColorArray(self, c, a, c, a, c, a, c, a)
	end
end

function Layout:updateScroll(dx, dy)
	if dx == 0 and dy == 0 then return end
	local offX, offY = self.offX - dx, self.offY - dy
	
	if offX < 0 then
		dx = self.offX
		offX = 0
		self.pointerAX = 0
	elseif offX > self.scrW then
		dx = self.offX - self.scrW 
		offX = self.scrW
		self.pointerAX = 0
	end
	
	if offY < 0 then
		dy = self.offY
		offY = 0
		self.pointerAY = 0
	elseif offY > self.scrH then
		dy = self.offY - self.scrH
		offY = self.scrH
		self.pointerAY = 0
	end
	
	self:setClip(offX, offY, self.w, self.h)
	local x, y = self:getPosition()
	self:setPosition(x + dx, y + dy)
	self.backup.x = self.backup.x + (dx / self.w)
	self.backup.y = self.backup.y + (dy / self.h)
	
	if Layout.selected == self then
		Layout.selector:setPosition(offX, offY)
	end
	self.offX, self.offY = offX, offY
	
	if self.template and self.__children then
		for _, child in pairs(self.__children) do
			if child.frame < child.frames then
				child.frame = child.frames - 1
			end
		end
		self:updateTemplateGrid()
	end
	
	if self.onScroll then self:onScroll() end
end

function Layout:updateMove(dx, dy)
	if not self.parent or not self.parent.isLayout then return end
	local conW, conH = self.parent.conW, self.parent.conH
	
	if dx ~= 0 then
		local x1 = self.x + dx
		local x2 = x1 + self.w
		if x1 < 0 then
			dx = -self.x
		elseif x2 > conW then
			dx = conW - x2 + dx
		end
		self.x = self.x + dx
		self:setX(self:getX() + dx)
		self.backup.x = self.backup.x + (dx / self.w)
		
		if self.col then
			self.col = self.x / self.parCellW
		elseif self.absX then
			self.absX = self.x
		elseif self.relX then
			self.relX = self.x / self.parW
		elseif self.parW ~= self.w then
			self.ancX = self.x / (self.parW - self.w)
		else
			self.ancX = 0
		end
	end
	
	if dy ~= 0 then
		local y1 = self.y + dy
		local y2 = y1 + self.h
		if y1 < 0 then
			dy = -self.y
		elseif y2 > conH then
			dy = conH - y2 + dy
		end
		self.y = self.y + dy
		self:setY(self:getY() + dy)
		self.backup.y = self.backup.y + (dy / self.h)
		if self.row then
			self.row = self.y / self.parCellH
		elseif self.absY then
			self.absY = self.y
		elseif self.relY then
			self.relY = self.y / self.parH
		elseif self.parH ~= self.h then
			self.ancY = self.y / (self.parH - self.h)
		else
			self.ancY = 0
		end
	end
	
	if self.onMove then self:onMove() end
end

function Layout:updateTexture(texture)
	local pw, ph = self.w, self.h
	local tw0, th0 = texture:getWidth(), texture:getHeight()
	local tw, th = tw0 / self.texS, th0 / self.texS
	local w, h = nil, nil
	
	if     self.texM == Layout.FIT_ALL then
		local s = math.max(tw / pw, th / ph)
		w, h = s * pw, s * ph
	elseif self.texM == Layout.STRETCH then
		w, h = tw, th
	elseif self.texM == Layout.FIT_WIDTH then
		w, h = tw, ph * th / pw
	elseif self.texM == Layout.FIT_HEIGHT then
		w, h = pw * tw / ph , th
	elseif self.texM == Layout.CROP then
		local s = math.min(tw / pw, th / ph)
		w, h = s * pw, s * ph
	else
		error("texture mode '" .. tostring(self.texM) .. "' not found")
	end
	
	local x = self.texAncX*(tw0 - w) + self.texOffX
	local y = self.texAncY*(th0 - h) + self.texOffY
	self:setTextureCoordinates(1, x, y, 2, x+w, y, 3, x+w, y+h, 4, x, y+h)
end

function Layout:updateSprite(sprite)
	local pw, ph = self.w, self.h
	
	if sprite.onResize then return sprite:onResize(pw, ph) end

	sprite:setPosition(0, 0)
	sprite:setScale(1.0)
	
	local w = sprite:getWidth()
	local isText = getmetatable(sprite).getSample
	local h = isText and sprite:getLineHeight() or sprite:getHeight()
	
	if     self.sprM == Layout.FIT_ALL then
		sprite:setScale(self.sprS * math.min(pw / w, ph / h))
	elseif self.sprM == Layout.STRETCH then
		sprite:setScale(self.sprS * pw / w, self.sprS * ph / h)
	elseif self.sprM == Layout.FIT_WIDTH then
		sprite:setScale(self.sprS * pw / w)
	elseif self.sprM == Layout.FIT_HEIGHT then
		sprite:setScale(self.sprS * ph / h)
	elseif self.sprM == Layout.CROP then
		sprite:setScale(self.sprS * math.max(pw / w, ph / h))
	else
		error("sprite mode '" .. tostring(self.sprM) .. "' not found")
	end
	
	local w = sprite:getWidth()
	local h = isText and sprite:getScale() * h or sprite:getHeight()
	sprite:setPosition(self.sprX * (pw - w), self.sprY * (ph - h))
end

function Layout:getGridSize()
	local cols, rows = self.cols, self.rows
	local num = self.database and #self.database or self:getNumChildren()
	if cols == 0 and rows == 0 then -- auto grid size
		rows = math.ceil(math.sqrt(num))
		cols = math.ceil(num / rows)
	elseif rows == 0 then -- auto rows number
		rows = math.ceil(num/cols)
	elseif cols == 0 then -- auto columns number
		cols = math.ceil(num/rows)
	end
	return cols, rows, num
end

function Layout:updateTemplateGrid()
	local isSelected = self == Layout.selected
	if isSelected then Layout.selector:removeFromParent() end
	
	local cols, rows = self:getGridSize()
	local l, n = #self.database, self:getNumChildren()
	
	local w = self.cellAbsW or self.cellRelW * self.w
	local h = self.cellAbsH or self.cellRelH * self.h
	local fw, fh = w + self.borderW, h + self.borderH
	
	local vcols = math.min(cols, math.ceil(self.w / fw) + 1)
	local vrows = math.min(rows, math.ceil(self.h / fh) + 1)
	
	local vn = math.min(l, vcols * vrows)
	
	local col0 = math.floor(self.offX / fw)
	local row0 = math.floor(self.offY / fh)
	
	local colN = math.min(col0 + vcols - 1, cols)
	local rowN = math.min(row0 + vrows - 1, rows)
	
	local ucols, urows = colN - col0 + 1, rowN - row0 + 1
	
	local vn = ucols * urows
	
	if n < vn then
		for i = 1, vn - n do self:addChild(self.template.new{}) end
	elseif n > vn then
		for i = n, vn + 1, -1 do self:getChildAt(i):removeFromParent() end
	end
	
	for col = col0, colN do
		for row = row0, rowN do
			local n, i
			if self.colsFill then
				n = (col - col0) * urows + row - row0 + 1
				i = col * rows + row + 1
			else
				n = (row - row0) * ucols + col - col0 + 1
				i = row * cols + col + 1
			end
			local child = self:getChildAt(n)
			
			if child.col ~= col or child.row ~= row then
				if self.database[i] then
					local t = {col = col, row = row, parCellW = w, parCellH = h}
					for k,v in pairs(self.database[i]) do t[k] = v end
					child:update(t)
				else
					child:update{col = -1, row = -1, parCellW = 0, parCellH = 0}
				end
				if child.frame < child.frames then
					child:restoreState()
					child.event = Layout.IDLE
					child.frame = child.frames
				end
			end
		end
	end
	
	if isSelected and self:getNumChildren() > 0 then
		self:getChildAt(1):select()
	end
end

-- ANIMATION --

function Layout:setAnchorPoint(ax, ay)
	local w, h = self.w, self.h
	self:setAnchorPosition(ax * w, ay * h)
end

function Layout:getAnchorPoint()
	local x, y = self:getAnchorPosition()
	local w, h = self.w, self.h
	return x / w, y / h
end

function Layout:setRelativePosition(x, y)
	local w, h = self.w, self.h
	self:setPosition(x * w, y * h)
end

function Layout:getRelativePosition()
	local x, y = self:getPosition()
	local w, h = self.w, self.h
	return x / w, y / h
end

function Layout:continueAnimation()
	self.frame = self.mark + math.floor(
		(1 - self.frame/self.mark) * (self.frames - self.mark))
end

function Layout:animate(t)
	if self.newstate then
		local p = {}
		for k,v in pairs(self.newstate) do
			local o = self.oldstate[k]
			p[k] = o + t * (v - o)
		end
		self:update(p)
	end
	t = self.strength * t
	local anim, bak = self.anim, self.backup
	local x, y, ax, ay = anim.x, anim.y, anim.anchorX, anim.anchorY
	local r = anim.rotation
	anim.x, anim.y, anim.anchorX, anim.anchorY, anim.rotation = nil
	
	for k,v in pairs(anim) do
		self:set(k, bak[k] + t * (tonumber(v) and v or v(t)))
	end
	
	if x then
		self:setX(self.w * (bak.x + t * (tonumber(x) and x or x(t))))
	end
	if y then
		self:setY(self.h * (bak.y + t * (tonumber(y) and y or y(t))))
	end
	
	if ax or ay then
		local x, y = self:getAnchorPosition()
		if ax then
			x = self.w * (bak.anchorX + t * (tonumber(ax) and ax or ax(t)))
		end
		if ay then
			y = self.h * (bak.anchorY + t * (tonumber(ay) and ay or ay(t)))
		end
		self:setAnchorPosition(x, y)
	end
	
	if r then
		self:setRotation(bak.rotation +
			360 * t * (tonumber(r) and r or r(t)))
	end
	
	anim.x, anim.y, anim.anchorX, anim.anchorY = x, y, ax, ay
	anim.rotation = r
end

function Layout:backupState(anim)
	local bak = {}
	for k,v in pairs(anim) do bak[k] = self:get(k) end
	if anim.x or anim.y then
		bak.x, bak.y = self:getRelativePosition()
	end
	if anim.anchorX or anim.anchorY then
		bak.anchorX, bak.anchorY = self:getAnchorPoint()
	end
	self.backup = bak
end

function Layout:restoreState()
	local bak = self.backup
	local x, y, ax, ay = bak.x, bak.y, bak.anchorX, bak.anchorY
	bak.x, bak.y, bak.anchorX, bak.anchorY = nil, nil, nil, nil
	for k,v in pairs(bak) do self:set(k, v) end
	if x or y then self:setRelativePosition(x, y) end
	if ax or ay then self:setAnchorPoint(ax, ay) end
	bak.x, bak.y, bak.anchorX, bak.anchorY = x, y, ax, ay
end

function Layout:play(anim, newstate, mark)
	if not anim.frames or anim.frames <= 0 then
		error("animation: 'frames' key must be greater than 0")
	end
	if not mark and not anim.mark then
		error("animation: 'mark' key not found")
	end
	if type(newstate) == "function" then
		mark, newstate = newstate, mark
	end
	local frames, animMark, strength = anim.frames, anim.mark, anim.strength
	anim.frames, anim.mark, anim.strength = nil, nil, nil
	self:restoreState()
	self.anim = {}
	for k,v in pairs(anim) do self.anim[k] = v end
	self:backupState(anim)
	anim.frames, anim.mark, anim.strength = frames, animMark, strength
	
	if not mark then
		mark = animMark
		self.event = Layout.PLAY
		self.onPlay = false
	elseif tonumber(mark) then
		if mark == -2 then mark = animMark end
		if mark <= 0 then
		elseif mark < 1 then
			mark = math.ceil(mark*frames)
		elseif mark > frames then
			mark,frames = frames, mark
		end
		self.onPlay = false
	else
		self.onPlay = mark
		if self.events then self:disableEvents() end
		mark = animMark
		self.event = Layout.PLAY
	end
	
	self.mark, self.strength = mark, strength or 1
	self.frame, self.frames = 0, frames
	
	if newstate then
		self.newstate, self.oldstate = newstate, {}
		for k in pairs(newstate) do self.oldstate[k] = self[k] end
	else
		self.newstate = false
	end
end

-- SELECTOR --

function Layout.newSelector(w, h, lc, la, fc, fa)
	w, h = w or 0, h or 0
	lc, la = lc or Layout.selLineC, la or Layout.selLineA
	fc, fa = fc or Layout.selFillC, fa or Layout.selFillA
	local self = Path2D.new()
	self.setSize = function(self, w, h)
		w, h = w - 1, h - 1
		self:setSvgPath(string.format("M 1 1 L %s 1 L %s %s L 1 %s Z",
			w, w, h, h))
	end
	self:setSize(w, h)
	self:setConvex()
	self:setLineColor(lc, la)
	self:setFillColor(fc, fa)
	self.isLayout = true
	return self
end

function Layout:select()
	self = self or stage
	Layout.selected = self
	Sprite.removeFromParent(Layout.selector)
	if self == stage then return end
	if self.isLayout then
		local parent = self.parent
		if parent and parent.template then
			parent.selectedCol, parent.selectedRow = self.col, self.row
		end
		Layout.selector:setSize(self.w, self.h)
		Layout.selector:setLineColor(self.selLineC, self.selLineA)
		Layout.selector:setFillColor(self.selFillC, self.selFillA)
		Layout.selector:setPosition(self.offX, self.offY)
	else
		local sx, sy = self:getScale()
		Layout.selector:setSize(self:getWidth()/sx, self:getHeight()/sy)
		Layout.selector:setLineColor(Layout.selLineC, Layout.selLineA)
		Layout.selector:setFillColor(Layout.selFillC, Layout.selFillA)
		Layout.selector:setPosition(0, 0)
	end
	self:addChild(Layout.selector)
end


function Layout:selectCell(col, row)
	local col0, row0 = self.selectedCol, self.selectedRow
	local cols, rows = self:getGridSize()
	local i = self.colsFill and col*rows + row + 1 or row*cols + col + 1
	
	if col < 0 or col > cols - 1 or row < 0 or row > rows - 1
	or not self.database[i] then return end
	
	self.selectedCol, self.selectedRow = col, row
	if not self.__children then return end
	
	self.frame = self.frames
	
	local cell = nil
	for _,child in pairs(self.__children) do
		if child.col == col and child.row == row then
			cell = child
			break
		end
	end
	
	local w = self.cellAbsW or self.cellRelW * self.w
	local h = self.cellAbsH or self.cellRelH * self.h
	local fw, fh = w + self.borderW, h + self.borderH
	
	local px1, py1 = self.offX, self.offY
	local px2, py2 = px1 + self.w, py1 + self.h
	local cx1, cy1 = fw * col, fh * row
	local cx2, cy2 = cx1 + fw, cy1 + fh
	
	if col == cols - 1 then cx2 = cx2 - self.borderW end
	if row == rows - 1 then cy2 = cy2 - self.borderH end
	
	local t = {}
	if cx1 < px1 then t.offX = cx1
	elseif cx2 > px2 then t.offX = math.min(cx2 - self.w, self.scrW) end
	if cy1 < py1 then t.offY = cy1
	elseif cy2 > py2 then t.offY = math.min(cy2 - self.h, self.scrH) end
	
	if cell and not (t.offX or t.offY) then
		cell:select()
		cell.event = Layout.HOVER
		if cell.onHover then cell:onHover() end
		if cell.anHover then cell:play(cell.anHover, nil, -2) end
	else
		if cell then cell:select() end
		local a = {frames = self.scrollFrames, mark = -1}
		local c = function() self:selectCell(col, row) end
		self:play(a, t, c)
	end
end

Layout.selector = Layout.newSelector()

Layout.selected = stage

-- KEYBOARD AND GAMEPAD EVENTS

local actions = {}

local function select()
	local selected = Layout.selected
	if selected.onPress then
		selected:onPress()
	else
		Sprite.removeFromParent(Layout.selector)
		local n = selected:getNumChildren()
		if n > 0 then
			if selected.template then
				selected:selectCell(selected.selectedCol,
					selected.selectedRow)
			else
				local child = selected:getChildAt(n)
				if child.isLayout then
					Layout.select(child)
				else
					Layout.select(selected)
				end
			end
		end
	end
end

if pcall(require, "controller") then
	controller:addEventListener(Event.KEY_DOWN, function(e)
		--print("BUTTON PRESSED:", e.keyCode)
		local buttons = Layout.selected.isLayout and
			Layout.selected.buttons or Layout.buttons
		if buttons[e.keyCode] then
			actions[buttons[e.keyCode]] = true
			Layout.onKeyOrButton(buttons[e.keyCode])
		end
	end)
	
	controller:addEventListener(Event.KEY_UP, function(e)
		--print("BUTTON RELEASED:", e.keyCode)
		local buttons = Layout.selected.isLayout and
			Layout.selected.buttons or Layout.buttons
		local code = buttons[e.keyCode]
		if code then
			actions[code] = nil
			Layout.selected.event = Layout.IDLE
			if code == "SELECT" then select() end
		end
	end)
	
	local pressed = false
	controller:addEventListener(Event.LEFT_JOYSTICK, function(e)
		--print("LEFT_JOYSTICK:", e.angle, e.strength)
		local buttons = Layout.selected.isLayout and
			Layout.selected.buttons or Layout.buttons
		if buttons.stickDeadzone == 1 then return end
		if e.strength <= buttons.stickDeadzone then
			pressed = false
		elseif not pressed then
			pressed = true
			local a, pi = e.angle, math.pi
			if a >= 0.00*pi and a < 0.25*pi then
				Layout.onKeyOrButton "RIGHT"
			elseif a >= 0.25*pi and a < 0.75*pi then
				Layout.onKeyOrButton "DOWN"
			elseif a >= 0.75*pi and a < 1.25*pi then
				Layout.onKeyOrButton "LEFT"
			elseif a >= 1.25*pi and a < 1.75*pi then
				Layout.onKeyOrButton "UP"
			elseif a >= 1.75*pi and a <= 2.00*pi then
				Layout.onKeyOrButton "RIGHT"
			end
		end
	end)
end

stage:addEventListener(Event.KEY_DOWN, function(e)
	--print("KEY PRESSED:", e.realCode)
	local keys = Layout.selected.isLayout and
		Layout.selected.keys or Layout.keys
	if keys[e.realCode] then
		actions[keys[e.realCode]] = true
		Layout.onKeyOrButton(keys[e.realCode])
	end	
end)

stage:addEventListener(Event.KEY_UP, function(e)
	--print("KEY RELEASED:", e.realCode)
	local keys = Layout.selected.isLayout and
		Layout.selected.keys or Layout.keys
	local code = keys[e.realCode]
	if code then
		actions[code] = nil
		Layout.selected.event = Layout.IDLE
		if code == "SELECT" then select() end
	end
end)

stage:addEventListener(Event.MOUSE_WHEEL, function(e)
	local keys = Layout.selected.isLayout and
		Layout.selected.keys or Layout.keys
	if keys.mouseWheel then
		Layout.onKeyOrButton(e.wheel > 0 and "UP" or "DOWN")
	end
end)

function Layout.onKeyOrButton(code)
	--print("PRESSED:", code)
	local selected = Layout.selected
	local parent = selected.__parent
	if code == "SELECT" then
		actions.SELECT = nil
		if selected.isLayout and (selected.onPress or selected.anPress) then
			local event = selected.event
			selected.event = Layout.PRESS_HOLD
			if selected.anPress then
				if selected.frame < selected.frames
				and event == Layout.PRESS_HOLD then
					selected:continueAnimation()
				else
					selected:play(selected.anPress, nil, -2)
				end
			end
		end
	elseif code == "BACK" then
		actions.BACK = nil
		if parent and parent.isLayout then Layout.select(parent) end
		if selected.onBack then selected:onBack(parent) end
	elseif not actions.SELECT and not actions.BACK then
		if not parent then return end
		if parent:getNumChildren() == 1 then return end
		
		if selected.isLayout then selected.event = Layout.HOVER end
		
		if parent.template then
			local col, row = parent.selectedCol, parent.selectedRow
			if     code == "RIGHT" then col = col + 1; actions.RIGHT = nil
			elseif code == "LEFT"  then col = col - 1; actions.LEFT = nil
			elseif code == "DOWN"  then row = row + 1; actions.DOWN = nil
			elseif code == "UP"    then row = row - 1; actions.UP = nil end
			return parent:selectCell(col, row)
		end
		
		Sprite.removeFromParent(Layout.selector)
		local x0, y0
		if selected.isLayout then
			x0, y0 = selected.x, selected.y
		else
			x0, y0 = selected:getPosition()
		end
		local xMin, xMax = -math.huge, math.huge
		local yMin, yMax = -math.huge, math.huge
		if code == "RIGHT" then
			for _,child in pairs(parent.__children) do
				if child.isLayout then
					local x, y = child.x, child.y
					local dy = math.abs(y - y0)
					if x > x0 and x <= xMax and dy <= yMax then
						selected, xMax, yMax = child, x, dy
					end
				end
			end
			actions.RIGHT = nil
		elseif code == "LEFT" then
			for _,child in pairs(parent.__children) do
				if child.isLayout then
					local x, y = child.x, child.y
					local dy = math.abs(y - y0)
					if x < x0 and x >= xMin and dy <= yMax then
						selected, xMin, yMax = child, x, dy
					end
				end
			end
			actions.LEFT = nil
		elseif code == "DOWN" then
			for _,child in pairs(parent.__children) do
				if child.isLayout then
					local x, y = child.x, child.y
					local dx = math.abs(x - x0)
					if y > y0 and y <= yMax and dx <= xMax then
						selected, yMax, xMax = child, y, dx
					end
				end
			end
			actions.DOWN = nil
		elseif code == "UP" then
			for _,child in pairs(parent.__children) do
				if child.isLayout then
					local x, y = child.x, child.y
					local dx = math.abs(x - x0)
					if y < y0 and y >= yMin and dx <= xMax then
						selected, yMin, xMax = child, y, dx
					end
				end
			end
			actions.UP = nil
		end
		
		if selected ~= Layout.selected and selected.isLayout then
			if parent.scroll then
				local x1, y1 = parent.offX, parent.offY
				local x2, y2 = x1 + parent.w, y1 + parent.h
				local sx1, sy1 = selected.x, selected.y
				local sx2, sy2 = sx1 + selected.w, sy1 + selected.h
				local t = {}
				if sx1 < x1 then
					t.offX = sx1
				elseif sx2 > x2 then
					t.offX = math.min(sx2 - parent.w, parent.scrW)
				end
				if sy1 < y1 then
					t.offY = sy1
				elseif sy2 > y2 then
					t.offY = math.min(sy2 - parent.h, parent.scrH)
				end
				for k,v in pairs(t) do
					local a = {frames = parent.scrollFrames, mark = -1}
					parent:play(a, t)
					break
				end
			end
			selected.event = Layout.IDLE
			selected:atHover()
		end
		Layout.select(selected)
	end
end

function Layout.newAnimation(frames, mark, strength, seed)
	if frames and tonumber(frames) == nil then
		local p = frames
		frames = p.frames
		mark = p.mark
		strength = p.strength
		seed = p.seed
	end
	if seed then math.randomseed(seed) end
	return {
		frames          = frames or 60,
		mark            = mark or 0.5,
		strength        = strength or 1,
		x               = math.random(-1, 1),
		y               = math.random(-1, 1),
		anchorX         = math.random(-1, 1),
		anchorY         = math.random(-1, 1),
		rotation        = math.random(-1, 1),
		rotationX       = math.random(-1, 1),
		rotationY       = math.random(-1, 1),
		scaleX          = math.random(-1, 1),
		scaleY          = math.random(-1, 1),
		alpha           = math.random(-1, 0),
		redMultiplier   = math.random(-1, 0),
		greenMultiplier = math.random(-1, 0),
		blueMultiplier  = math.random(-1, 0),
		alphaMultiplier = math.random(-1, 0),
	}
end

function Layout.newResources(p)
	local path = p.path
	local subdirs = p.subdirs
	local names = p.names
	local from = p.from or 1
	local to = p.to or 1e15
	local namemod = p.namemod
	local output = p.output
	local onlynames = p.onlynames
	
	local textureFiltering = p.textureFiltering
	local textureOptions = p.textureOptions
	
	local fontSize = p.fontSize or 100
	local fontText = p.fontText
	local fontFiltering = p.fontFiltering
	
	local lfs = require "lfs"
	local att = lfs.attributes(path.."/.")
	if not att then return nil end
	
	lfs.chdir(path.."/.")
	path = lfs.currentdir():gsub("\\", "/")
	
	local t = {}
	
	if not names then
		names = {}
		local ok, err = pcall(lfs.dir, path)
		if not ok then return nil, err end
		local iter, dir = lfs.dir(path)
		while true do
			local name = dir:next()
			if not name then return {}, names end
			if name:sub(1,1) ~= "." then
				table.insert(names, name)
				break
			end
		end
		for name in iter, dir do
			table.insert(names, name)
		end
	end
	
	if output then print(require"json".encode(names)) end
	
	local prefix = path:sub(1,1) == "|" and path or path .. "/"
	local k, i = 0, 0
	for _,name in ipairs(names) do
		local data = nil
		local filename  = prefix .. name
		local e = (name:match "^.+(%..+)$" or ""):lower()
		i = i + 1
		local filenamemod = true
		if namemod then
			local base = name:sub(1, -#e - 1)
			filenamemod = namemod(filename, prefix, base, e, k + 1)
		end
		if not filenamemod then
			i = i - 1
		elseif onlynames then
			local att = lfs.attributes(filename)
			if att and att.mode == "directory" then filename = filename.."/" end
			data = filename
		elseif i < from then
			filenamemod = nil
		elseif i > to then
			break
		elseif p[e] then
			data = p[e](filename)
		elseif e == ".jpg" or e == ".png" then
			data = Texture.new(filename, textureFiltering, textureOptions)
		elseif e == ".wav" or e == ".mp3" then
			data = Sound.new(filename)
		elseif e == ".ttf" or e == ".otf" then
			data = TTFont.new(filename, fontSize, fontText, fontFiltering)
		elseif e == ".lua" then
			data = loadfile(filename)
		else
			local file = io.open(filename, "rb")
			if file then
				data = file:read "*a"
				if e == ".json" then
					data = require"json".decode(data)
				end
				file:close()
			elseif subdirs then
				p.path = filename
				local p_names = p.names
				p.names = nil
				data = Layout.newResources(p)
				p.path = path
				p.names = p_names
			end
		end
		
		if namemod then filename = filenamemod end
		
		if data and filename then
			k = k + 1
			t[filename] = data
			t[k] = data
			t[-k] = filename
		end
	end
	return t
end
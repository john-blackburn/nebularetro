--[[----------------------levman----------------------------------------
API:
levman.host           -- [string] server host like "//localhost:80"
levman.maxnamesize    -- [number] maximum number of bytes for level name
levman.count()        -- get total number of levels on server
levman.names(p1, p2, step) -- get level names from p1 to p2 on server
levman.download(name) -- download level data with that name
levman.upload(name, data) -- upload level name and data
--]]--------------------------------------------------------------------

levman = {}

levman.host = "http://localhost"
levman.maxnamesize = 32

local http = require "socket.http"

local coder = {}

local char = string.char
for i = 0, 255 do
	local b1, b2 = i // 16, i % 16
	local s = char(b1<10 and b1+48 or b1+55, b2<10 and b2+48 or b2+55)
	local c = string.char(i)
	coder[c], coder[s] = s, c
end

local function encode(s)
	local t = {}
	local sub = string.sub
	for i = 1, #s do t[i] = coder[s:sub(i, i)] end
	return table.concat(t)
end

local function decode(s)
	local t = {}
	local sub = string.sub
	for i = 2, #s, 2 do t[0.5*i] = coder[s:sub(i-1, i)] end
	return table.concat(t)
end

local function extractNames(data, maxnamesize)
	local names = {}
	for i = 1, #data/maxnamesize do
		local p1 = (i - 1) * maxnamesize + 1
		local p2 = p1 + maxnamesize - 1
		local s = decode(data:sub(p1, p2))
		names[i] = s:sub(1, -1 - #s:reverse():match" *")
	end
	return names
end

function levman.count()
	local req = levman.host.."/c/"
	local body, code, headers, status = http.request(req)
	if code ~= 200 then return nil, code end
	return headers.data
end

function levman.names(p1, p2, step)
	if step then
		local data = {}
		for i = p1, p2, step do
			local j = math.min(i + step - 1, p2)
			local req = levman.host.."/n/"..string.format("%08X%08X", i, j)
			local body, code, headers, status = http.request(req)
			if code ~= 200 then return nil, code end
			table.insert(data, headers.data)
		end
		return extractNames(table.concat(data), levman.maxnamesize)
	else
		local req = levman.host.."/n/"..string.format("%08X%08X", p1, p2)
		local body, code, headers, status = http.request(req)
		if code ~= 200 then return nil, code end
		return extractNames(headers.data, levman.maxnamesize)
	end
end

function levman.upload(name, data)
	local spaces = (" "):rep(0.5*levman.maxnamesize - #name)
	local encname = encode(name..spaces)
	local req = levman.host.."/u/"..encname..encode(data)
	local body, code, headers, status = http.request(req)
	if code ~= 200 then return nil, code end
	return true
end

function levman.download(name)
	local spaces = (" "):rep(0.5*levman.maxnamesize - #name)
	local encname = encode(name..spaces)
	local req = levman.host.."/d/"..encname
	local body, code, headers, status = http.request(req)
	if code ~= 200 then return nil, code end
	return decode(headers.data)
end
--[[----------------------levman----------------------------------------
API:
levman.host           -- [string] server host like "//localhost:80"
levman.maxnamesize    -- [number] maximum number of bytes for level name
levman.count()        -- get total number of levels on server
levman.names(p1, p2, step) -- get level names from p1 to p2 on server
levman.download(name) -- download level data with that name
levman.upload(name, data) -- upload level name and data
--]]--------------------------------------------------------------------

local http = require "socket.http"
local host = "//localhost:80"
local maxnamesize = 32

local function encodeInt(n)
	local t = {}
	local char = string.char
	t[1] = char(n >> 24 & 0xFF)
	t[2] = char(n >> 16 & 0xFF)
	t[3] = char(n >> 08 & 0xFF)
	t[4] = char(n >> 00 & 0xFF)
	return table.concat(t)
end

local function decodeInt(s)
	local a, b, c, d = s:byte(1, -1)
	return a * 0x1000000 + b * 0x10000 + c * 0x100 + d
end

local function trim(s)
	return s:sub(1, -1 - #s:reverse():match" *")
end

local function extractNames(data)
	local names = {}
	for i = 1, #data/maxnamesize do
		local p1 = (i - 1) * maxnamesize + 1
		local p2 = p1 + maxnamesize - 1
		names[i] = trim(data:sub(p1, p2))
	end
	return names
end

local function getLevelCount()
	local req = "C"
	local body, code, headers, status = http.request(host, req)
	if not body then return nil, code end
	return headers.maximum
end

local function getLevelNames(p1, p2, step)
	if step then
		local data = {}
		for i = p1, p2, step do
			local j = math.min(i + step - 1, p2)
			local req = "N"..encodeInt(i)..encodeInt(j)
			local body, code, headers, status = http.request(host, req)
			if not body then return nil, code end
			table.insert(data, headers.names)
		end
		return extractNames(table.concat(data))
	else
		local req = "N"..encodeInt(p1)..encodeInt(p2)
		local body, code, headers, status = http.request(host, req)
		if not body then return nil, code end
		return extractNames(headers.names)
	end
	
end

local function downloadLevel(name)
	local req = "D"..name
	local body, code, headers, status = http.request(host, req)
	if not body then return nil, code end
	return headers.level
end

local function uploadLevel(name, data)
	local req = "U"..(" "):rep(maxnamesize - #name)..name..data
	local body, code, headers, status = http.request(host, req)
	if not body then return nil, code end
	if headers.upload ~= "OK" then return nil, headers.upload end
	return headers.upload
end

levman = {
	host = host,
	maxnamesize = maxnamesize,
	count = getLevelCount,
	names = getLevelNames,
	download = downloadLevel,
	upload = uploadLevel,
}
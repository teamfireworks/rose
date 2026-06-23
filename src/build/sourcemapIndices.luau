-- Adapted from https://github.com/checkraisefold/warmluau/blob/8299341613adfef565a19b8ee7da25c1c66ccb10/src/ingredients/resolve_require/init.luau

const fs = require "@std/fs"
const path = require "@std/path"

export type SourcemapIndices = { [string]: string }

type SourcemapNode = {
	name: string,
	filePaths: { string }?,
	children: { SourcemapNode }?,
}

-- @std/json's deserializeObject uses `cursor < #src` instead of `cursor <= #src`,
-- so when skipWhitespace hits end-of-string it sets cursor to nil, and the next
-- string.find call with a nil position silently wraps back to 1 — corrupting the
-- parse state mid-file. We parse the sourcemap ourselves to avoid this.
local function parseSourcemapJson(source: string): SourcemapNode
	local cursor = 1

	local function skipWhitespace()
		cursor = string.find(source, "[^ \t\n\r]", cursor) or (#source + 1)
	end

	local function expect(char: string)
		skipWhitespace()
		if string.sub(source, cursor, cursor) ~= char then
			error(`expected {string.format("%q", char)} at position {cursor}, got {string.format("%q", string.sub(source, cursor, cursor))}`)
		end
		cursor += 1
	end

	local parseValue: () -> unknown

	local function parseString(): string
		expect '"'
		local start = cursor
		while cursor <= #source do
			const char = string.sub(source, cursor, cursor)
			if char == "\\" then
				cursor += 2
			elseif char == '"' then
				const result = string.sub(source, start, cursor - 1)
				cursor += 1
				return result
			else
				cursor += 1
			end
		end
		error("unterminated string")
	end

	local function parseArray(): { unknown }
		expect "["
		skipWhitespace()
		const items: { unknown } = {}
		if string.sub(source, cursor, cursor) == "]" then
			cursor += 1
			return items
		end
		while true do
			table.insert(items, parseValue())
			skipWhitespace()
			const next = string.sub(source, cursor, cursor)
			if next == "]" then
				cursor += 1
				break
			elseif next == "," then
				cursor += 1
			else
				error(`expected "," or "]" at position {cursor}`)
			end
		end
		return items
	end

	local function parseObject(): { [string]: unknown }
		expect "{"
		skipWhitespace()
		const obj: { [string]: unknown } = {}
		if string.sub(source, cursor, cursor) == "}" then
			cursor += 1
			return obj
		end
		while true do
			skipWhitespace()
			const key = parseString()
			expect ":"
			obj[key] = parseValue()
			skipWhitespace()
			const next = string.sub(source, cursor, cursor)
			if next == "}" then
				cursor += 1
				break
			elseif next == "," then
				cursor += 1
			else
				error(`expected "," or "}" at position {cursor}`)
			end
		end
		return obj
	end

	parseValue = function(): unknown
		skipWhitespace()
		const char = string.sub(source, cursor, cursor)
		if char == '"' then
			return parseString()
		elseif char == "[" then
			return parseArray()
		elseif char == "{" then
			return parseObject()
		elseif char == "t" then
			cursor += 4
			return true
		elseif char == "f" then
			cursor += 5
			return false
		elseif char == "n" then
			cursor += 4
			return nil
		else
			const numStart = cursor
			cursor = string.find(source, "[^%d%.%+%-%eE]", cursor) or (#source + 1)
			return tonumber(string.sub(source, numStart, cursor - 1))
		end
	end

	return parseValue() :: SourcemapNode
end

local function readSourcemapIndices(sourcemapPath: path.Pathlike): SourcemapIndices
	if not fs.exists(sourcemapPath) then return {} end
	const sourcemap = parseSourcemapJson(fs.readFileToString(sourcemapPath))
	const indices: SourcemapIndices = {}

	const topLevelNodes = sourcemap.children
	if not topLevelNodes then return indices end

	local nodeCount = #topLevelNodes
	for index = 1, nodeCount do
		local serviceNode = topLevelNodes[index]
		serviceNode.name = `@game/{serviceNode.name}`
	end

	local cursor = 0
	while cursor < nodeCount do
		cursor += 1
		const node = topLevelNodes[cursor]
		const nodeName = node.name

		const filePaths = node.filePaths
		if filePaths then
			for _, filePath in filePaths do
				indices[path.format(filePath)] = nodeName
			end
		end

		const children = node.children
		if children then
			const childrenCount = #children
			for childIndex = 1, childrenCount do
				local child = children[childIndex]
				child.name = `{nodeName}/{child.name}`
			end
			table.move(children, 1, childrenCount, nodeCount + 1, topLevelNodes)
			nodeCount += childrenCount
		end
	end

	return indices
end

return readSourcemapIndices

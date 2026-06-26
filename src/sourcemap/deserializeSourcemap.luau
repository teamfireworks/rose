const types = require "@rose/sourcemap/types"

-- @std/json's deserializeObject uses `cursor < #src` instead of `cursor <= #src`,
-- so when skipWhitespace hits end-of-string it sets cursor to nil, and the next
-- string.find call with a nil position silently wraps back to 1 — corrupting the
-- parse state mid-file. We parse the sourcemap ourselves to avoid this.
local function deserializeSourcemap(source: string): types.Node
	local cursor = 1

	local function skipWhitespace()
		cursor = string.find(source, "[^ \t\n\r]", cursor) or (#source + 1)
	end

	local function expect(char: string)
		skipWhitespace()
		if string.sub(source, cursor, cursor) ~= char then
			error(
				`expected {string.format("%q", char)} at position {cursor}, got {string.format(
					"%q",
					string.sub(source, cursor, cursor)
				)}`
			)
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
		error "unterminated string"
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
			-- GOD KNOWS HWTA THIS WAS MEANT TO BE
			-- TODO(bwa): can you make this string pattern valid
			cursor = string.find(source, "[^%d%.%+%-%eE]" :: any, cursor) or (#source + 1)
			return tonumber(string.sub(source, numStart, cursor - 1))
		end
	end

	return parseValue() :: types.Node
end

return deserializeSourcemap

local richterm = require "@rose/batteries/richterm"

local header = richterm.combine(richterm.bold, richterm.underline)

local function padStart(str: string, length: number)
	return string.rep(" ", length - string.len(str)) .. str
end

local function padEnd(str: string, length: number)
	return str .. string.rep(" ", length - string.len(str))
end

return table.freeze {
	padStart = padStart,
	padEnd = padEnd,
	header = header,
}

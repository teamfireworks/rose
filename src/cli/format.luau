local richterm = require "@rose/batteries/richterm"

const BANNER_LINES = table.freeze {
	"██████▄  ▄ █▀▀▄   ▄██████ ▄█████▄",
	"███ ███ ▀▀ ▄█▄ ▄█ ███▄▄▄  ███▄▄▄▄",
	"██████▀  █▄ ▀ ▄█▀  ▀▀▀███ ███▀▀▀▀",
	"███ ███ ▀█▀▀ ▀▀   ██████▀ ▀█████▀",
}

const BANNER = table.concat(BANNER_LINES, "\n")
const BANNER_INDENT = "                                   "

local header = richterm.combine(richterm.bold, richterm.underline)

local function padStart(str: string, length: number)
	return string.rep(" ", length - string.len(str)) .. str
end

local function padEnd(str: string, length: number)
	return str .. string.rep(" ", length - string.len(str))
end

return table.freeze {
	BANNER = BANNER,
	BANNER_LINES = BANNER_LINES,
	BANNER_INDENT = BANNER_INDENT,

	padStart = padStart,
	padEnd = padEnd,
	header = header,
}

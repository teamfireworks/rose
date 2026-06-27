local richterm = require "@rose/batteries/richterm"

const BANNER_LINES = table.freeze {
	"██████▄  ▄ █▀▀▄   ▄██████ ▄█████▄",
	"███ ███ ▀▀ ▄█▄ ▄█ ███▄▄▄  ███▄▄▄▄",
	"██████▀  █▄ ▀ ▄█▀  ▀▀▀███ ███▀▀▀▀",
	"███ ███ ▀█▀▀ ▀▀   ██████▀ ▀█████▀",
}

const BANNER = table.concat(BANNER_LINES, "\n")
const BANNER_INDENT = "                                 "

const LINE = "─"

const formatDivider = richterm.combine(richterm.black, richterm.dim)
const header = richterm.combine(richterm.bold, richterm.underline)

const function divider(title: string?, length: number?)
	length = length or 80

	if title then
		const titleLength = string.len(title)
		const sideLength = (length - titleLength) / 2
		const isEven = titleLength % 2 == 0
		const rightPadding = if isEven then 0 else 1

		const unformatted = string.rep(LINE, sideLength)
			.. " "
			.. richterm.bold(title)
			.. " "
			.. string.rep(LINE, sideLength + rightPadding)

		return formatDivider(unformatted)
	else
		return formatDivider(string.rep(LINE, length))
	end
end

const function padStart(str: string, length: number)
	return string.rep(" ", length - string.len(str)) .. str
end

const function padEnd(str: string, length: number)
	return str .. string.rep(" ", length - string.len(str))
end

return table.freeze {
	BANNER = BANNER,
	BANNER_LINES = BANNER_LINES,
	BANNER_INDENT = BANNER_INDENT,

	padStart = padStart,
	padEnd = padEnd,

	header = header,
	divider = divider,
}

const richterm = require "@rose/batteries/richterm"

local ROSE_ART = {
	{ "      ,--.      ", "red"   },
	{ "   ,-'_  _`-.   ", "red"   },
	{ "  /  ( \\/ )  \\  ", "red"   },
	{ " |    \\  /    | ", "red"   },
	{ "  \\   /  \\   /  ", "red"   },
	{ "   `-(____)-'   ", "red"   },
	{ "       ||       ", "stem"  },
	{ "   \\\\  ||  //   ", "green" },
	{ "    \\\\ || //    ", "green" },
	{ "      \\||/      ", "stem"  },
	{ "       ||       ", "stem"  },
	{ "     <====>     ", "green" },
}

local BIG_R = {
	"██████╗ ",
	"██╔══██╗",
	"██████╔╝",
	"██╔══██╗",
	"██║  ██║",
	"╚═╝  ╚═╝",
	"        ",
	"        ",
	"        ",
	"        ",
	"        ",
	"        ",
}

local BIG_O = {
	" ██████╗ ",
	"██╔═══██╗",
	"██║   ██║",
	"██║   ██║",
	"╚██████╔╝",
	" ╚═════╝ ",
	"         ",
	"         ",
	"         ",
	"         ",
	"         ",
	"         ",
}

local BIG_S = {
	"███████╗",
	"██╔════╝",
	"███████╗",
	"╚════██║",
	"███████║",
	"╚══════╝",
	"        ",
	"        ",
	"        ",
	"        ",
	"        ",
	"        ",
}

local BIG_E = {
	"███████╗",
	"██╔════╝",
	"█████╗  ",
	"██╔══╝  ",
	"███████╗",
	"╚══════╝",
	"        ",
	"        ",
	"        ",
	"        ",
	"        ",
	"        ",
}

local LETTERS = { BIG_R, BIG_O, BIG_S, BIG_E }

local roseRed = richterm.combine(richterm.brightRed, richterm.bold)
local stemGreen = richterm.combine(richterm.green, richterm.dim)
local leafGreen = richterm.green
local urlGray = richterm.gray

local function colorArt(line: string, color: string): string
	if color == "red" then
		return roseRed(line)
	elseif color == "green" then
		return leafGreen(line)
	else
		return stemGreen(line)
	end
end

local function hero()
	local lines = {}
	local artCount = #ROSE_ART
	for i, row in ROSE_ART do
		local artLine = colorArt(row[1], row[2])
		local textLine = ""
		for _, letter in LETTERS do
			textLine ..= letter[i]
		end
		if i == artCount then
			table.insert(lines, `  {artLine}  {urlGray "https://github.com/teamfireworks/rose.git"}`)
		else
			table.insert(lines, `  {artLine}  {roseRed(textLine)}`)
		end
	end
	table.insert(lines, "")
	return table.concat(lines, "\n")
end

return hero

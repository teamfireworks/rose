const Command = require "@rose/cli/Command"
const hero = require "@rose/batteries/hero"
const richterm = require "@rose/batteries/richterm"

local help = Command.new { help = "Show help and available commands" }

local roseRed = richterm.combine(richterm.brightRed, richterm.bold)

local function entry(name: string, description: string): string
	const paddedName = name .. string.rep(" ", 8 - #name)
	return `  {roseRed(paddedName)}  {richterm.dim(description)}`
end

function help.onRun()
	print(hero())
	print(richterm.bold "Commands:")
	print(entry("dev",    "Start a live development session for a workspace member"))
	print(entry("ls",     "List all workspace members"))
	print(entry("ripple", "Run a command across all workspace members"))
	print(entry("ropen",  "Open a place in Roblox Studio"))
	print(entry("help",   "Show this help message"))
	print()
end

return help

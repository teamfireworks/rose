const CommandStore = require "@rose/cli/CommandStore"
const runCommands = require "@rose/cli/runCommands"
const process = require "@std/process"

CommandStore.root = {
	help = "Next-generation Roblox monorepository toolchain",
	subcommands = {
		dev = require "@rose/cli/commands/dev",
		dev_new = require "@rose/cli/commands/dev_new",
		help = require "@rose/cli/commands/help",
		ls = require "@rose/cli/commands/ls",
		ripple = require "@rose/cli/commands/ripple",
		ropen = require "@rose/cli/commands/ropen",
	},
}

const args = { ... }
CommandStore.program = table.remove(args, 1)

const runResult = runCommands(args, CommandStore.root)
if runResult.success then
	process.exit(0)
else
	print "Failed to run command:"
	print(runResult.err)
	print()
	print "Traceback:"
	print(runResult.traceback)
	process.exit(1)
end

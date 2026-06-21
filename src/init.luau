const runCommands = require "@rose/cli/runCommands"
const process = require "@std/process"

const args = { ... }
table.remove(args, 1)

const runResult = runCommands(args, {
	dev = require "@self/cli/commands/dev",
	ls = require "@self/cli/commands/ls",
	ripple = require "@self/cli/commands/ripple",
	ropen = require "@self/cli/commands/ropen",
})

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

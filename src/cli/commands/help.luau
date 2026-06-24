const Command = require "@rose/cli/Command"
const CommandStore = require "@rose/cli/CommandStore"
const format = require "@rose/cli/format"

const help = Command.new { help = "Show help and available commands" }
help.args:add("command", "variadic", { help = "Command to show further info" })

const function formatOverview(commandOrSubcommands: CommandStore.CommandOrSubcommands)
	if Command.isCommand(commandOrSubcommands) then
		const command = commandOrSubcommands :: Command.Command
		return command.help
	else
		const subcommands = commandOrSubcommands :: CommandStore.Subcommands
		return subcommands.help
	end
end

const function formatSubcommands(subcommands: CommandStore.Subcommands)
	local longestLength = 0
	for commandName in subcommands.subcommands do
		longestLength = math.max(longestLength, string.len(commandName))
	end

	const nameCollumnLength = longestLength + 2

	const commandLines = {}
	for commandName, command in subcommands.subcommands do
		table.insert(commandLines, ` {format.padEnd(commandName, nameCollumnLength)} {formatOverview(command)}`)
	end
	table.sort(commandLines)

	print(subcommands.help)
	print()
	print(format.header "Commands:")
	print(table.concat(commandLines, "\n"))
end

function help.onRun()
	formatSubcommands(CommandStore.root)
end

return help

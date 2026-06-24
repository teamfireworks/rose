const result = require "@rose/batteries/result"
const Command = require "@rose/cli/Command"
const CommandStore = require "@rose/cli/CommandStore"

const function runSubcommands(args: { string }, subcommands: CommandStore.Subcommands): result.Result<nil>
	args = table.clone(args)

	const commandName = #args >= 1 and table.remove(args, 1) or "help"

	const commandOrSubcommands = subcommands.subcommands[commandName]
	return if not commandOrSubcommands
		then result.fail(`unknown command "{commandName}"`)
		elseif Command.isCommand(commandOrSubcommands) then (commandOrSubcommands :: Command.Command):run(args)
		else runSubcommands(args, (commandOrSubcommands :: any).subcommands)
end

return runSubcommands

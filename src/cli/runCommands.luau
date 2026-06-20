const result = require "@rose/batteries/result"
const Command = require "@rose/cli/Command"

export type CommandOrSubcommands = Command.Command | { [string]: CommandOrSubcommands }

const function runSubcommands(args: { string }, subcommands: { [string]: CommandOrSubcommands }): result.Result<nil>
	args = table.clone(args)

	const commandName = #args >= 1 and table.remove(args, 1) or "help"

	const commandOrSubcommands = subcommands[commandName]
	return if not commandOrSubcommands
		then result.fail(`unknown command "{commandName}"`)
		elseif Command.isCommand(commandOrSubcommands) then (commandOrSubcommands :: Command.Command):run(args)
		else runSubcommands(args, commandOrSubcommands :: { [string]: CommandOrSubcommands })
end

return runSubcommands

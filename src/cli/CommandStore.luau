-- help command needs this but cyclic requires :/

const Command = require "@rose/cli/Command"

export type Subcommands = {
	help: string,
	subcommands: { [string]: CommandOrSubcommands },
}

export type CommandOrSubcommands = Command.Command | { Subcommands }

return {
	program = (nil :: any) :: string,
	root = {} :: Subcommands,
}

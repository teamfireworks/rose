const cli = require "@rose/batteries/cli"
const result = require "@rose/batteries/result"

const Command = {}
Command.__index = Command

export type Command = setmetatable<{
	help: string,
	args: cli.Parser,
	onRun: (args: cli.Parser, commands: { [string]: Command }) -> (),
}, typeof(Command)>

function Command.isCommand(x: unknown)
	return type(x) == "table" and getmetatable(x) == Command
end

function Command.new(options: { help: string }): Command
	const self: Command = setmetatable({
		help = options.help,
		args = cli.parser(),
		onRun = function() end,
	}, Command)
	self.args:add("help", "flag", { help = "Show help", aliases = { "h" } })
	return self
end

function Command.run(self: Command, args: { string }): result.Result<nil>
	self.args:parse(args)
	if self.args:has "help" then
		print(self.help)
		self.args:help()
		return result.ok(nil)
	end
	return result.pcall(self.onRun :: (cli.Parser) -> nil, self.args)
end

return Command

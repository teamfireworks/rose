const Command = require "@rose/cli/Command"
const format = require "@rose/cli/format"
const assertWorkspace = require "@rose/workspace/assertWorkspace"
const path = require "@std/path"

const ls = Command.new { help = "Lists known workspace members" }

function ls.onRun()
	const workspace = assertWorkspace()
	for _, member in workspace.members do
		print(
			`{format.padEnd(member.name, 24)} {member.place and "(Place)" or "(Mixin)"}: {path.format(member.dirPath)}`
		)
	end
end

return ls

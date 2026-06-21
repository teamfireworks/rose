const richterm = require "@rose/batteries/richterm"
const Command = require "@rose/cli/Command"
const assertWorkspace = require "@rose/workspace/assertWorkspace"
const path = require "@std/path"
const Workspace = require "@rose/workspace/Workspace"
const io = require "@std/io"
const process = require "@std/process"
const task = require "@std/task"

const ripple = Command.new { help = "Runs a command inside all workspace members" }
ripple.args:add("concurrent", "flag", { help = "Run commands concurrently", aliases = { "c" } })
ripple.args:add("nostdio", "flag", { help = "Whether to hide stdio" })
ripple.args:add("nofail", "flag", { help = "Whether to disregard failures" })
ripple.args:add("command", "variadic", { help = "Command to execute" })

const threads: { thread } = {}

const function createRunOptions(member: Workspace.WorkspaceMember): process.ProcessSystemOptions
	return {
		cwd = path.format(member.dirPath),
		stdio = if ripple.args:has "nostdio" then "none" else "inherit",
		env = {
			ROSE_MEMBER_NAME = member.name,
			ROSE_DIR_PATH = path.format(member.dirPath),
			ROSE_CONFIG_PATH = path.format(member.configPath),
		},
	}
end

const function runMemberCommand(command: string, member: Workspace.WorkspaceMember)
	const options = createRunOptions(member)
	for key, value in options.env or {} :: never do
		command = string.gsub(command, "{" .. key .. "}", value)
	end

	print(`{member.name}: {richterm.dim(command)}`)

	const runResult = process.system(command, options)
	if runResult.ok or ripple.args:has "nofail" then return end

	for _, thread in threads do
		pcall(task.cancel, thread)
	end

	if ripple.args:has "nostdio" then
		io.write(runResult.stdout)
		io.write(runResult.stderr)
	end

	error(`command inside {member.name} failed with code {runResult.exitcode}`)
end

function ripple.onRun()
	const forwarded = ripple.args:forwarded()
	assert(forwarded and next(forwarded), "ripple needs a command to run")

	const command = table.concat(forwarded, " ")

	const workspace = assertWorkspace()
	if ripple.args:has "concurrent" then
		for _, member in workspace.members do
			task.spawn(runMemberCommand, command, member)
		end
	else
		for _, member in workspace.members do
			runMemberCommand(command, member)
		end
	end
end

return ripple

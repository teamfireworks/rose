const richterm = require "@rose/batteries/richterm"
const Command = require "@rose/cli/Command"
const assertWorkspace = require "@rose/workspace/assertWorkspace"
const path = require "@std/path"
const Workspace = require "@rose/workspace/Workspace"
const io = require "@std/io"
const process = require "@std/process"
const task = require "@std/task"

const ripple = Command.new { help = "Runs a command inside all workspace members" }
ripple.args:add("concurrent", "flag", { help = "Run commands concurrently" })
ripple.args:add("ignorestdio", "flag", { help = "Whether to hide stdio" })
ripple.args:add("ignorefailure", "flag", { help = "Whether to disregard failures" })
ripple.args:add("command", "variadic", { help = "Command to execute" })

const threads: { thread } = {}

const function createRunOptions(member: Workspace.WorkspaceMember): process.ProcessSystemOptions
	return {
		cwd = path.format(member.dirPath),
		stdio = if ripple.args:has "ignorestdio" then "none" else "inherit",
		env = {
			ROSE_DIR_NAME = member.dirName,
			ROSE_DIR_PATH = path.format(member.dirPath),
			ROSE_CONFIG_PATH = path.format(member.configPath),
		},
	}
end

const function runMemberCommand(command: string, member: Workspace.WorkspaceMember)
	if not ripple.args:has "ignorestdio" then print(richterm.black(`{member.dirName}:`)) end
	const runResult = process.system(command, createRunOptions(member))

	if runResult.ok or ripple.args:has "ignorefailure" then return end

	for _, thread in threads do
		pcall(task.cancel, thread)
	end

	if ripple.args:has "ignorestdio" then
		io.write(runResult.stdout)
		io.write(runResult.stderr)
	end

	error(`command inside {member.dirName} failed with code {runResult.exitcode}`)
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

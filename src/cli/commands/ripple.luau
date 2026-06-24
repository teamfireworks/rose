const richterm = require "@rose/batteries/richterm"
const Command = require "@rose/cli/Command"
const assertWorkspace = require "@rose/workspace/assertWorkspace"
const path = require "@std/path"
const Workspace = require "@rose/workspace/Workspace"
const io = require "@lute/io"
const process = require "@std/process"
const task = require "@std/task"

const ripple = Command.new { help = "Runs a command inside all workspace members" }
ripple.args:add("concurrent", "flag", { help = "Run commands concurrently", aliases = { "c" } })
ripple.args:add("nostdio", "flag", { help = "Whether to hide stdio" })
ripple.args:add("nofail", "flag", { help = "Whether to disregard failures" })
ripple.args:add("progress", "flag", { help = "Show progress bar instead of per-member output" })
ripple.args:add("command", "variadic", { help = "Command to execute" })

const threads: { thread } = {}

const BAR_WIDTH = 30

local ESC = "\x1b["
local function clearLine(): string
	return `{ESC}2K\r`
end
local function cursorUp(n: number): string
	return `{ESC}{n}A`
end

local function barColor(fraction: number): (text: string) -> string
	if fraction <= 0.25 then
		return richterm.red
	elseif fraction <= 0.50 then
		return richterm.brightRed
	elseif fraction <= 0.75 then
		return richterm.yellow
	else
		return richterm.green
	end
end

local function renderBar(done: number, total: number, currentName: string, currentCommand: string)
	const fraction = if total > 0 then done / total else 0
	const filled = math.floor(fraction * BAR_WIDTH)
	const empty = BAR_WIDTH - filled

	local barSegments = {}
	for i = 1, filled do
		const segFraction = i / BAR_WIDTH
		table.insert(barSegments, barColor(segFraction) "=")
	end
	const bar = table.concat(barSegments) .. richterm.dim(string.rep("-", empty))
	const counter = richterm.dim(`{done}/{total}`)

	io.write(`{clearLine()}[{bar}] {counter}\n`)

	if currentName ~= "" then
		io.write(`{clearLine()}{richterm.dim(currentName)}: {richterm.dim(currentCommand)}`)
	else
		io.write(clearLine())
	end
end

const function createRunOptions(member: Workspace.WorkspaceMember): process.ProcessSystemOptions
	return {
		cwd = path.format(member.dirPath),
		stdio = if ripple.args:has "nostdio" or ripple.args:has "progress" then "none" else "inherit",
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

	if not ripple.args:has "progress" then print(`{member.name}: {richterm.dim(command)}`) end

	const runResult = process.system(command, options)
	if runResult.ok or ripple.args:has "nofail" then return end

	for _, thread in threads do
		pcall(task.cancel, thread)
	end

	if ripple.args:has "nostdio" or ripple.args:has "progress" then
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
			table.insert(threads, task.spawn(runMemberCommand, command, member))
		end
	elseif ripple.args:has "progress" then
		const members = workspace.members
		const total = #members

		io.write(`{clearLine()}\n{clearLine()}`)

		for index, member in members do
			local displayCommand = command
			const env = createRunOptions(member).env or {} :: never
			for key, value in env do
				displayCommand = string.gsub(displayCommand, "{" .. key .. "}", value)
			end

			io.write(cursorUp(2))
			renderBar(index - 1, total, member.name, displayCommand)

			runMemberCommand(command, member)
		end

		io.write(cursorUp(2))
		renderBar(total, total, "", "")
		io.write(`\n{clearLine()}{cursorUp(1)}{clearLine()}`)
	else
		for _, member in workspace.members do
			runMemberCommand(command, member)
		end
	end
end

return ripple

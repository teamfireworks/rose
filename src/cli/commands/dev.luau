const Command = require "@rose/cli/Command"
const Session = require "@rose/Session"
const richterm = require "@rose/batteries/richterm"
const format = require "@rose/cli/format"
const assertWorkspace = require "@rose/workspace/assertWorkspace"
const assertWorkspaceMember = require "@rose/workspace/assertWorkspaceMember"
const fs = require "@std/fs"
const io = require "@lute/io"
const openStudio = require "@rose/openStudio"
const path = require "@std/path"
const process = require "@std/process"
const task = require "@std/task"
const stringext = require "@std/stringext"

const dev = Command.new { help = "Starts a development session for the workspace member" }
dev.args:add("member", "positional", { help = "Workspace member to build", required = true })

function dev.onRun()
	const workspace = assertWorkspace()
	const member = assertWorkspaceMember(workspace, dev.args:get "member" :: string)

	const sessionResult = Session.fromMember(workspace, member)
	const session = if sessionResult.success
		then sessionResult.value
		else error(`failed to instantiate session: {sessionResult.err}`)

	session:init()
	session:watchIdl()

	const sourcemapWatcher = fs.watch(workspace.sourcemap)
	task.spawn(function()
		const result = process.run {
			"rojo",
			"sourcemap",
			"--watch",
			"--absolute",
			"--include-non-scripts",
			"--output",
			path.format(workspace.sourcemap),
			path.format(workspace.sourcemapProject),
		}

		if not result.ok then
			session.log:atError(`Sourcemap process exited with code {result.exitcode}`)
			session:destroy()
			process.exit(1)
		end
	end)

	task.spawn(function()
		const result = process.run({ "rojo", "serve" }, { stdio = "inherit" })
		if not result.ok then
			session.log:atError(`Serve process exited with code {result.exitcode}`)
			session:destroy()
			process.exit(1)
		end
	end)

	-- UI

	const sessionLog = session.log

	local isUiDirty = false
	function sessionLog.outputLog()
		isUiDirty = true
	end

	const banner = table.clone(format.BANNER_LINES)
	for index, line in banner do
		banner[index] = richterm.dim(richterm.red(line))
	end

	const title = session.memberPlace.title or session.member.name
	const formatKey = richterm.combine(richterm.black, richterm.bgBrightBlack, richterm.bold)

	local showMenu = true
	local showActions = true

	local lastAction = ""

	const function renderUi()
		print(string.rep("\n", 100))

		for index = #session.log.logs, 1, -1 do
			const message = session.log.logs[index]
			print(session.log.formatLog(message))
		end

		print(format.divider())

		if showMenu then
			print(`{banner[1]} Building {richterm.bold(title)} {richterm.dim(path.format(member.dirPath))}`)
			print(`{banner[2]} Rojo: {richterm.bold(richterm.green "localhost:34872")}`)
			print(`{banner[3]}`)
			print(`{banner[4]}`)

			if showActions then
				print()
				-- stylua: ignore start
				print(`{formatKey " R "} Restart session  {formatKey " F "} Hard-clear & restart {formatKey " Q "} Exit session`)
				print(`{formatKey " W "} Open cloud place {formatKey " E "} Open local place     {formatKey " D "} Download and open local place`)
				print(`{formatKey " C "} Clear logs       {formatKey " L "} Toggle action list   {formatKey " Z "} Toggle this menu`)
				-- stylua: ignore end
			end
		end

		print()
		io.write "Input Action: "
	end

	task.spawn(function()
		while task.wait(0.05) do
			if sourcemapWatcher:next() then session:onSourcemapChanged() end
			session.watcher:checkFileWatchers()
			session:processChanges()

			if isUiDirty then
				isUiDirty = false
				renderUi()
			end
		end
	end)

	while true do
		lastAction = string.upper(stringext.trim(io.read()))

		if lastAction == "W" then
			openStudio(session.memberPlace.placeId :: string)
		elseif lastAction == "C" then
			table.clear(session.log.logs)
			isUiDirty = true
		elseif lastAction == "L" then
			showActions = not showActions
			isUiDirty = true
		elseif lastAction == "Z" then
			showMenu = not showMenu
			isUiDirty = true
		else
			session.log:atError(`Unknown command: {lastAction}`)
		end
	end
end

return dev

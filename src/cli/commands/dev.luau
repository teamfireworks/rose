const Command = require "@rose/cli/Command"
const Session = require "@rose/Session"
const assertWorkspace = require "@rose/workspace/assertWorkspace"
const assertWorkspaceMember = require "@rose/workspace/assertWorkspaceMember"
const fs = require "@std/fs"
const path = require "@std/path"
const process = require "@std/process"
const task = require "@std/task"

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
			session.log:atWarn(`Sourcemap process exited with code {result.exitcode}`)
			session:destroy()
			process.exit(1)
		end
	end)

	task.spawn(function()
		const result = process.run({ "rojo", "serve" }, { stdio = "inherit" })
		if not result.ok then
			session.log:atWarn(`Serve process exited with code {result.exitcode}`)
			session:destroy()
			process.exit(1)
		end
	end)

	print "Polling for changes..."
	while task.wait(0.05) do
		if sourcemapWatcher:next() then session:onSourcemapChanged() end
		session.watcher:checkFileWatchers()
		session:processChanges()

		-- if io.read() then
		-- 	pcall(task.cancel, rojoThread)
		-- 	session:destroy()
		-- 	break
		-- end
	end
end

return dev

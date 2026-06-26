const Command = require "@rose/cli/Command"
const Session = require "@rose/Session"
const assertWorkspace = require "@rose/workspace/assertWorkspace"
const assertWorkspaceMember = require "@rose/workspace/assertWorkspaceMember"
const luteFs = require "@lute/fs"
const io = require "@lute/io"
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

	const sourcemapDir = path.format(path.dirname(workspace.sourcemap))
	const sourcemapFilename = path.basename(workspace.sourcemap) :: string
	luteFs.watch(sourcemapDir, function(filename, event)
		if event.change and filename == sourcemapFilename then session:onSourcemapChanged() end
	end)

	const rojoThread = task.spawn(function()
		const result = process.run({ "rojo", "serve" }, { stdio = "inherit" })
		if not result.ok then
			session.log:atWarn(`Rojo exited with code {result.exitcode}`)
			session:destroy()
			process.exit(1)
		end
	end)

	print "Polling for changes..."
	while task.wait(0.05) do
		session.watcher:checkFileWatchers()
		session:processChanges()

		if io.read() then
			pcall(task.cancel, rojoThread)
			session:destroy()
			break
		end
	end
end

return dev

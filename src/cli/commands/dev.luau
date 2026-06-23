const Command = require "@rose/cli/Command"
const Session = require "@rose/build/Session"
const openStudio = require "@rose/openStudio"
const transpile = require "@rose/build/transpile"
const watchSourcemap = require "@rose/build/Watcher"
const assertWorkspace = require "@rose/workspace/assertWorkspace"
const assertWorkspaceMember = require "@rose/workspace/assertWorkspaceMember"
const divider = require "@rose/batteries/divider"
const hero = require "@rose/batteries/hero"
const richterm = require "@rose/batteries/richterm"
const luteFs = require "@lute/fs"
const fs = require "@std/fs"
const io = require "@lute/io"
const path = require "@std/path"
const process = require "@std/process"
const task = require "@std/task"

const dev = Command.new { help = "Starts a development session for the workspace member" }
dev.args:add("member", "positional", { help = "Workspace member to build", required = true })
dev.args:add("nopreinit", "flag", { help = "Whether to skip preInit steps" })

function dev.onRun()
	const workspace = assertWorkspace()
	const member = assertWorkspaceMember(workspace, dev.args:get "member" :: string)

	const sessionResult = Session.fromMember(workspace, member)
	const session = if sessionResult.success
		then sessionResult.value
		else error(`failed to instantiate session: {sessionResult.err}`)

	if not dev.args:has "nopreinit" then
		print(divider "Running pre-init steps...")
		session:preInit()
	end

	print(divider "Initializing build...")
	session:init()

	const sourcemapBaseArgs = {
		"--absolute",
		"--include-non-scripts",
		"--output",
		path.format(workspace.sourcemap),
		path.format(workspace.sourcemapProject),
	}

	print(divider "Generating sourcemap...")
	process.run({ "rojo", "sourcemap", table.unpack(sourcemapBaseArgs) }, { stdio = "inherit" })

	task.spawn(function()
		const result = process.run({ "rojo", "sourcemap", "--watch", table.unpack(sourcemapBaseArgs) }, { stdio = "inherit" })
		if not result.ok then
			print(richterm.red(`! rojo sourcemap --watch exited with code {result.exitcode}`))
		end
	end)

	const watcher = watchSourcemap()
	const devGlobals = session:getDevGlobals()
	const cwd = path.format(process.cwd())

	local function transpileFile(absolutePath: string, outputFilepath: path.Path)
		const outputDir = path.dirname(outputFilepath)
		if not fs.exists(outputDir) then fs.createDirectory(outputDir, { makeParents = true }) end
		fs.writeStringToFile(
			outputFilepath,
			transpile {
				filepath = absolutePath,
				source = fs.readFileToString(absolutePath),
				globals = devGlobals,
				sourcemapIndices = session.currentSourcemapIndices,
			}
		)
	end

	local function displayPath(absolutePath: string): string
		const relative = path.format(path.relative(cwd, absolutePath))
		return if relative ~= "" then relative else absolutePath
	end

	local function processChanges()
		for absolutePath, action in watcher.changes do
			if (action == "removed" or fs.exists(absolutePath)) and session:shouldTranspile(absolutePath) then
				const outputFilepath = session:getOutputFilepath(absolutePath)

				if action == "added" then
					transpileFile(absolutePath, outputFilepath)
					print(richterm.green(`+ {displayPath(absolutePath)}`))
				elseif action == "changed" then
					transpileFile(absolutePath, outputFilepath)
					print(richterm.cyan(`↻ {displayPath(absolutePath)}`))
				elseif action == "removed" then
					fs.remove(outputFilepath)
					print(richterm.red(`- {displayPath(absolutePath)}`))
				end
			end
		end

		table.clear(watcher.changes)
	end

	print(divider "Running initial transpilation...")
	session:refreshSourcemapIndices()
	watcher.onChanged(session.currentSourcemapIndices)
	processChanges()

	-- register the sourcemap watcher after the initial pass to avoid a race with rojo sourcemap --watch
	local sourcemapChanged = false
	const sourcemapDir = path.format(path.dirname(workspace.sourcemap))
	const sourcemapFilename = path.basename(workspace.sourcemap) :: string
	luteFs.watch(sourcemapDir, function(filename, event)
		if event.change and filename == sourcemapFilename then
			sourcemapChanged = true
		end
	end)

	print(divider())
	task.spawn(function()
		const result = process.run({ "rojo", "serve" }, { stdio = "inherit" })
		if not result.ok then
			print(richterm.red(`! rojo serve exited with code {result.exitcode}`))
		end
	end)

	task.delay(0.1, function()
		print(hero())

		const memberPlaceId = session.memberPlace.placeId
		if memberPlaceId then
			print(richterm.blue(`Press {richterm.bold "Enter"} to open {session.memberPlace.title} in Roblox Studio.`))
		end

		print(divider "Polling for changes...")
		while task.wait(0.05) do
			if sourcemapChanged then
				sourcemapChanged = false
				session:refreshSourcemapIndices()
				watcher.onChanged(session.currentSourcemapIndices)
			end
			processChanges()
		end
	end)

	while io.read() do
		const memberPlaceId = session.memberPlace.placeId
		if memberPlaceId then openStudio(memberPlaceId) end
	end
end

return dev

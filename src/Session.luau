const result = require "@rose/batteries/result"
const insertMapping = require "@rose/insertMapping"
const configuration = require "@rose/configuration"
const copyInto = require "@rose/copyInto"
const deepClone = require "@rose/deepClone"
const Workspace = require "@rose/workspace/Workspace"
const fs = require "@std/fs"
const json = require "@std/json"
const path = require "@std/path"
const process = require "@std/process"
const Watcher = require "@rose/sourcemap/Watcher"
const Log = require "@rose/Log"
const indexSourcemap = require "@rose/sourcemap/indexSourcemap"
const transformers = require "@rose/transpilation/transformers"
const transpile = require "@rose/transpilation/transpile"
const syntax = require "@std/syntax"
const task = require "@std/task"

const Session = {}
Session.__index = Session

export type Session = setmetatable<{
	workspace: Workspace.Workspace,

	member: Workspace.WorkspaceMember,
	memberPlace: configuration.Place,
	memberDependencies: { Workspace.WorkspaceMember },
	rojoDependencies: { Workspace.WorkspaceMember },

	cwd: path.Path,
	buildDir: path.Path,
	profile: configuration.Profile?,

	log: Log.Log,
	watcher: Watcher.Watcher,
}, typeof(Session)>

function Session.fromMember(
	workspace: Workspace.Workspace,
	member: Workspace.WorkspaceMember,
	profile: configuration.Profile?
): result.Result<Session>
	if member.place == nil then result.fail(`workspace member must be a rose.place`) end

	const dependencies = workspace:resolveDependencies(member)
	if not dependencies.success then return dependencies end

	profile = profile or if workspace.profiles then workspace.profiles.default else nil

	return result.ok<<Session>>(setmetatable({
		workspace = workspace,

		member = member,
		memberPlace = member.place,
		memberDependencies = dependencies.value,
		rojoDependencies = { member, table.unpack(dependencies.value) },

		cwd = process.cwd(),
		buildDir = path.join(workspace.buildDir, member.name),
		profile = nil :: configuration.Profile?,

		log = Log.new(),
		watcher = Watcher.new(),
	}, Session))
end

-- Paths

function Session.getMemberBuildDir(self: Session, member: Workspace.WorkspaceMember)
	return path.join(self.buildDir, member.name)
end

function Session.getOutputFilepath(self: Session, sourceFilepath: path.Pathlike): path.Path
	const member = self.workspace:resolveMemberFromPath(sourceFilepath) :: Workspace.WorkspaceMember
	const memberBuildDir = self:getMemberBuildDir(member)
	const absoluteMemberDir = path.resolve(member.dirPath)
	const relativeToMember = path.relative(absoluteMemberDir, path.resolve(sourceFilepath))
	return path.join(memberBuildDir, relativeToMember)
end

function Session.getDisplayPath(self: Session, absolutePath: string): string
	const relative = path.format(path.relative(self.cwd, absolutePath))
	return if relative ~= "" then relative else absolutePath
end

-- Rojo

function Session.getRojoProject(self: Session, kind: "build" | "sourcemap")
	const project = deepClone(self.workspace.build.place.baseProject or {} :: never)
	project.name = project.name or `{self.workspace.name}: {self.rojoDependencies[1].place.title}`

	const tree: configuration.RojoInstance = project.tree or {} :: never
	tree["$className"] = "DataModel"
	project.tree = tree

	const dirMappings = self.workspace.build.place.dirMappings
	for _, member in self.rojoDependencies do
		if member.place then
			const baseDir = kind == "build" and self:getMemberBuildDir(member) or member.dirPath
			for dir, segments in dirMappings do
				const mappingDir = path.join(baseDir, dir)
				insertMapping(tree, segments, member.folderName or member.name, mappingDir)
			end
		end

		if member.placeMixin then
			const mixinDir = kind == "build" and self:getMemberBuildDir(member) or member.dirPath
			insertMapping(tree, member.placeMixin.mapping, member.folderName or member.name, mixinDir)
		end
	end

	return project
end

-- Transpilation

function Session.getGlobals(self: Session): configuration.Globals
	const globals = self.workspace.build.globals and table.clone(self.workspace.build.globals)
		or {} :: configuration.Globals

	if self.profile and self.profile.globals then
		for key, value in self.profile.globals do
			globals[key] = value
		end
	end

	globals.__DEV__ = { value = false }
	globals.ROSE_DIR_NAME = { value = self.member.name }
	globals.ROSE_PLACE_FOLDER = { value = self.memberPlace.folderName }
	globals.ROSE_PLACE_TITLE = { value = self.memberPlace.title }
	globals.ROSE_PLACE_SUBTITLE = { value = self.memberPlace.subtitle }

	return globals
end

function Session.shouldTranspile(self: Session, filepath: path.Pathlike): boolean
	const member = self.workspace:resolveMemberFromPath(filepath)
	if not member then return false end
	if member.place then return true end
	if member.placeMixin then return member.placeMixin.transpile == true end
	return false
end

function Session.transpileFile(self: Session, absolutePath: string)
	const outputFilepath = self:getOutputFilepath(absolutePath)

	const outputDir = path.dirname(outputFilepath)
	if not fs.exists(outputDir) then fs.createDirectory(outputDir, { makeParents = true }) end

	const source = fs.readFileToString(absolutePath)
	const parseSuccess, treeOrError = pcall(syntax.parse, source)

	if not parseSuccess then return self.log:atWarn(`Failed to parse {absolutePath}:`, tostring(treeOrError)) end

	const outputSource = transpile(transformers.BUILD_TRANSFORMERS, {
		tree = treeOrError,
		source = source,
		filepath = absolutePath,

		log = self.log,
		globals = self:getGlobals(),
		sourcemapIndices = self.watcher.currentIndices,
	})

	fs.writeStringToFile(outputFilepath, outputSource)
end

-- Processor

function Session.processChanges(self: Session)
	for absolutePath, action in self.watcher.changes do
		if (action == "remove" or fs.exists(absolutePath)) and self:shouldTranspile(absolutePath) then
			if action == "add" then
				self:transpileFile(absolutePath)
				self.log:atAdd(self:getDisplayPath(absolutePath))
			elseif action == "change" then
				self:transpileFile(absolutePath)
				self.log:atChange(self:getDisplayPath(absolutePath))
			elseif action == "remove" then
				pcall(fs.remove, self:getOutputFilepath(absolutePath))
				self.log:atRemove(self:getDisplayPath(absolutePath))
			end
		end
	end

	table.clear(self.watcher.changes)
end

function Session.onSourcemapChanged(self: Session)
	self.watcher:onChanged(indexSourcemap(fs.readFileToString(self.workspace.sourcemap)))
end

function Session.watchIdl(self: Session)
	const idl = self.workspace.build.idl
	if not idl then return end

	for _, member in self.rojoDependencies do
		const filepath = path.format(path.join(member.dirPath, idl.filename))
		if fs.exists(filepath) then
			task.spawn(process.run, {
				idl.program,
				path.format(path.join(member.dirPath, idl.filename)),
				"--yes",
				"--watch",
			}, nil :: process.ProcessRunOptions?)
		end
	end
end

function Session.init(self: Session)
	const preInit = self.workspace.buildScripts.preInit
	if preInit then process.system(preInit, { stdio = "inherit" }) end

	if fs.exists(self.buildDir) then
		for _, file in fs.listDirectory(self.buildDir) do
			local filepath = path.join(self.buildDir, file.name)
			if file.type == "dir" then
				fs.removeDirectory(filepath, { recursive = true })
			elseif file.type == "file" then
				fs.remove(filepath)
			end
		end
	else
		fs.createDirectory(self.buildDir, { makeParents = true })
	end

	for _, member in self.rojoDependencies do
		copyInto(member.dirPath, self:getMemberBuildDir(member))
	end

	const buildProject = json.serialize(self:getRojoProject "build" :: json.Object)
	fs.writeStringToFile(self.workspace.buildProject, buildProject)

	const sourcemapProject = json.serialize(self:getRojoProject "sourcemap" :: json.Object)
	fs.writeStringToFile(self.workspace.sourcemapProject, sourcemapProject)

	const idl = self.workspace.build.idl
	if idl then
		for _, member in self.rojoDependencies do
			const filepath = path.format(path.join(member.dirPath, idl.filename))
			if fs.exists(filepath) then
				process.run({
					idl.program,
					path.format(path.join(member.dirPath, idl.filename)),
					"--yes",
				}, { stdio = "inherit" })
			end
		end
	end

	process.run({
		"rojo",
		"sourcemap",
		"--absolute",
		"--include-non-scripts",
		"--output",
		path.format(self.workspace.sourcemap),
		path.format(self.workspace.sourcemapProject),
	}, { stdio = "inherit" })

	task.wait(0.5)

	self:onSourcemapChanged()
	self:processChanges()
end

function Session.destroy(self: Session)
	self.watcher:destroy()
end

return table.freeze(Session)

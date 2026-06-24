const result = require "@rose/batteries/result"
const richterm = require "@rose/batteries/richterm"
const insertMapping = require "@rose/build/insertMapping"
const sourcemapIndices = require "@rose/build/sourcemapIndices"
const configuration = require "@rose/configuration"
const copyInto = require "@rose/copyInto"
const deepClone = require "@rose/deepClone"
const uuid = require "@rose/vendor/uuid"
const Workspace = require "@rose/workspace/Workspace"
const fs = require "@std/fs"
const json = require "@std/json"
const path = require "@std/path"
const process = require "@std/process"
const task = require "@std/task"

const Session = {}
Session.__index = Session

export type Session = setmetatable<{
	workspace: Workspace.Workspace,

	member: Workspace.WorkspaceMember,
	memberPlace: configuration.Place,
	memberDependencies: { Workspace.WorkspaceMember },
	rojoDependencies: { Workspace.WorkspaceMember },

	profile: configuration.Profile?,
	initThreads: { thread },

	buildDir: path.Path,
	currentSourcemapIndices: sourcemapIndices.SourcemapIndices,
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

	const self: Session = setmetatable({
		workspace = workspace,

		member = member,
		memberPlace = member.place,
		memberDependencies = dependencies.value,
		rojoDependencies = { member, table.unpack(dependencies.value) },

		profile = profile or if workspace.profiles then workspace.profiles.default else nil,
		initThreads = {},

		buildDir = path.join(workspace.buildDir, uuid()),
		currentSourcemapIndices = {},
	}, Session)

	return result.ok(self)
end

function Session.getMemberBuildDir(self: Session, member: Workspace.WorkspaceMember)
	return path.join(self.buildDir, member.name)
end

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
				insertMapping(tree, segments, member.name, mappingDir)
			end
		end

		if member.placeMixin then
			const mixinDir = kind == "build" and self:getMemberBuildDir(member) or member.dirPath
			insertMapping(tree, member.placeMixin.mapping, member.name, mixinDir)
		end
	end

	return project
end

function Session.getGlobals(self: Session): configuration.Globals
	const globals = self.workspace.build.globals and table.clone(self.workspace.build.globals)
		or {} :: configuration.Globals

	if self.profile and self.profile.globals then
		for key, value in self.profile.globals do
			globals[key] = value
		end
	end

	globals.__DEV__ = { value = true }
	globals.ROSE_DIR_NAME = { value = self.member.name }
	globals.ROSE_PLACE_FOLDER = { value = self.memberPlace.folderName }
	globals.ROSE_PLACE_TITLE = { value = self.memberPlace.title }
	globals.ROSE_PLACE_SUBTITLE = { value = self.memberPlace.subtitle }

	return globals
end

function Session.getDevGlobals(self: Session): configuration.Globals
	const globals = self:getGlobals()

	return globals
end

local function substituteStepTemplates(stepString: string, member: Workspace.WorkspaceMember): string
	return (stepString:gsub("{ROSE_DIR_PATH}", path.format(member.dirPath)))
end

function Session.preInit(self: Session)
	const preInit = self.workspace.build.preInit
	if not preInit then return end

	for _, step in preInit do
		if step.run then
			const command = substituteStepTemplates(step.run, self.member)
			process.system(command, { stdio = "inherit" })
		elseif step.spawn then
			const command = substituteStepTemplates(step.spawn, self.member)
			print(richterm.black(command))
			table.insert(
				self.initThreads,
				task.spawn(process.system, command, { stdio = "inherit" } :: process.ProcessSystemOptions)
			)
		end
	end
end

function Session.shouldTranspile(self: Session, filepath: path.Pathlike): boolean
	const member = self.workspace:resolveMemberFromPath(filepath)
	if not member then return false end
	if member.place then return true end
	if member.placeMixin then return member.placeMixin.transpile == true end
	return false
end

function Session.getOutputFilepath(self: Session, sourceFilepath: path.Pathlike): path.Path
	const member = self.workspace:resolveMemberFromPath(sourceFilepath) :: Workspace.WorkspaceMember
	const memberBuildDir = self:getMemberBuildDir(member)
	const absoluteMemberDir = path.resolve(member.dirPath)
	const relativeToMember = path.relative(absoluteMemberDir, path.resolve(sourceFilepath))
	return path.join(memberBuildDir, relativeToMember)
end

function Session.refreshSourcemapIndices(self: Session)
	self.currentSourcemapIndices = sourcemapIndices(self.workspace.sourcemap)
end

function Session.init(self: Session)
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
end

return table.freeze(Session)

const result = require "@rose/batteries/result"
const richterm = require "@rose/batteries/richterm"
const insertMapping = require "@rose/build/insertMapping"
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
			insertMapping(tree, member.placeMixin.mapping, member.name, self:getMemberBuildDir(member))
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
	return globals
end

function Session.preInit(self: Session)
	const preInit = self.workspace.build.preInit
	if not preInit then return end

	for _, step in preInit do
		if step.run then
			print(richterm.black(step.run))
			process.system(step.run, { stdio = "inherit" })
		elseif step.spawn then
			print(richterm.black(step.spawn))
			table.insert(
				self.initThreads,
				task.spawn(process.system, step.spawn, { stdio = "inherit" } :: process.ProcessSystemOptions)
			)
		end
	end
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

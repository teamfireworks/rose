const glob = require "@rose/batteries/glob"
const result = require "@rose/batteries/result"
const configuration = require "@rose/configuration"
const loadConfig = require "@rose/workspace/loadConfig"
const fs = require "@std/fs"
const path = require "@std/path"

const CONFIG_FILE_NAME = ".config.luau"

const Workspace = {}
Workspace.__index = Workspace

type WorkspaceData = {
	buildDir: path.Pathlike,
	buildProject: path.Pathlike,
	sourcemapProject: path.Pathlike,
	sourcemap: path.Pathlike,

	name: string,
	build: index<configuration.Workspace, "build">,
	profiles: index<configuration.Workspace, "profiles">,

	members: { WorkspaceMember },
	nameToMembers: { [string]: WorkspaceMember },
}

export type WorkspaceMember = {
	name: string,
	place: configuration.Place,
	placeMixin: configuration.PlaceMixin,

	dirPath: path.Pathlike,
	configPath: path.Pathlike,
}

export type Workspace = setmetatable<WorkspaceData, typeof(Workspace)>

const function tryResolveMember(dirPath: path.Pathlike): result.Result<WorkspaceMember>
	if fs.type(dirPath) ~= "dir" then return result.fail "expected directory" end

	const configPath = path.join(dirPath, CONFIG_FILE_NAME)
	if not fs.exists(configPath) then return result.fail(`expected {CONFIG_FILE_NAME}`) end

	const configResult = loadConfig(configPath)
	if not configResult.success then return configResult end

	const config = configResult.value.rose
	if not config then return result.fail(`missing rose field in {CONFIG_FILE_NAME}`) end
	if config.workspace then return result.fail(`expected rose.place or rose.placeMixin, got rose.workspace`) end
	if config.place and config.placeMixin then result.fail(`rose.place and rose.placeMixin is mutually exclusive`) end

	const member: WorkspaceMember = {
		name = config.place and config.place.name or path.basename(dirPath) :: string,
		place = config.place :: configuration.Place,
		placeMixin = config.placeMixin :: configuration.PlaceMixin,

		dirPath = dirPath,
		configPath = configPath,
	}

	return result.ok(member)
end

function Workspace.fromConfig(workspaceConfig: configuration.Workspace): result.Result<Workspace>
	const workspacePaths = workspaceConfig.paths or {} :: never

	const self: WorkspaceData = {
		buildDir = workspacePaths.buildDir or ".rose/build",
		buildProject = workspacePaths.buildProject or "default.project.json",
		sourcemapProject = workspacePaths.sourcemapProject or "sourcemap.project.json",
		sourcemap = workspacePaths.sourcemap or "sourcemap.json",

		name = workspaceConfig.name,
		build = workspaceConfig.build,
		profiles = workspaceConfig.profiles,

		members = {},
		nameToMembers = {},
	}

	for _, pattern in workspaceConfig.members do
		for _, dirPath in glob.discover(pattern) do
			const memberResult = tryResolveMember(dirPath)
			if memberResult.success then
				const member = memberResult.value
				if self.nameToMembers[member.name] then
					return result.fail(`conflicting dir name {string.format("%q", path.basename(dirPath) :: string)}`)
				end
				self.nameToMembers[member.name] = member
				table.insert(self.members, memberResult.value)
			end
		end
	end

	return result.ok(setmetatable(self, Workspace))
end

function Workspace.resolveDependencies(self: Workspace, member: WorkspaceMember): result.Result<{ WorkspaceMember }>
	local resolved, resolvedSet, visiting = {}, {}, {}

	local function visit(current: WorkspaceMember, stack: { string })
		local place = current.place
		if not place then return resolved end

		if visiting[current.name] then
			local cycleStart = table.find(stack, current.name) or 1
			local cycle = table.move(stack, cycleStart, #stack, 1, {})
			table.insert(cycle, current.name)

			error(`place has cyclic dependency: {table.concat(cycle, " -> ")}`)
		end

		if resolvedSet[current.name] then return resolved end

		visiting[current.name] = true
		table.insert(stack, current.name)

		for _, dependencyName in place.dependencies or {} do
			local dependency = self.nameToMembers[dependencyName]
				or error(`place {current.name} has unknown dependency named {dependencyName}`)
			visit(dependency, stack)

			if not resolvedSet[dependency.name] then
				resolvedSet[dependency.name] = true
				table.insert(resolved, dependency)
			end
		end

		visiting[current.name] = nil
		table.remove(stack)

		return resolved
	end

	return result.pcall(visit, member, {} :: { string })
end

function Workspace.resolveMemberFromPath(self: Workspace, filepath: path.Pathlike): WorkspaceMember?
	local firstPart = path.parse(filepath).parts[1]
	return self.nameToMembers[firstPart]
end

return table.freeze(Workspace)

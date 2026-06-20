const glob = require "@rose/batteries/glob"
const result = require "@rose/batteries/result"
const typecheckers = require "@rose/typecheckers"
const fs = require "@std/fs"
const luau = require "@std/luau"
const path = require "@std/path"

export type WorkspaceMember = {
	place: typecheckers.Place,
	placeBuildDirPath: path.Pathlike,

	placeMixin: typecheckers.PlaceMixin,

	dirName: string,
	dirPath: path.Pathlike,
	configPath: path.Pathlike,

	mappings: {
		build: { [string]: path.Pathlike },
		sourcemap: { [string]: path.Pathlike },
	},
}

export type Workspace = {
	buildDir: path.Pathlike,
	buildProject: path.Pathlike,
	sourcemapProject: path.Pathlike,
	sourcemap: path.Pathlike,

	name: string,
	build: index<typecheckers.Workspace, "build">,
	profiles: index<typecheckers.Workspace, "profiles">,

	members: { WorkspaceMember },
	dirToMembers: { [string]: WorkspaceMember },
}

const CONFIG_FILE_NAME = ".config.luau"

const function loadConfig(filepath: path.Pathlike): result.Result<typecheckers.LuauConfig>
	const module = luau.loadModule(filepath)
	const isConfig, configError = typecheckers.LuauConfig:matches(module)
	return if isConfig then result.ok(module) else result.fail(configError:formatErr())
end

const function loadWorkspaceConfig(): result.Result<typecheckers.Workspace>
	const configResult = loadConfig(CONFIG_FILE_NAME)
	return if configResult.success
		then if configResult.value.rose and configResult.value.rose.workspace
			then result.ok(configResult.value.rose.workspace)
			else result.fail "configuration missing rose.workspace field"
		else configResult
end

const function resolveWorkspaceMember(workspace: Workspace, dirPath: path.Pathlike): result.Result<WorkspaceMember>
	if fs.type(dirPath) ~= "dir" then return result.fail "expected directory" end

	const configPath = path.join(dirPath, CONFIG_FILE_NAME)
	if not fs.exists(configPath) then return result.fail(`expected {CONFIG_FILE_NAME}`) end

	const configResult = loadConfig(configPath)
	if not configResult.success then return configResult end

	const config = configResult.value.rose
	if not config then return result.fail(`missing rose field in {CONFIG_FILE_NAME}`) end
	if config.workspace then return result.fail(`expected rose.place or rose.placeMixin, got rose.workspace`) end
	if config.place and config.placeMixin then result.fail(`rose.place and rose.placeMixin is mutually exclusive`) end

	const dirName = path.basename(dirPath) :: string
	const mappings: index<WorkspaceMember, "mappings"> = { build = {}, sourcemap = {} }
	for mappingDir in workspace.build.place.dirMappings do
		mappings.build[mappingDir] = path.join(workspace.buildDir, dirName, mappingDir)
		mappings.sourcemap[mappingDir] = path.join(dirPath, mappingDir)
	end

	const member: WorkspaceMember = {
		place = config.place :: typecheckers.Place,
		placeBuildDirPath = path.join(workspace.buildDir, dirName),
		placeMixin = config.placeMixin :: typecheckers.PlaceMixin,

		dirName = dirName,
		dirPath = dirPath,
		configPath = configPath,

		mappings = mappings,
	}

	return result.ok(member)
end

const function resolveWorkspace(workspaceConfig: typecheckers.Workspace): result.Result<Workspace>
	const paths = workspaceConfig.paths or {} :: never

	const workspace: Workspace = {
		buildDir = paths.buildDir or ".build",
		buildProject = paths.buildProject or "default.project.json",
		sourcemapProject = paths.sourcemapProject or "sourcemap.project.json",
		sourcemap = paths.sourcemap or "sourcemap.json",

		name = workspaceConfig.name,
		build = workspaceConfig.build,
		profiles = workspaceConfig.profiles,

		members = {},
		dirToMembers = {},
	}

	for _, pattern in workspaceConfig.members do
		for _, dirPath in glob.discover(pattern) do
			const memberResult = resolveWorkspaceMember(workspace, dirPath)
			if memberResult.success then
				const member = memberResult.value
				if workspace.dirToMembers[member.dirName] then
					return result.fail(`conflicting dir name {string.format("%q", path.basename(dirPath) :: string)}`)
				end
				workspace.dirToMembers[member.dirName] = member
				table.insert(workspace.members, memberResult.value)
			end
		end
	end

	return result.ok(workspace)
end

return table.freeze {
	loadWorkspaceConfig = loadWorkspaceConfig,
	resolveWorkspace = resolveWorkspace,
}

const Workspace = require "@rose/workspace/Workspace"
const loadWorkspaceConfig = require "@rose/workspace/loadWorkspaceConfig"

const function assertWorkspace(): Workspace.Workspace
	const configResult = loadWorkspaceConfig()
	if not configResult.success then error("Failed to load workspace .config.luau: " .. configResult.err) end

	const workspaceResult = Workspace.fromConfig(configResult.value)
	if not workspaceResult.success then error("Failed to instantiate workspace: " .. workspaceResult.err) end

	return workspaceResult.value
end

return assertWorkspace

const pp = require "@rose/batteries/pp"
const Workspace = require "@rose/workspace/Workspace"
const loadWorkspaceConfig = require "@rose/workspace/loadWorkspaceConfig"

const config = loadWorkspaceConfig()
if config.success then
	const workspace = Workspace.fromConfig(config.value)
	if workspace.success then print(pp(workspace)) end
end

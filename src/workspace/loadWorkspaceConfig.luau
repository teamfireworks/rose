const result = require "@rose/batteries/result"
const configuration = require "@rose/configuration"
const loadConfig = require "@rose/workspace/loadConfig"

const function loadWorkspaceConfig(): result.Result<configuration.Workspace>
	const configResult = loadConfig ".config.luau"
	return if configResult.success
		then if configResult.value.rose and configResult.value.rose.workspace
			then result.ok(configResult.value.rose.workspace)
			else result.fail "configuration missing rose.workspace field"
		else configResult
end

return loadWorkspaceConfig

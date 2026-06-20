const path = require "@std/path"
const result = require "@rose/batteries/result"
const configuration = require "@rose/configuration"
const luau = require "@std/luau"

const function loadConfig(configPath: path.Pathlike): result.Result<configuration.LuauConfig>
	const module = luau.loadModule(configPath)
	const isConfig, configError = configuration.LuauConfig:matches(module)
	return if isConfig then result.ok(module) else result.fail(configError:formatErr())
end

return loadConfig

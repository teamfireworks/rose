const pp = require "@rose/batteries/pp"
const resolver = require "@rose/resolver"

const result = resolver.loadWorkspaceConfig()
if result.success then print(pp(resolver.resolveWorkspace(result.value))) end

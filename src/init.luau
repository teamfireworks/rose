const pp = require "@rose/batteries/pp"
const discovery = require "@rose/discovery"

const result = discovery.loadWorkspaceConfig()
if result.success then print(pp(discovery.resolveWorkspace(result.value))) end

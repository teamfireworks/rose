const configuration = require "@rose/configuration"
const Workspace = require "@rose/workspace/Workspace"
const assertWorkspaceMember = require "@rose/workspace/assertWorkspaceMember"

const function assertWorkspacePlace(
	workspace: Workspace.Workspace,
	name: string
): (configuration.Place, Workspace.WorkspaceMember)
	const member = assertWorkspaceMember(workspace, name)
	const memberPlace = member.place or error(`workspace member {name} must be a rose.place`)
	return memberPlace, member
end

return assertWorkspacePlace

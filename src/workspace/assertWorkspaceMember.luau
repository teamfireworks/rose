const Workspace = require "@rose/workspace/Workspace"

const function assertWorkspaceMember(workspace: Workspace.Workspace, name: string): Workspace.WorkspaceMember
	const member = workspace.nameToMembers[name] or error(`unknown workspace member named {name}`)
	return member
end

return assertWorkspaceMember

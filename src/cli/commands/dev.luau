const Session = require "@rose/build/Session"
const Command = require "@rose/cli/Command"
const assertWorkspace = require "@rose/workspace/assertWorkspace"
const assertWorkspaceMember = require "@rose/workspace/assertWorkspaceMember"

const dev = Command.new { help = "Starts a development session for the workspace member" }
dev.args:add("member", "positional", { help = "Workspace member to build", required = true })
dev.args:add("nopreinit", "flag", { help = "Whether to skip preInit steps" })

function dev.onRun()
	const workspace = assertWorkspace()
	const member = assertWorkspaceMember(workspace, dev.args:get "member" :: string)

	const sessionResult = Session.fromMember(workspace, member)
	const session = if sessionResult.success
		then sessionResult.value
		else error(`failed to instantiate session: {sessionResult.err}`)

	if not dev.args:has "nopreinit" then session:preInit() end

	session:init()
end

return dev

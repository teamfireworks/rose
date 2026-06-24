const Command = require "@rose/cli/Command"

const dev = Command.new { help = "Spins up a new development session" }
dev.args:add("member", "positional", { help = "Workspace member to build", required = true })
dev.args:add("profile", "option", { help = "Profile to use, this overrides environment variables if set" })
dev.args:add("fresh", "flag", { help = "Forces a fresh rebuild" })

function dev.onRun() end

return dev

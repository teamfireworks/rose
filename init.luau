--!nocheck
-- Temporary bootstrapper so we can use this inside WTH

const process = require "@std/process"
const path = require "@std/path"

const args = { ... }
args[1] = "rose/src"
table.insert(args, 1, "lute")
table.insert(args, 2, "run")
process.run(args, { cwd = path.format(process.cwd()), stdio = "inherit" })

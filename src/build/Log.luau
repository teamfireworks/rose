const richterm = require "@rose/batteries/richterm"
const tableext = require "@std/tableext"
const task = require "@std/task"

export type LogKind = "add" | "change" | "remove" | "warn"

export type LogMessage = {
	kind: LogKind,
	lines: { string },
	timestamp: number,
}

const LOG_STYLES: { [LogKind]: { formatter: richterm.Formatter, symbol: string } } = {
	add = { formatter = richterm.green, symbol = "+" },
	change = { formatter = richterm.cyan, symbol = "↻" },
	remove = { formatter = richterm.red, symbol = "-" },
	warn = { formatter = richterm.combine(richterm.yellow, richterm.bold), symbol = "!" },
}

const Log = {}
Log.__index = Log

export type Log = setmetatable<{ logs: { LogMessage }, onLog: (LogMessage) -> () }, typeof(Log)>

function Log.formatLog(message: LogMessage)
	const style = LOG_STYLES[message.kind]
	const timestamp = richterm.dim(os.date("%X", message.timestamp))
	const indent = `\n{timestamp}   `
	return timestamp
		.. " "
		.. style.formatter(style.symbol)
		.. " "
		.. table.concat(tableext.map(message.lines, style.formatter :: (string) -> string), indent)
end

function Log.defaultOnLog(message: LogMessage)
	print(Log.formatLog(message))
end

function Log.new(): Log
	return setmetatable({ logs = {}, onLog = Log.defaultOnLog }, Log)
end

function Log.push(self: Log, kind: LogKind, ...: string)
	const message = {
		kind = kind,
		lines = { ... },
		timestamp = os.time(),
	}
	table.insert(self.logs, message)
	task.spawn(self.onLog, message)
end

function Log.atAdd(self: Log, ...: string)
	self:push("add", ...)
end

function Log.atChange(self: Log, ...: string)
	self:push("change", ...)
end

function Log.atRemove(self: Log, ...: string)
	self:push("remove", ...)
end

function Log.atWarn(self: Log, ...: string)
	self:push("warn", ...)
end

return table.freeze(Log)

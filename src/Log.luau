const richterm = require "@rose/batteries/richterm"
const tableext = require "@std/tableext"

export type LogKind = "add" | "change" | "remove" | "info" | "warn" | "error"

export type LogMessage = {
	kind: LogKind,
	lines: { string },
	timestamp: number,
}

const LOG_STYLES: { [LogKind]: { formatter: richterm.Formatter, symbol: string } } = {
	add = { formatter = richterm.combine(richterm.dim, richterm.green), symbol = "+" },
	change = { formatter = richterm.combine(richterm.dim, richterm.cyan), symbol = "↻" },
	remove = { formatter = richterm.combine(richterm.dim, richterm.red), symbol = "-" },

	info = { formatter = richterm.white, symbol = "i" },
	warn = { formatter = richterm.combine(richterm.yellow, richterm.bold), symbol = "!" },
	error = { formatter = richterm.combine(richterm.red, richterm.bold), symbol = "X" },
}

const Log = {}
Log.__index = Log

export type Log = setmetatable<{ logs: { LogMessage }, outputLog: (LogMessage) -> () }, typeof(Log)>

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

function Log.defaultOutputLog(message: LogMessage)
	print(Log.formatLog(message))
end

function Log.new(): Log
	return setmetatable({ logs = {}, outputLog = Log.defaultOutputLog }, Log)
end

function Log.push(self: Log, kind: LogKind, ...: string)
	const message = {
		kind = kind,
		lines = { ... },
		timestamp = os.time(),
	}
	table.insert(self.logs, message)
	self.outputLog(message)
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

function Log.atInfo(self: Log, ...: string)
	self:push("info", ...)
end

function Log.atWarn(self: Log, ...: string)
	self:push("warn", ...)
end

function Log.atError(self: Log, ...: string)
	self:push("error", ...)
end

return table.freeze(Log)

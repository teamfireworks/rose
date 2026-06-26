const fs = require "@std/fs"
const types = require "@rose/sourcemap/types"

const Watcher = {}
Watcher.__index = Watcher

export type Watcher = setmetatable<{
	changes: { [string]: "added" | "changed" | "removed" },
	watchers: { [string]: typeof(fs.watch(...)) },
	previousIndices: types.Indices,
	currentIndices: types.Indices,
}, typeof(Watcher)>

function Watcher.new(): Watcher
	return setmetatable({
		changes = {},
		watchers = {},
		previousIndices = {},
		currentIndices = {},
	}, Watcher)
end

function Watcher.onChanged(self: Watcher, nextIndices: types.Indices)
	self.currentIndices = nextIndices

	for absolutePath in nextIndices do
		if not self.previousIndices[absolutePath] and not self.changes[absolutePath] then
			self.changes[absolutePath] = "added"

			local watcher = fs.watch(absolutePath)
			self.watchers[absolutePath] = watcher
		end
	end

	for absolutePath in self.previousIndices do
		if not nextIndices[absolutePath] and not self.changes[absolutePath] then
			self.changes[absolutePath] = "removed"
		end
	end

	self.previousIndices = nextIndices
end

function Watcher.checkFileWatchers(self: Watcher)
	for absolutePath, fileWatcher in self.watchers do
		local event = fileWatcher:next()
		if event then
			if event.change then self.changes[absolutePath] = "changed" end
		end
	end
end

function Watcher.destroy(self: Watcher)
	for _, handle in self.watchers do
		pcall(handle.close, handle)
	end
	table.clear(self.watchers)
end

return table.freeze(Watcher)

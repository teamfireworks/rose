local luteFs = require "@lute/fs"
local path = require "@std/path"

local function normalizeSlashes(str: string): string
	return (str:gsub("\\", "/"))
end

export type SourcemapIndices = { [string]: string }

export type WatcherState = {
	changes: { [string]: "added" | "changed" | "removed" },
	dirWatchers: { [string]: luteFs.WatchHandle },
	onChanged: (newIndices: SourcemapIndices) -> (),
}

local function watchSourcemap(): WatcherState
	local oldIndices: SourcemapIndices = {}
	local currentIndices: SourcemapIndices = {}
	local changes: { [string]: "added" | "changed" | "removed" } = {}
	local dirWatchers: { [string]: luteFs.WatchHandle } = {}

	local function onChanged(newIndices: SourcemapIndices)
		currentIndices = newIndices

		for absolutePath in newIndices do
			if not oldIndices[absolutePath] then
				changes[absolutePath] = "added"

				local dirPath = path.format(path.dirname(absolutePath))
				if not dirWatchers[dirPath] then
					dirWatchers[dirPath] = luteFs.watch(dirPath, function(filename, event)
						local changedPath = normalizeSlashes(dirPath .. "/" .. filename)
						if event.change and currentIndices[changedPath] then changes[changedPath] = "changed" end
					end)
				end
			end
		end

		for absolutePath in oldIndices do
			if not newIndices[absolutePath] and not changes[absolutePath] then changes[absolutePath] = "removed" end
		end

		oldIndices = newIndices
	end

	return {
		changes = changes,
		dirWatchers = dirWatchers,
		onChanged = onChanged,
	}
end

return watchSourcemap

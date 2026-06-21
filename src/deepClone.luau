const function deepCloneImpl<T>(tbl: T, seen: { [T]: T }): T
	local clone = {}
	assert(typeof(tbl) == "table", `deepClone only supports tables, you passed: {tbl}`)

	seen[tbl] = clone
	for k, v in tbl :: any do
		if typeof(v) == "table" then
			clone[k] = if seen[v] then seen[v] else deepCloneImpl(v, seen)
		else
			clone[k] = v
		end
	end

	return clone
end

const function deepClone<T>(tbl: T): T
	local cloneCache = {}

	return deepCloneImpl(tbl, cloneCache)
end

return deepClone

const result = require "@rose/batteries/result"

const function assertResult<T>(result: result.Result<T>): T
	return if result.success then result.value else error(result.err)
end

return assertResult

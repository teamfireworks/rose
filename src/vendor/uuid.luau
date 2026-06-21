--!native
-- https://gist.github.com/gaymeowing/7a3e22168b2d39573a5e7601c0d44f92

-- uuid
-- function for generating a uuid, based on https://gist.github.com/jrus/3197011

local uuid_format = "%x%x%x%x%x%x%x%x-%x%x%x%x-4%x%x%x-%x%x%x%x-%x%x%x%x%x%x%x%x%x%x%x%x"
local wrap_in_curly_braces_format = "{%*}"
local string_format = string.format
local random_seed = math.randomseed
local random = math.random
local y_hex = 0xB
local x_hex = 0xF
local x_min = 0
local y_min = 8

-- this is cursed, but its quite fast so...
local function uuid(wrap_in_curly_braces: boolean?): string
	random_seed(os.clock())
	local uuid = (
		string_format(
			uuid_format,
			random(x_min, x_hex),
			random(x_min, x_hex),
			random(x_min, x_hex),
			random(x_min, x_hex),
			random(x_min, x_hex),
			random(x_min, x_hex),
			random(x_min, x_hex),
			random(x_min, x_hex),
			random(x_min, x_hex),
			random(x_min, x_hex),
			random(x_min, x_hex),
			random(x_min, x_hex),
			random(x_min, x_hex),
			random(x_min, x_hex),
			random(x_min, x_hex),
			random(y_min, y_hex),
			random(x_min, x_hex),
			random(x_min, x_hex),
			random(x_min, x_hex),
			random(x_min, x_hex),
			random(x_min, x_hex),
			random(x_min, x_hex),
			random(x_min, x_hex),
			random(x_min, x_hex),
			random(x_min, x_hex),
			random(x_min, x_hex),
			random(x_min, x_hex),
			random(x_min, x_hex),
			random(x_min, x_hex),
			random(x_min, x_hex),
			random(x_min, x_hex)
		)
	)

	return if wrap_in_curly_braces then string_format(wrap_in_curly_braces_format, uuid) else uuid
end

return uuid

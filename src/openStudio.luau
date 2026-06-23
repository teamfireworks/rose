const process = require "@std/process"
const system = require "@std/system"

local function getSystemOpenCommand(): string
	return if system.os == "windows" then "explorer" elseif system.os == "Darwin" then "open" else "xdg-open"
end

local function formatEditPlaceUrl(placeId: number | string): string
	return `roblox-studio:1+task:EditPlace+placeId:{placeId}+universeId:0`
end

local function openStudio(placeId: number | string)
	process.run { getSystemOpenCommand(), formatEditPlaceUrl(placeId) }
end

return openStudio

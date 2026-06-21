const Command = require "@rose/cli/Command"
const assertWorkspace = require "@rose/workspace/assertWorkspace"
const process = require "@std/process"
const system = require "@std/system"

const ropen = Command.new { help = "Opens the given workspace member or  place ID in Roblox Studio" }
ropen.args:add("place", "positional", { help = "Place name or ID to open", required = true })

const function getSystemOpenCommand()
	return if system.os == "windows" then "explorer" elseif system.os == "Darwin" then "open" else "xdg-open"
end

const function openDeeplink(url: string)
	process.run { getSystemOpenCommand(), url }
end

const function formatEditPlaceUrl(placeId: number | string)
	return `roblox-studio:1+task:EditPlace+placeId:{placeId}+universeId:0`
end

function ropen.onRun()
	const place = ropen.args:get "place" :: string

	const placeId = tonumber(place)
	if placeId then return openDeeplink(formatEditPlaceUrl(placeId)) end

	const workspace = assertWorkspace()
	const member = workspace.dirToMembers[place] or error(`unknown workspace member named {place}`)
	const memberPlace = member.place or error(`workspace member {place} must be a rose.place`)
	const memberPlaceId = memberPlace.placeId or error(`workspace member {place} missing it's rose.place.placeId`)

	openDeeplink(formatEditPlaceUrl(memberPlaceId))
end

return ropen

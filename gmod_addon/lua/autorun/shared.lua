AddCSLuaFile()
resource.AddFile("materials/mute-icon.png")
if (CLIENT) then

	local drawMute = false
	local muteIcon = Material("materials/mute-icon.png")

	net.Receive("drawMute",function()
		drawMute = net.ReadBool()
	end)

	hook.Add( "HUDPaint", "ttt_discord_bot_HUDPaint", function()
		if (!drawMute) then return end
		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetMaterial(muteIcon)
		surface.DrawTexturedRect(0, 0, 128, 128)
	end )


	return
end
util.AddNetworkString("drawMute")

REMOTE_HOST = "http://discord_bot"
PORT = 37405
PREFIX = "[TTT Discord Bot] "
FILEPATH = "ttt_discord_bot.dat"
TRIES = 3

muted = {}

ids = {}
ids_raw = file.Read( FILEPATH, "DATA" )
if (ids_raw) then
	ids = util.JSONToTable(ids_raw)
end

function saveIDs()
	file.Write( FILEPATH, util.TableToJSON(ids))
end

function buildUrl(path)
    if PORT > 0 then
        return REMOTE_HOST .. ":" .. PORT .. path
    else
        return REMOTE_HOST .. path
    end
end

function postWithRetries(path, params, callback)
    url = buildUrl(path)
    print("Connecting to " .. url .. " with data " .. util.TableToJSON(params))
    http.Post(
        url,
        params,
        function(res, length, headers, statusCode)
            if statusCode == 200 then
                callback(util.JSONToTable(res))
            else
                print("Request to bot failed with status code " .. statusCode .. ": " .. res)
            end
        end,
        function(err)
            print(err)
        end
    )
end

function sendClientIconInfo(ply,mute)
	net.Start("drawMute")
	net.WriteBool(mute)
	net.Send(ply)
end

--[[
function isMuted(ply)
	for i,v in ipairs(muted) do
		if ply == v then return
			true
		end
	end
	return false
end]]
function isMuted(ply)
	return muted[ply]
end

function mute(ply)
	if (ids[ply:SteamID()]) then
		if (!isMuted(ply)) then
            postWithRetries("/mute", 
                { mute=tostring(true), id=ids[ply:SteamID()] },
                function(res)
                    if (res) then
                        --PrintTable(res)
                        if (res.success) then
                            ply:PrintMessage(HUD_PRINTCENTER,"You're muted in discord!")
                            sendClientIconInfo(ply,true)
                            muted[ply] = true
                        end
                        if (res.error) then
                            print(PREFIX.."Error: "..res.err)
                        end
                end
			end)
		end
	end
end

function unmute(ply)
	if (ply) then
		if (ids[ply:SteamID()]) then
			if (isMuted(ply)) then
                postWithRetries("/mute",
                    {mute=tostring(false),id=ids[ply:SteamID()]},
                    function(res)
                        if (res.success) then
                            ply:PrintMessage(HUD_PRINTCENTER,"You're no longer muted in discord!")
                            sendClientIconInfo(ply,false)
                            muted[ply] = false
                        end
                        if (res.error) then
                            print(PREFIX.."Error: "..res.err)
                        end
                    end
                )
			end
		end
	else
		for ply,val in pairs(muted) do
			if val then unmute(ply) end
		end
	end
end

hook.Add("PlayerSay", "ttt_discord_bot_PlayerSay", function(ply,msg)
    if (string.sub(msg,1,9) != '!discord ') then return end
    tag = string.sub(msg,10)
    tag_utf8 = ""

    for p, c in utf8.codes(tag) do
        tag_utf8 = string.Trim(tag_utf8.." "..c)
    end

	postWithRetries("/connect", {tag=tag_utf8}, function(res)
		if (res.answer == 0) then ply:PrintMessage(HUD_PRINTTALK,"No guilde member with a discord tag like '"..tag.."' found.") end
		if (res.answer == 1) then ply:PrintMessage(HUD_PRINTTALK,"Found more than one user with a discord tag like '"..tag.."'. Please specify!") end
		if (res.tag && res.id) then
			ply:PrintMessage(HUD_PRINTTALK,"Discord tag '"..res.tag.."' successfully boundet to SteamID '"..ply:SteamID().."'") --lie! actually the discord id is bound! ;)
			ids[ply:SteamID()] = res.id
			saveIDs()
		end
	end)
	return ""
end)

hook.Add("PlayerInitialSpawn", "ttt_discord_bot_PlayerInitialSpawn", function(ply)
	if (ids[ply:SteamID()]) then
		ply:PrintMessage(HUD_PRINTTALK,"You are connected with discord.")
	else
		ply:PrintMessage(HUD_PRINTTALK,"You are not connected with discord. Write '!discord DISCORDTAG' in the chat. E.g. '!discord marcel.js#4402'")
	end
end)

hook.Add("PlayerSpawn", "ttt_discord_bot_PlayerSpawn", function(ply)
  unmute(ply)
end)
hook.Add("PlayerDisconnected", "ttt_discord_bot_PlayerDisconnected", function(ply)
  unmute(ply)
end)
hook.Add("ShutDown","ttt_discord_bot_ShutDown", function()
  unmute()
end)
hook.Add("TTTEndRound", "ttt_discord_bot_TTTEndRound", function()
	timer.Simple(0.1,function() unmute() end)
end)
hook.Add("TTTBeginRound", "ttt_discord_bot_TTTBeginRound", function()--in case of round-restart via command
  unmute()
end)
hook.Add("PostPlayerDeath", "ttt_discord_bot_PostPlayerDeath", function(ply)
	if (GetRoundState() == 3) then
		mute(ply)
	end
end)

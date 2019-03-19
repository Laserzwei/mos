package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/entity/?.lua"

require ("utility")
require ("stringutility")
require ("faction")
require ("callable")

local config = require("config/mos")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace mOS
mOS = {}

local selectedSector = {}


local window
local selectSectorButton
local payButton
local transferToAllianceButton
local permissions = {AlliancePrivilege.ManageStations, AlliancePrivilege.FoundStations, AlliancePrivilege.ModifyCrafts, AlliancePrivilege.SpendResources}
local uiInitialized

function mOS.initialize()
    Entity():registerCallback("onSectorEntered", "onSectorEntered")
    if onClient() then
        Player():registerCallback("onSelectMapCoordinates", "onSelectMapCoordinates")
    end
end

--is the player that tries to interact also the owner? Are we close enough? then return true.
function mOS.interactionPossible(playerIndex)
    local player = Player(playerIndex)
    local astro = Entity()
    local craft = player.craft
    if craft == nil then return false end
    local dist = craft:getNearestDistance(astro)
    if dist < config.CALLDISTANCE then
        if checkEntityInteractionPermissions(astro, permissions) then
            return true
        end
    end
    return false
end

function mOS.initUI()
    local res = getResolution()
    local size = vec2(500, 300)

    local menu = ScriptUI()
    window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))

    window.showCloseButton = 1
    window.moveable = 1
    window.closeableWithEscape = true

    window:createLabel(vec2(50, 10), "You will need "..createMonetaryString(config.MONEY_PER_JUMP).."Cr to jump this Asteroid.", 15)
    --botton pay
    payButton = window:createButton(Rect(300, 200, 450, 30 + 200 ), "Pay & Move", "onPayPressed")
    payButton.maxTextSize = 15

    --button abort
    selectSectorButton = window:createButton(Rect(50, 200, 200, 30 + 200 ), "Select Sector", "onSectorSelectionPressed")
    selectSectorButton.maxTextSize = 15


    transferToAllianceButton = window:createButton(Rect(165, 150, 360, 30 + 150 ), "Transfer to Alliance", "onTransferOwnershipPressed")
    transferToAllianceButton.maxTextSize = 15

    if Player().allianceIndex then
        if Player().index == Entity().factionIndex then
            transferToAllianceButton.caption = "Transfer to Alliance "
        elseif Player().allianceIndex == Entity().factionIndex then
            transferToAllianceButton.caption = "Transfer Ownership to You "
        end
        transferToAllianceButton.active = true
        transferToAllianceButton.visible = true
    else
        transferToAllianceButton.active = false
        transferToAllianceButton.visible = false
    end

    menu:registerWindow(window, "Move Asteroid")
    uiInitialized = true
end

function mOS.onSelectMapCoordinates(x, y)
    if uiInitialized and not (x == 0 and y == 0) then
        selectedSector.x, selectedSector.y = x, y
        selectSectorButton.tooltip = "Selected Sector: ("..selectedSector.x..":"..selectedSector.y..")"
    end
end

-- changing position in target sector
function mOS.onSectorEntered()
    local x,y,z = math.random(-config.MAXDISPERSION, config.MAXDISPERSION), math.random(-config.MAXDISPERSION, config.MAXDISPERSION), math.random(-config.MAXDISPERSION, config.MAXDISPERSION)
    Entity().translation = dvec3(x,y,z)
end

function mOS.onSectorSelectionPressed()
    if onClient()then
        if selectedSector.x and selectedSector.y then
            GalaxyMap():show(selectedSector.x, selectedSector.y)
        else
            GalaxyMap():show(Sector():getCoordinates())
        end
    end
end

function mOS.onPayPressed()
    if onClient()then
        if selectedSector.x and selectedSector.y then
            invokeServerFunction("server_onPayPressed",Player().index, selectedSector)
            window.visible = false
        else
            displayChatMessage("No sector selected!", "Asteroid", 1)
        end
    end
end

function mOS.server_onPayPressed(playerIndex, pSelectedSector)
    if pSelectedSector.x == 0 and pSelectedSector.y == 0 then return end
    selectedSector = pSelectedSector
    local player = Player(playerIndex)
    local owner = checkEntityInteractionPermissions(Entity(), permissions)
    if owner then
        local canPay, msg, args = owner:canPay(config.MONEY_PER_JUMP)
        if canPay then
            local x,y = Sector():getCoordinates()
            if selectedSector.x and selectedSector.y then
                if not (selectedSector.x == x and selectedSector.y == y) then
                    if config.MAXTRANSFERRANGE >= distance2(vec2(x,y), vec2(selectedSector.x, selectedSector.y)) then
                        owner:pay("",config.MONEY_PER_JUMP)
                        Galaxy():transferEntity(Entity(), selectedSector.x, selectedSector.y, 1)
                        player:sendChatMessage("Asteroid", 0, [[Asteroid has been transferred to sector \s(%s:%s) !]], selectedSector.x, selectedSector.y)
                    else
                        player:sendChatMessage("Asteroid", 1, "Target Sector too far away!")
                    end
                else
                    player:sendChatMessage("Asteroid", 1, "Asteroid is already in sector ("..x..":"..y..") !")
                end
            else
                player:sendChatMessage("Asteroid", 1, "No sector selected!")
            end
        else
            player:sendChatMessage("Asteroid", 1, msg,unpack(args))
            return
        end
    else
        return
    end
end
callable(mOS, "server_onPayPressed")

function mOS.onTransferOwnershipPressed()
    invokeServerFunction("server_onTransferOwnershipPressed")
    if Player().index == Entity().factionIndex then
        transferToAllianceButton.caption = "Transfer Ownership to You "
    elseif Player().allianceIndex == Entity().factionIndex then
        transferToAllianceButton.caption = "Transfer to Alliance "
    end
    window.visible = false
end

function mOS.server_onTransferOwnershipPressed()
    if Player(callingPlayer).allianceIndex == Entity().factionIndex then
        printlog("transferred Asteroid ".. Entity().index.value .. " to Player" ..Player(callingPlayer).name)
        Entity().factionIndex = callingPlayer
    else
        printlog("transferred Asteroid ".. Entity().index.value .. " to Alliance " ..Alliance(Player(callingPlayer).allianceIndex).name)
        Entity().factionIndex = Player(callingPlayer).allianceIndex
    end
end
callable(mOS, "server_onTransferOwnershipPressed")

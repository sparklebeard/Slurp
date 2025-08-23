-- Slurp.lua
local addonName = ...
local Slurp = CreateFrame("Frame", "SlurpFrame")

-- Only register relevant events
Slurp:RegisterEvent("CHAT_MSG_LOOT")

-- Data storage
Slurp.tally = {}

-- Configuration
local suppressOwnServerName = true -- If true, the player's server name will be hidden in the ledger.
local applyCauldronItemFiltering = true -- If true, will only record cauldron items.
local recordAnyFleetingItems = false -- If true, will record all fleeting items even if cauldron filtering is active.

-- Localization Headaches
local FLEETING_ITEM_KEYWORD = "Fleeting" -- The string to identify fleeting items
local PLAYER_NAME_YOU = "You" -- The string used in loot messages to refer to the player running the addon

-- Cauldron item IDs (example, replace with actual IDs)
Slurp.cauldronItems = {
    [212725] = "Fleeting Flask of Tempered Aggression",
    [212727] = "Fleeting Flask of Tempered Aggression",
    [212728] = "Fleeting Flask of Tempered Aggression",
    [212729] = "Fleeting Flask of Tempered Swiftness",
    [212730] = "Fleeting Flask of Tempered Swiftness",
    [212731] = "Fleeting Flask of Tempered Swiftness",
    [212732] = "Fleeting Flask of Tempered Versatility",
    [212733] = "Fleeting Flask of Tempered Versatility",
    [212734] = "Fleeting Flask of Tempered Versatility",
    [212735] = "Fleeting Flask of Tempered Mastery",
    [212736] = "Fleeting Flask of Tempered Mastery",
    [212738] = "Fleeting Flask of Tempered Mastery",
    [212739] = "Fleeting Flask of Alchemical Chaos",
    [212740] = "Fleeting Flask of Alchemical Chaos",
    [212741] = "Fleeting Flask of Alchemical Chaos",
    [212745] = "Fleeting Flask of Saving Graces",
    [212746] = "Fleeting Flask of Saving Graces",
    [212747] = "Fleeting Flask of Saving Graces",
    [212942] = "Fleeting Algari Healing Potion",
    [212943] = "Fleeting Algari Healing Potion",
    [212944] = "Fleeting Algari Healing Potion",
    [212945] = "Fleeting Algari Mana Potion",
    [212946] = "Fleeting Algari Mana Potion",
    [212947] = "Fleeting Algari Mana Potion",
    [212948] = "Fleeting Cavedweller's Delight",
    [212949] = "Fleeting Cavedweller's Delight",
    [212950] = "Fleeting Cavedweller's Delight",
    [212951] = "Fleeting Slumbering Soul Serum",
    [212952] = "Fleeting Slumbering Soul Serum",
    [212953] = "Fleeting Slumbering Soul Serum",
    [212954] = "Fleeting Draught of Silent Footfalls",
    [212955] = "Fleeting Draught of Silent Footfalls",
    [212956] = "Fleeting Draught of Silent Footfalls",
    [212957] = "Fleeting Draught of Shocking Revelations",
    [212958] = "Fleeting Draught of Shocking Revelations",
    [212959] = "Fleeting Draught of Shocking Revelations",
    [212960] = "Fleeting Grotesque Vial",
    [212961] = "Fleeting Grotesque Vial",
    [212962] = "Fleeting Grotesque Vial",
    [212963] = "Fleeting Potion of Unwavering Focus",
    [212964] = "Fleeting Potion of Unwavering Focus",
    [212965] = "Fleeting Potion of Unwavering Focus",
    [212966] = "Fleeting Frontline Potion",
    [212967] = "Fleeting Frontline Potion",
    [212968] = "Fleeting Frontline Potion",
    [212969] = "Fleeting Tempered Potion",
    [212970] = "Fleeting Tempered Potion",
    [212971] = "Fleeting Tempered Potion",
    [212972] = "Fleeting Potion of the Reborn Cheetah",
    [212973] = "Fleeting Potion of the Reborn Cheetah",
    [212974] = "Fleeting Potion of the Reborn Cheetah",
    [244849] = "Fleeting Invigorating Healing Potion",
}
local emitDebugMessages = true
function Slurp.DebugPrint(msg)
    if not emitDebugMessages or not msg then return end
    print("SlurpDebug: " .. msg)
end

-- UI stub
function Slurp:CreateWindow()
    if self.window then return end
    local f = CreateFrame("Frame", "SlurpWindow", UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(600, 400)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:SetUserPlaced(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f.title = f:CreateFontString(nil, "OVERLAY")
    f.title:SetFontObject("GameFontHighlight")
    f.title:SetPoint("LEFT", f.TitleBg, "LEFT", 5, 0)
    f.title:SetText("Slurp Cauldron Usage")

    -- Reset Button
    f.resetBtn = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
    f.resetBtn:SetPoint("BOTTOMLEFT", 10, 10)
    f.resetBtn:SetSize(80, 25)
    f.resetBtn:SetText("Reset")
    f.resetBtn:SetScript("OnClick", function()
        Slurp.tally = {}
        Slurp:UpdateWindow()
    end)

    -- Close Button
    f.closeBtn = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
    f.closeBtn:SetPoint("BOTTOMRIGHT", -10, 10)
    f.closeBtn:SetSize(80, 25)
    f.closeBtn:SetText("Close")
    f.closeBtn:SetScript("OnClick", function()
        f:Hide()
    end)

    -- Usage List
    f.scrollFrame = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    f.scrollFrame:SetPoint("TOPLEFT", 10, -40)
    f.scrollFrame:SetPoint("BOTTOMRIGHT", -30, 50)
    f.content = CreateFrame("Frame", nil, f.scrollFrame)
    f.content:SetSize(1, 1)
    f.scrollFrame:SetScrollChild(f.content)

    self.window = f
    self:UpdateWindow()
end

function Slurp:UpdateWindow()
    if not self.window then return end
    local content = self.window.content

    -- Create or reuse FontStrings
    Slurp.fontStrings = Slurp.fontStrings or {}

    -- Hide all FontStrings first
    for _, fs in ipairs(Slurp.fontStrings) do
        fs:Hide()
    end

    local y = -5
    local idx = 1
    for user, items in pairs(self.tally) do
        for itemID, count in pairs(items) do
            local name = self.cauldronItems[itemID] or ("Item "..itemID)
            local fs = Slurp.fontStrings[idx]
            if not fs then
                fs = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                Slurp.fontStrings[idx] = fs
            end
            fs:SetPoint("TOPLEFT", 10, y)
            fs:SetText(user .. ": " .. name .. " x" .. count)
            fs:Show()
            y = y - 20
            idx = idx + 1
        end
    end
end

function Slurp:ShowWindow()
    self:CreateWindow()
    self.window:Show()
    self:UpdateWindow()
end

-- Slash command
SLASH_SLURP1 = "/slurp"
SlashCmdList["SLURP"] = function(msg)
    if msg:lower() == "show" or msg:lower() == "open" then
        Slurp:ShowWindow()
    elseif msg:lower() == "reset" then
        Slurp.tally = {}
        Slurp:UpdateWindow()
    elseif msg:lower() == "hide" then
        Slurp:HideWindow()
    elseif msg:lower() == "debug" then
        emitDebugMessages = not emitDebugMessages
        print("SlurpDebug is now " .. (emitDebugMessages and "enabled" or "disabled"))
    elseif msg:lower() == "all" then
        applyCauldronItemFiltering = not applyCauldronItemFiltering
        print("Slurp will now record " .. (applyCauldronItemFiltering and "only cauldron items." or "all items."))
    else
        print("Slurp commands:")
        print("/slurp show - Show the Slurp window")
        print("/slurp hide - Hide the Slurp window")
        print("/slurp reset - Reset all recorded data")
        print("/slurp debug - Toggle debug messages")
        print("/slurp all - Toggle recording all items vs only cauldron items")
    end
end

-- Event handler stub
Slurp:SetScript("OnEvent", function(self, event, ...)
    if event == "CHAT_MSG_LOOT" then
        local msg, user = ...
        Slurp:ParseMessage(msg, user)
    end
end)

-- Message parsing stub
function Slurp:ParseMessage(msg, user)
    -- Example loot message: "Sparklebeard-Stormrage creates: [Fleeting Flask of Tempered Aggression]."
    local player, itemName = msg:match("^(%a[%a%-]*) creates*: (.-)%.$")
    if not player or not itemName then 
        -- maybe it's potions in a stack, so try with the x5 suffix
        -- Example loot message: "Sparklebeard-Stormrage creates: [Fleeting Tempered Potion of Whatever]x5."
        player, itemName = msg:match("^(%a[%a%-]*) creates*: (.-)x%d%.$")
        if not player or not itemName then return end
    end

    -- Get the item ID
    local itemID = self:GetItemIDFromLink(itemName)
    self.DebugPrint(itemID)
    if not itemID then return end

    -- Apply filtering for cauldron items. Restrict to items in the cauldronItems dictionary, or "Fleeting" items if enabled.
    if applyCauldronItemFiltering then
        local isCauldronItem = self.cauldronItems[itemID]
        local isFleetingItem = recordAnyFleetingItems and itemName:find(FLEETING_ITEM_KEYWORD) ~= nil
        if not isFleetingItem and not isCauldronItem then return end
    end

    if player == PLAYER_NAME_YOU then
        if suppressOwnServerName then
            -- remove the "-ServerName" from the name
            local nameOnly = user:match("^[^%-]+")
            if not nameOnly then 
                nameOnly = user
            end
            player = nameOnly
        else
            player = user
        end
    end

    self.tally[player] = self.tally[player] or {}
    self.tally[player][itemName] = (self.tally[player][itemName] or 0) + 1
    self:UpdateWindow()
end

-- Extract item ID from an item link
function Slurp:GetItemIDFromLink(link)
    if type(link) ~= "string" then return nil end
    local itemID = link:match("item:(%d+)")
    return tonumber(itemID)
end

-- Extract item name from an item link
function Slurp:GetItemNameFromLink(link)
    if type(link) ~= "string" then return nil end
    local name = link:match("|h%[(.-)%]|h")
    return name
end

-- Check if a string is an item link
function Slurp:IsItemLink(str)
    return type(str) == "string" and str:find("|Hitem:") ~= nil
end

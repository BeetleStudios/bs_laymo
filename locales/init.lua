local function deepGet(tbl, key)
    if type(tbl) ~= "table" or type(key) ~= "string" then
        return nil
    end

    local node = tbl
    for part in key:gmatch("[^%.]+") do
        if type(node) ~= "table" then
            return nil
        end
        node = node[part]
        if node == nil then
            return nil
        end
    end

    return node
end

local function loadLocale(localeCode)
    local resourceName = GetCurrentResourceName()
    local relPath = ("locales/%s.lua"):format(localeCode)
    local content = LoadResourceFile(resourceName, relPath)
    if type(content) ~= "string" or content == "" then
        return nil, ("missing or empty %s"):format(relPath)
    end

    local chunk, err = load(content, ("@@%s/%s"):format(resourceName, relPath))
    if not chunk then
        return nil, err
    end

    local ok, data = pcall(chunk)
    if not ok or type(data) ~= "table" then
        return nil, data
    end

    return data
end

local localeCode = tostring((Config and Config.Locale) or "EN"):upper()
local localeData, loadErr = loadLocale(localeCode)
if not localeData then
    print(("[Laymo] Locale '%s' failed to load (%s), falling back to EN"):format(localeCode, tostring(loadErr)))
    localeCode = "EN"
    localeData = loadLocale("EN") or {}
end

Lang = localeData
LangCode = localeCode
_G.Lang = Lang
_G.LangCode = LangCode

function L(key, ...)
    local raw = deepGet(Lang, key)
    if type(raw) ~= "string" then
        return key
    end

    if select("#", ...) > 0 then
        local ok, formatted = pcall(string.format, raw, ...)
        if ok then
            return formatted
        end
    end

    return raw
end

_G.L = L

local json = require("json")
local settings_store = {}

local filename = "settings.json"

local function normalize_language(language)
    if type(language) ~= "string" then
        return nil
    end

    language = language:lower():match("^([a-z][a-z])")
    if language == "en" or language == "ru" then
        return language
    end
    return nil
end

local function system_language()
    if not love.system.getPreferredLocales then
        return nil
    end

    local ok, locales = pcall(love.system.getPreferredLocales)
    if not ok or type(locales) ~= "table" then
        return nil
    end

    for _, locale in ipairs(locales) do
        local language = normalize_language(locale)
        if language then
            return language
        end
    end
    return nil
end

function settings_store.load()
    local settings = {}
    local serialized = love.filesystem.read(filename)

    if serialized then
        local ok, decoded = pcall(json.decode, serialized)
        if ok and type(decoded) == "table" then
            settings = decoded
        end
    end

    settings.language = normalize_language(os.getenv("SARCOPHAGUS_LANGUAGE"))
        or normalize_language(settings.language)
        or system_language()
        or "en"

    return settings
end

function settings_store.save(settings)
    local language = normalize_language(settings and settings.language)
    assert(language, "cannot save unsupported language")
    return love.filesystem.write(filename, json.encode({ language = language }))
end

return settings_store

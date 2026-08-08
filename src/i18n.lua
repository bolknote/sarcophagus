local i18n = {}

local languages = { "en", "ru" }
local supported = { en = true, ru = true }

local function deep_copy(value, seen)
    if type(value) ~= "table" then
        return value
    end

    seen = seen or {}
    if seen[value] then
        return seen[value]
    end

    local copy = {}
    seen[value] = copy
    for key, child in pairs(value) do
        copy[deep_copy(key, seen)] = deep_copy(child, seen)
    end
    return setmetatable(copy, getmetatable(value))
end

local function merge(base, overlay)
    for key, value in pairs(overlay) do
        if type(value) == "table" and type(base[key]) == "table" then
            merge(base[key], value)
        else
            base[key] = deep_copy(value)
        end
    end
end

function i18n.is_supported(language)
    return supported[language] == true
end

function i18n.load(language)
    assert(i18n.is_supported(language), "unsupported language: " .. tostring(language))

    local messages = deep_copy(require("src.locales.en"))
    if language ~= "en" then
        merge(messages, require("src.locales." .. language))
    end
    return messages
end

function i18n.activate(language)
    assert(i18n.is_supported(language), "unsupported language: " .. tostring(language))
    LANGUAGE = language
    msg = i18n.load(language)
    return msg
end

function i18n.next_language(language)
    for index, candidate in ipairs(languages) do
        if candidate == language then
            return languages[index % #languages + 1]
        end
    end
    return languages[1]
end

function i18n.format_datetime(messages, timestamp)
    local date = os.date("*t", timestamp)
    local localized = assert(messages.datetime, "datetime locale is missing")
    local replacements = {
        localized.weekdays[date.wday],
        date.day,
        localized.months[date.month],
        date.year,
        string.format("%02d", date.hour),
        string.format("%02d", date.min),
        string.format("%02d", date.sec),
    }

    return (localized.save:gsub("_(%d+)_", function(index)
        return tostring(replacements[tonumber(index)])
    end))
end

function i18n.apply_content_names(messages, items, stones, runtime_font)
    local text = runtime_font and love.graphics.newText(runtime_font, "") or nil

    for index, translation in ipairs(messages.item or {}) do
        if items[index] and translation.name then
            items[index].name = translation.name
            if text then
                text:setf(translation.name, 1000, "left")
                items[index].w = text:getWidth() / 8
            end
        end
    end

    for index, translation in ipairs(messages.stone or {}) do
        if stones[index] and translation.name then
            stones[index].name = translation.name
            if text then
                text:setf(translation.name, 1000, "left")
                stones[index].w = text:getWidth() / 8
            end
        end
    end
end

return i18n

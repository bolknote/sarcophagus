I18N = require("src.i18n")
SETTINGS_STORE = require("src.settings")
APP_SETTINGS = SETTINGS_STORE.load()

function language_set(language, persist)
	local messages = I18N.activate(language)
	APP_SETTINGS.language = language

	if persist then
		local saved, save_error = SETTINGS_STORE.save(APP_SETTINGS)
		if not saved then
			LANGUAGE_SETTINGS_ERROR = save_error
		end
	end

	if item and stone and font then
		I18N.apply_content_names(messages, item, stone, font)
	end

	return messages
end

function language_next()
	return language_set(I18N.next_language(LANGUAGE), true)
end

return language_set(APP_SETTINGS.language, false)

local build_mode = {}

local valid_modes = {
    development = true,
    release = true,
}

function build_mode.detect()
    local selected = os.getenv("SARCOPHAGUS_BUILD_MODE")

    if not selected then
        local ok, release_config = pcall(require, "release_config")
        if ok and type(release_config) == "table" then
            selected = release_config.build_mode
        end
    end

    selected = selected or "development"
    assert(valid_modes[selected], "invalid Sarcophagus build mode: " .. tostring(selected))
    return selected
end

return build_mode

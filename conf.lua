function love.conf(t)
    t.version = "11.5"
    t.identity = "sarcophagus"
    t.window.width = 1280
    t.window.height = 720
    t.window.resizable = true
    t.window.vsync = 1
    t.window.highdpi = true
    t.window.usedpiscale = true
    t.modules.joystick = true
    t.modules.physics = false
end

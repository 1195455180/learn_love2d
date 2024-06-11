require "engine/object"
require "engine/string_packer"
require "engine/controller"
require "functions/misc_functions"
require "game"
require "globals"
require "functions/button_callbacks"

function love.load()
    G:start_up()

end

function love.update(dt)
    
end

function love.draw()
    love.graphics.print("round start", 100, 300)
end
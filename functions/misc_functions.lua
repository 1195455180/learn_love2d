

function boot_timer(_label, _next, progress)
    progress = progress or 0
    G.LOADING = G.LOADING or {
        font = love.graphics.setNewFont("resources/fonts/m6x11plus.ttf", 20),
        love.graphics.dis
    }
    local realw, realh = love.window.getMode()
    love.graphics.setCanvas()
    love.graphics.push()
    love.graphics.setShader()
    love.graphics.clear(0,0,0,1)
    love.graphics.setColor(0.6, 0.8, 0.9,1)
    if progress > 0 then love.graphics.rectangle('fill', realw/2 - 150, realh/2 - 15, progress*300, 30, 5) end
    love.graphics.setColor(1, 1, 1,1)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle('line', realw/2 - 150, realh/2 - 15, 300, 30, 5)
    if G.F_VERBOSE and not _RELEASE_MODE then love.graphics.print("LOADING: ".._next, realw/2 - 150, realh/2 +40) end
    love.graphics.pop()
    love.graphics.present()
  
    G.ARGS.bt = G.ARGS.bt or love.timer.getTime()
    G.ARGS.bt = love.timer.getTime()
end



function HEX(hex)
    if #hex <= 6 then hex = hex.."FF" end
    local _,_,r,g,b,a = hex:find('(%x%x)(%x%x)(%x%x)(%x%x)')
    local color = {tonumber(r,16)/255,tonumber(g,16)/255,tonumber(b,16)/255,tonumber(a,16)/255 or 255}
    return color
end


function copy_table(O)
    local O_type = type(O)
    local copy
    if O_type == 'table' then
        copy = {}
        for k, v in next, O, nil do
            copy[copy_table(k)] = copy_table(v)
        end
        setmetatable(copy, copy_table(getmetatable(O)))
    else
        copy = O
    end
    return copy
  end
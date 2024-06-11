--Applies all window changes, including updates to the screenmode, selected display, resolution and vsync.\
--These changes are all defined in the G.SETTINGS.QUEUED_CHANGE table. Any unchanged settings use the previous value
G.FUNCS.apply_window_changes = function(_initial)
    --Set the screenmode setting from Windowed, Fullscreen or Borderless
    G.SETTINGS.WINDOW.screenmode = (G.SETTINGS.QUEUED_CHANGE and G.SETTINGS.QUEUED_CHANGE.screenmode) or G.SETTINGS.WINDOW.screenmode or 'Windowed'
  
    --Set the monitor the window should be rendered to
    G.SETTINGS.WINDOW.selected_display = (G.SETTINGS.QUEUED_CHANGE and G.SETTINGS.QUEUED_CHANGE.selected_display) or G.SETTINGS.WINDOW.selected_display or 1
  
    --Set the screen resolution
    G.SETTINGS.WINDOW.DISPLAYS[G.SETTINGS.WINDOW.selected_display].screen_res = {
      w = (G.SETTINGS.QUEUED_CHANGE and G.SETTINGS.QUEUED_CHANGE.screenres and G.SETTINGS.QUEUED_CHANGE.screenres.w) or (G.SETTINGS.screen_res and G.SETTINGS.screen_res.w) or love.graphics.getWidth( ),
      h = (G.SETTINGS.QUEUED_CHANGE and G.SETTINGS.QUEUED_CHANGE.screenres and G.SETTINGS.QUEUED_CHANGE.screenres.h) or (G.SETTINGS.screen_res and G.SETTINGS.screen_res.h) or love.graphics.getHeight( )
    }
  
    --Set the vsync value, 0 is off 1 is on
    G.SETTINGS.WINDOW.vsync = (G.SETTINGS.QUEUED_CHANGE and G.SETTINGS.QUEUED_CHANGE.vsync) or G.SETTINGS.WINDOW.vsync or 1
  
    love.window.updateMode(
      (G.SETTINGS.QUEUED_CHANGE and G.SETTINGS.QUEUED_CHANGE.screenmode == 'Windowed') and love.graphics.getWidth()*0.8 or G.SETTINGS.WINDOW.DISPLAYS[G.SETTINGS.WINDOW.selected_display].screen_res.w,
      (G.SETTINGS.QUEUED_CHANGE and G.SETTINGS.QUEUED_CHANGE.screenmode == 'Windowed') and love.graphics.getHeight()*0.8 or G.SETTINGS.WINDOW.DISPLAYS[G.SETTINGS.WINDOW.selected_display].screen_res.h,
      {fullscreen = G.SETTINGS.WINDOW.screenmode ~= 'Windowed',
      fullscreentype = (G.SETTINGS.WINDOW.screenmode == 'Borderless' and 'desktop') or (G.SETTINGS.WINDOW.screenmode == 'Fullscreen' and 'exclusive') or nil,
      vsync = G.SETTINGS.WINDOW.vsync,
      resizable = true,
      display = G.SETTINGS.WINDOW.selected_display,
      highdpi = true
      })
    G.SETTINGS.QUEUED_CHANGE = {}
    if _initial ~= true then
      love.resize(love.graphics.getWidth(),love.graphics.getHeight())
      G:save_settings()
    end
    if G.OVERLAY_MENU then
      local tab_but = G.OVERLAY_MENU:get_UIE_by_ID('tab_but_Video')
      G.FUNCS.change_tab(tab_but)
    end
  end
  
Game = Object:extend()

function Game:init()
    G = self

    self:set_globals()
end

function Game:start_up()
    -- body
    local settings_ver = nil

    self.SETTINGS.version = settings_ver or G.VERSION
    self.SETTINGS.paused = nil

    local new_colour_proto = self.C["SO_"..(self.SETTINGS.colourblind_option and 2 or 1)]
    self.C.SUITS.Hearts = new_colour_proto.Hearts
    self.C.SUITS.Diamonds = new_colour_proto.Diamonds
    self.C.SUITS.Spades = new_colour_proto.Spades
    self.C.SUITS.Clubs = new_colour_proto.Clubs
    -- 加载配置
    boot_timer('start', 'settings', 0.1)

    if self.SETTINGS.GRAPHICS.texture_scaling then
        self.SETTINGS.GRAPHICS.texture_scaling = self.SETTINGS.GRAPHICS.texture_scaling > 1 and 2 or 1
    end

    if self.SETTINGS.DEMO and not self.F_CTA then
        self.SETTINGS.DEMO = {
            total_uptime = 0, -- 运行时间
            timed_CTA_shown = true,
            win_CTA_shown = true,
            quit_CTA_shown = true
        }
    end

    -- 声音table
    SOURCES = {}
    local sound_files = love.filesystem.getDirectoryItems("resources/sounds")

    for _,file_name in ipairs(sound_files) do
        local extension = string.sub(file_name, 1, -5)
        if extension == ".ogg" then
            local sound_code = string.sub(file_name, 1, -5)
            SOURCES[sound_code] = {}    
        end
    end


    self.SETTINGS.language = self.SETTINGS.language or "en-us"
    boot_timer("setting", "windows init", 0.2)
    self:init_window()

    if G.F_SOUND_THREAD then
        boot_timer('window init', 'soudmanager2')
        -- 调用声音管理器以准备线程播放声音
        self.SOUND_MANAGER = {
            thread = love.thread.newThread('engine/sound_manager.lua'),
            channel = love.thread.getChannel('sound_request'),
            load_channel = love.thread.getChannel('load_channel')
        }
        self.SOUND_MANAGER.thread:start(1)

        local sound_loaded, prev_file = false, 'none'
        while not sound_loaded and false do
            -- 监听通道是否有请求
            local request = self.SOUND_MANAGER.load_channel:pop()
            if request then
                --If the request is for an update to the music track, handle it here
                if request == 'finished' then
                    sound_loaded = true
                else
                    boot_timer(request, prev_file)
                    prev_file = request
                end
            end
            love.timer.sleep(0.001)
        end

        boot_timer('soundmanager2', 'savemanager',0.22)
    end
    
    boot_timer('window init', 'savemanager')

    -- 调用存储管理器以等待任何存储请求
    G.SAVE_MANAGER = {
        thread = love.thread.newThread('engine/save_manager.lua'),
        channel = love.thread.getChannel('save_reqeust')
    }
    G.SAVE_MANAGER.thread:start(2)
    boot_timer('savemanager', 'shaders', 0.4)

    -- 加载 http 管理
    G.HTTP_MANAGER = {
        thread = love.thread.newThread('engine/http_manager.lua'),
        out_channel = love.thread.getChannel('http_request'),
        in_channel = love.thread.getChannel('http_response')
    }
    if G.F_HTTP_SCORES then
        G.HTTP_MANAGER.thread:start()
    end

    -- 从资源加载所有着色器
    self.SHADERS = {}
    local shader_files = love.filesystem.getDirectoryItems("resources/shaders")
    for k, filename in ipairs(shader_files) do
        local extension = string.sub(filename, -3)
        if extension == '.fs' then
            local shader_name = string.sub(filename, 1, -4)
            self.SHADERS[shader_name] = love.graphics.newShader("resources/shaders/"..filename)
        end
    end

    boot_timer('shaders', 'controllers', 0.7)

    --Input handler/controller for game objects  加载手柄的
    self.CONTROLLER = Controller()
    love.joystick.loadGamepadMappings("resources/gamecontrollerdb.txt")
    if self.F_RUMBLE then 
        local joysticks = love.joystick.getJoysticks()
        if joysticks then 
            if joysticks[1] then 
                self.CONTROLLER:set_gamepad(joysticks[2] or joysticks[1])
            end
        end
    end
    boot_timer('controllers', 'localization',0.8)

    -- 纹理缩放
    if self.SETTINGS.GRAPHICS.texture_scaling then
        self.SETTINGS.GRAPHICS.texture_scaling = self.SETTINGS.GRAPHICS.texture_scaling > 1 and 2 or 1
    end

    self:load_profile(G.SETTINGS.profile or 1)

    -- 队列
    self.SETTINGS.QUEUED_CHANGE = {}
    self.SETTINGS.music_control = {desired_track = '', current_track = '', lerp = 1}









end


function Game:init_window(reset)
    -- body
    self.ROOM_PADDING_H = 0.7
    self.ROOM_PADDING_W = 1
    self.WINDOWTRANS = {
        x = 0, y = 0,
        w = self.TILE_W+2*self.ROOM_PADDING_W,
        h = self.TILE_H+2*self.ROOM_PADDING_H,
    }
    self.window_prev = {
        orig_scale = self.TILESCALE,
        w=self.WINDOWTRANS.w*self.TILESIZE*self.TILESCALE,
        h=self.WINDOWTRANS.h*self.TILESIZE*self.TILESCALE,
        orig_ratio = self.WINDOWTRANS.w*self.TILESIZE*self.TILESCALE/(self.WINDOWTRANS.h*self.TILESIZE*self.TILESCALE)
    }

    G.SETTINGS.QUEUED_CHANGE = G.SETTINGS.QUEUED_CHANGE or {}
    G.SETTINGS.QUEUED_CHANGE.screenmode = G.SETTINGS.WINDOW.screenmode

    G.FUNCS.apply_window_changes(true)
end





function Game:load_profile(_profile)
    if not G.PROFILES[_profile] then _profile = 1 end
    G.SETTINGS.profile = _profile
    
    --Load the settings file
    local info = get_compressed(_profile..'/profile.jkr')
    if info ~= nil then
        for k, v in pairs(STR_UNPACK(info)) do
            G.PROFILES[G.SETTINGS.profile][k] = v
        end
    end

    local temp_profile = {
        MEMORY = {
            deck = 'Red Deck',
            stake = 1,
        },
        stake = 1,
        
        high_scores = {
            hand = {label = 'Best Hand', amt = 0},
            furthest_round = {label = 'Highest Round', amt = 0},
            furthest_ante = {label = 'Highest Ante', amt = 0},
            most_money = {label = 'Most Money', amt = 0},
            boss_streak = {label = 'Most Bosses in a Row', amt = 0},
            collection = {label = 'Collection', amt = 0, tot = 1},
            win_streak = {label = 'Best Win Streak', amt = 0},
            current_streak = {label = '', amt = 0},
            poker_hand = {label = 'Most Played Hand', amt = 0}
        },
    
        career_stats = {
            c_round_interest_cap_streak = 0,
            c_dollars_earned = 0,
            c_shop_dollars_spent = 0,
            c_tarots_bought = 0,
            c_planets_bought = 0,
            c_playing_cards_bought = 0,
            c_vouchers_bought = 0,
            c_tarot_reading_used = 0,
            c_planetarium_used = 0,
            c_shop_rerolls = 0,
            c_cards_played = 0,
            c_cards_discarded = 0,
            c_losses = 0,
            c_wins = 0,
            c_rounds = 0,
            c_hands_played = 0,
            c_face_cards_played = 0,
            c_jokers_sold = 0,
            c_cards_sold = 0,
            c_single_hand_round_streak = 0,
        },
        progress = {

        },
        joker_usage = {},
        consumeable_usage = {},
        voucher_usage = {},
        hand_usage = {},
        deck_usage = {},
        deck_stakes = {},
        challenges_unlocked = nil,
        challenge_progress = {
            completed = {},
            unlocked = {}
        }
    }
    local recursive_init 
    recursive_init = function(t1, t2) 
        for k, v in pairs(t1) do
            if not t2[k] then 
                t2[k] = v
            elseif type(t2[k]) == 'table' and type(v) == 'table' then
                recursive_init(v, t2[k])
            end
        end
    end

    recursive_init(temp_profile, G.PROFILES[G.SETTINGS.profile])
end
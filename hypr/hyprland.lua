-- ============================================================================
-- Reescrita para a API Lua nativa do Hyprland (namespace hl.*), introduzida
-- na v0.55 (abril de 2026) em substituição ao dialecto declarativo "hyprlang".
-- Traduzido a partir de hyprland.conf (dialecto hyprlang, pré-0.55).
--
-- Referência oficial ................ https://wiki.hypr.land/Configuring/Start/
-- Exemplo oficial .................... https://github.com/hyprwm/Hyprland/blob/main/example/hyprland.lua
-- Anúncio da mudança (Vaxry, abr/2026) https://hypr.land/news/26_lua/
-- ============================================================================


------------------------------------------------------------------------------
-- MONITORES
-- https://wiki.hypr.land/Configuring/Basics/Monitors/
------------------------------------------------------------------------------
hl.monitor({ output = "eDP-1",    mode = "preferred", position = "auto", scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "auto", scale = "auto" })


------------------------------------------------------------------------------
-- PROGRAMAS PRINCIPAIS
------------------------------------------------------------------------------
local terminal = "kitty"
local menu     = "ulauncher"
local browser  = "firefox"

-- BUG-ORIGEM: $fileManager e $lockscreen eram referenciados em binds mais
-- abaixo no .conf original SEM nunca terem sido declarados como variável —
-- dois atalhos mortos, inertes desde sempre. Valores por omissão abaixo;
-- confirma-os e substitui pelos teus reais.
local fileManager = "thunar"    -- TODO: confirmar o gestor de ficheiros real
local lockscreen  = "hyprlock"  -- TODO: confirmar o comando de bloqueio real


------------------------------------------------------------------------------
-- AUTOSTART
-- https://wiki.hypr.land/Configuring/Basics/Autostart/
-- Nota: hl.exec_cmd() aqui dentro de hl.on(...) executa directamente — não
-- é um despachante de bind, não precisa de hl.dispatch().
------------------------------------------------------------------------------
hl.on("hyprland.start", function()
    hl.exec_cmd("avizo-service")
    hl.exec_cmd("waybar")
    hl.exec_cmd("swaybg -i ~/Pictures/Wallpapers/Desktop/Artwork/88.png -m fill")
    hl.exec_cmd("swaync")
    hl.exec_cmd("ulauncher --hide-window")
end)


------------------------------------------------------------------------------
-- VARIÁVEIS DE AMBIENTE
-- https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/
------------------------------------------------------------------------------
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "AppleCursor")
hl.env("HYPRCURSOR_THEME", "AppleCursor")
hl.env("GTK_THEME", "Adwaita:dark")
hl.env("WLR_NO_HARDWARE_CURSORS", "1")


------------------------------------------------------------------------------
-- ULAUNCHER — atalho, regra de janela e regra de camada (layer)
------------------------------------------------------------------------------
hl.bind("ALT + SPACE", hl.dsp.exec_cmd("ulauncher-toggle"))

-- BUG-ORIGEM: o .conf original definia isto como `windowrule{ ... }` com
-- sintaxe de chavetas e "match:class=" — sintaxe que nunca foi válida em
-- hyprlang, em nenhuma versão. Corrigido abaixo; semântica preservada.
hl.window_rule({
    name = "ulauncher-strip-fx",
    match = { class = "^ulauncher$" },
    no_blur = true,
    no_shadow = true,
    border_size = 0,
})

hl.layer_rule({
    name = "waybar-blur",
    match = { namespace = "waybar" },
    blur = true,
})

hl.layer_rule({
    name = "swaync-slide",
    match = { namespace = "swaync-control-center" },
    animation = "slide right",
})


------------------------------------------------------------------------------
-- APARÊNCIA — general / decoration / misc
-- https://wiki.hypr.land/Configuring/Basics/Variables/
------------------------------------------------------------------------------
hl.config({
    general = {
        gaps_in = 6,
        gaps_out = 0,
        border_size = 1,
        col = {
            active_border   = "rgba(0,0,0,1)",
            inactive_border = "rgba(0,0,0,1)",
        },
        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding = 10,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        shadow = {
            enabled = false,
            range = 13,
            render_power = 10,
            offset = { 6, 6 },
        },
        blur = {
            enabled = true,
            size = 12,
            passes = 2,
            vibrancy = 0.1696,
            new_optimizations = true,
            xray = false,
            contrast = 1.0,
            brightness = 1.0,
            noise = 0.01,
            special = false,
            popups = true,
        },
    },

    misc = {
        disable_hyprland_logo = true,
    },
})


------------------------------------------------------------------------------
-- CURVAS E ANIMAÇÕES
-- https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
------------------------------------------------------------------------------
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}   } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}   } }) -- definida, não referenciada — herdada assim do original
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}      } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1.0} } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}    } })

hl.config({ animations = { enabled = true } })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 2.94, bezier = "almostLinear", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 2.94, bezier = "almostLinear", style = "slide" })


------------------------------------------------------------------------------
-- ENTRADA — teclado, rato, touchpad, dispositivos
-- https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/
------------------------------------------------------------------------------
hl.config({
    input = {
        kb_layout   = "br",
        kb_variant  = "abnt2",
        kb_model    = "",
        kb_options  = "nodeadkeys",
        kb_rules    = "",
        follow_mouse = 1,
        sensitivity = 0,   -- -1.0 a 1.0; 0 = sem modificação
        touchpad = {
            natural_scroll = false,
        },
    },
})

-- BUG-ORIGEM: o bloco `device{}` original continha DUAS chaves `name` na
-- mesma tabela — a segunda pisava a primeira, silenciosamente. Cada
-- dispositivo recebe agora a sua própria invocação, sem ambiguidade.
hl.device({ name = "epic-mouse-v1", sensitivity = -0.5 })
hl.device({ name = "atml3000:00-03eb:2168-touchpad", sensitivity = 0.5 })


------------------------------------------------------------------------------
-- ATALHOS DE TECLADO
-- https://wiki.hypr.land/Configuring/Basics/Binds/
-- https://wiki.hypr.land/Configuring/Basics/Dispatchers/
------------------------------------------------------------------------------
local mainMod = "SUPER"

hl.bind(mainMod .. " + Return",     hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q",          hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + M",  hl.dsp.exit())
hl.bind(mainMod .. " + E",          hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + SPACE",      hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P",          hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + SHIFT + L",  hl.dsp.exec_cmd(lockscreen))

hl.bind(mainMod .. " + N",          hl.dsp.exec_cmd("swaync-client -t -sw"))
hl.bind(mainMod .. " + SHIFT + N",  hl.dsp.exec_cmd("swaync-client -d -swi"))

-- Foco direccional (equivalente a movefocus)
hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "up" }))

hl.bind(mainMod .. " + Tab", hl.dsp.window.cycle_next())

hl.bind(mainMod .. " + F",          hl.dsp.window.bring_to_top())
hl.bind(mainMod .. " + SHIFT + F",  hl.dsp.focus({ urgent_or_last = true })) -- aproxima focusCurrentOrLast

-- Espaços de trabalho 1–10 (0 mapeia ao décimo, tal como no original)
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Captura de ecrã (requer hyprshot)
hl.bind(mainMod .. " + s", hl.dsp.exec_cmd("hyprshot -m region"))


------------------------------------------------------------------------------
-- VOLUME E BRILHO
-- Consolidado numa única definição canónica por tecla.
------------------------------------------------------------------------------
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),        { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),       { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl set +10%"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 10%-"), { locked = true, repeating = true })


------------------------------------------------------------------------------
-- SUBMAPAS — redimensionar e mover com teclas vim
-- https://wiki.hypr.land/Configuring/Basics/Binds/#submaps
------------------------------------------------------------------------------
hl.bind("ALT + R", hl.dsp.submap("resize"))
hl.define_submap("resize", function()
    hl.bind("h", hl.dsp.window.resize({ x = -50, y = 0,   relative = true }), { repeating = true })
    hl.bind("l", hl.dsp.window.resize({ x = 50,  y = 0,   relative = true }), { repeating = true })
    hl.bind("j", hl.dsp.window.resize({ x = 0,   y = 50,  relative = true }), { repeating = true })
    hl.bind("k", hl.dsp.window.resize({ x = 0,   y = -50, relative = true }), { repeating = true })
    hl.bind("escape", hl.dsp.submap("reset"))
end)

hl.bind("ALT + M", hl.dsp.submap("move"))
hl.define_submap("move", function()
    -- Ponto em aberto à data desta escrita: assume-se hl.dsp.window.move()
    -- aceitando {x, y, relative}, por analogia estrutural com
    -- hl.dsp.window.resize() (essa sim, confirmada na documentação oficial).
    -- Verifica contra https://wiki.hypr.land/Configuring/Basics/Dispatchers/
    -- antes de confiares cegamente — a API Lua ainda está em sedimentação.
    hl.bind("h", hl.dsp.window.move({ x = -50, y = 0,   relative = true }), { repeating = true })
    hl.bind("l", hl.dsp.window.move({ x = 50,  y = 0,   relative = true }), { repeating = true })
    hl.bind("j", hl.dsp.window.move({ x = 0,   y = 50,  relative = true }), { repeating = true })
    hl.bind("k", hl.dsp.window.move({ x = 0,   y = -50, relative = true }), { repeating = true })
    hl.bind("escape", hl.dsp.submap("reset"))
end)

-- Material 3 Expressive Easing Curves
hl.curve("m3EmphasizedDecel", { type = "bezier", points = { {0.05, 0.7}, {0.1, 1} } })    -- Snappy in, slow settle (Opening/Entering)
hl.curve("m3EmphasizedAccel", { type = "bezier", points = { {0.3, 0}, {0.8, 0.15} } })    -- Slow start, fast exit (Closing/Exiting)

-- Material 3 Standard Easing Curves
hl.curve("m3Standard",        { type = "bezier", points = { {0.2, 0}, {0, 1} } })         -- Standard balanced curve (General Utility)
hl.curve("m3StandardDecel",   { type = "bezier", points = { {0, 0}, {0, 1} } })           -- Standard entering (Fades In)
hl.curve("m3StandardAccel",   { type = "bezier", points = { {0.3, 0}, {1, 1} } })         -- Standard exiting (Fades Out)

-- Animations mapped to Material 3 tokens
hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true,  speed = 5.39, bezier = "m3Standard" })

-- Windows & Popins (Uses Emphasized for maximum expression)
hl.animation({ leaf = "windows",       enabled = true,  speed = 4.79, bezier = "m3EmphasizedDecel" }) 
hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4.1,  bezier = "m3EmphasizedDecel", style = "popin 89%" })
hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 1.49, bezier = "m3EmphasizedAccel", style = "popin 92%" })

-- Fades (Uses Standard for simple utility transitions)
hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "m3StandardDecel" })
hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "m3StandardAccel" })
hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "m3Standard" })

-- Layers (Like menus, app launchers)
hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "m3Standard" })
hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "m3EmphasizedDecel", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.5,  bezier = "m3EmphasizedAccel", style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "m3StandardDecel" })
hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.39, bezier = "m3StandardAccel" })

-- Workspaces
hl.animation({ leaf = "workspaces",    enabled = true,  speed = 1.94, bezier = "m3EmphasizedDecel", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 1.21, bezier = "m3EmphasizedDecel", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 1.94, bezier = "m3EmphasizedAccel", style = "slide" })

-- Utility
hl.animation({ leaf = "zoomFactor",    enabled = true,  speed = 7,    bezier = "m3Standard" })
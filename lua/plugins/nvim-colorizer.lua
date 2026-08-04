return {
    "catgoose/nvim-colorizer.lua",
    event = "BufReadPre",
    opts = {
        user_default_options = {
            RGB = true,       -- #RGB
            RRGGBB = true,    -- #RRGGBB
            names = false,    -- "Blue", "red", etc. — off by default; noisy in prose/comments
            RRGGBBAA = true,  -- #RRGGBBAA
            AARRGGBB = false,
            rgb_fn = true,    -- rgb(...), rgba(...)
            hsl_fn = true,    -- hsl(...), hsla(...)
            css = true,       -- enables all CSS *features* (colors named, functions, etc.)
            css_fn = true,    -- enables all CSS *functions* (rgb_fn, hsl_fn, etc.)
            mode = "virtualtext", -- "background" | "foreground" | "virtualtext"
            tailwind = true,  -- highlight Tailwind class names too
        },
    },
}

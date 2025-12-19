-- Nibbler configuration for C programming number conversions
return {
    "Skosulor/nibbler",
    event = "VeryLazy",
    opts = {
        -- Enable virtual text to show decimal value of hex/bin numbers
        display_enabled = true,
        -- Show virtual text with alternate base
        show_virtual_text = true,
        -- Which bases to show when hovering / toggling
        formats = {
            hex = true,
            dec = true,
            bin = true,
        },
    },
}


return {
    "Skosulor/nibbler",
    opts = { display_enabled = true },
    show_virtual_text = true,
    formats = {
        hex = true,
        dec = true,
        bin = true,
    },
    keys = {
        { "<leader>nt", "<cmd>NibblerToggle<cr>", desc = "Nibbler: Toggle Base" },
        { "<leader>nh", "<cmd>NibblerToHex<cr>", desc = "Nibbler: to Hex" },
        { "<leader>nb", "<cmd>NibblerToBin<cr>", desc = "Nibbler: to Binary" },
        { "<leader>nd", "<cmd>NibblerToDec<cr>", desc = "Nibbler: to Decimal" },
    },
}

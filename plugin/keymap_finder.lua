vim.api.nvim_create_user_command("Keymaps", function()
    require("keymap_finder").pick_keymap()
end, {})

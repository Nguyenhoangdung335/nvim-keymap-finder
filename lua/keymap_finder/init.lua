local M = {}

function M.get_keymaps()
    local vim_modes = {
        ["n"] = "Normal",
        ["i"] = "Insert",
        ["v"] = "Visual",
        ["x"] = "Visual",
        ["c"] = "Command",
        ["s"] = "Select",
        ["t"] = "Terminal",
        ["o"] = "Operator-pending",
    }
    local keymap_results = {}

    for mode_char, mode_name in pairs(vim_modes) do
        local keymaps = vim.api.nvim_get_keymap(mode_char)
        for _, keymap in ipairs(keymaps) do
            if keymap.desc and keymap.desc ~= "" then
                table.insert(keymap_results, {
                    mode = mode_name,
                    lhs = keymap.lhs,
                    rhs = keymap.rhs,
                    desc = keymap.desc or "",
                    opts = {
                        noremap = keymap.noremap,
                        silent = keymap.silent,
                        expr = keymap.expr,
                        nowait = keymap.nowait,
                    },
                })
            end
        end
    end

    return keymap_results
end

function M.pick_keymap()
    local has_telescope, telescope = pcall(require, "telescope")
    if not has_telescope then
        vim.notify("nvim_keymap_finder require telescope.nvim", vim.log.levels.ERROR)
        return
    end

    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    local keymaps = M.get_keymaps()

    pickers
        .new(conf, {
            prompt_title = "Pick a keymap",
            finder = finders.new_table({
                results = keymaps,
                entry_maker = function(entry)
                    return {
                        value = entry,
                        display = string.format("[%s] %s -> %s %s", entry.mode, entry.lhs, entry.rhs, entry.desc),
                        ordinal = entry.lhs .. " " .. entry.rhs .. " " .. entry.desc,
                    }
                end,
            }),
            sorter = conf.generic_sorter({}),
            attach_mappings = function(prompt_bufnr, map)
                -- This is your safe "show notification" action, which is great.
                -- It will be the default action for <CR> in normal mode.
                actions.select_default:replace(function()
                    local selection = action_state.get_selected_entry()
                    vim.notify(string.format("LHS: %s | RHS: %s", selection.value.lhs, selection.value.rhs))
                end)

                -- Add a more powerful mapping for <C-e> to "execute" the keymap
                map("i", "<C-e>", function()
                    local selection = action_state.get_selected_entry()
                    actions.close(prompt_bufnr)
                    -- Feeds the keys to Neovim as if you typed them
                    vim.api.nvim_feedkeys(selection.value.lhs, "n", true)
                    vim.notify(string.format("Executed '%s'", selection.value.lhs))
                end)

                -- Add a mapping to copy the keymap's left-hand-side to your clipboard
                map("i", "<C-y>", function()
                    local selection = action_state.get_selected_entry()
                    vim.fn.setreg("+", selection.value.lhs)
                    vim.notify(string.format("Yanked '%s' to clipboard", selection.value.lhs))
                end)

                return true
            end,
        })
        :find()
end

return M

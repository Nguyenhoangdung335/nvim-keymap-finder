local M = {}

function M.get_keymaps()
    local vim_modes = {
        ["n"] = "Normal",
        ["i"] = "Insert",
        ["v"] = "Visual",
        ["V"] = "V-Line",
        ["c"] = "Command",
        ["s"] = "Select",
        ["S"] = "Select",
        ["t"] = "Terminal",
        ["R"] = "Replace",
        ["o"] = "Operator",
        ["!"] = "Shell",
    }
    local keymap_results = {}

    for _, mode in ipairs(vim_modes) do
        local keymaps = vim.api.nvim_get_keymap(mode:sub(1, 1))
        for _, keymap in ipairs(keymaps) do
            table.insert(keymap_results, {
                mode = mode,
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

    pickers.new(conf, {
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
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, map)
            -- actions.select_default:replace(function()
            --     actions.close(prompt_bufnr)
            --     local selection = action_state.get_selected_entry()
            --     vim.api.nvim_feedkeys(selection.value.lhs, "n", true)
            -- end)
            -- return true
            map("i", "<CR>", function()
                local selection = ation_state.get_selected_entry()
                actions.close(prompt_bufnr)
                vim.notify(
                    string.format(
                        "Keymap: [%s] %s -> %s %s",
                        selection.value.mode,
                        selection.value.lhs,
                        selection.value.rhs,
                        selection.value.desc
                    ),
                    vim.log.levels.INFO
                )
            end)
            return true
        end,
    }):find()
end

return M

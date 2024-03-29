return {
    "mfussenegger/nvim-dap",
    dependencies = {
        "nvim-telescope/telescope.nvim",
    },
    config = function()
        local dap = require("dap")

        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local conf = require("telescope.config").values
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")

        dap.adapters = {
            cppdbg = {
                id = "cppdbg",
                type = "executable",
                command = "/usr/local/lib/cpptools/extension/debugAdapters/bin/OpenDebugAD7",
            },
        }
        dap.configurations = {
            cpp = {
                {
                    name = "Launch file",
                    type = "cppdbg",
                    request = "launch",
                    program = function()
                        return coroutine.create(function(coro)
                            local opts = {}
                            pickers
                                .new(opts, {
                                    prompt_title = "Path to executable",
                                    finder = finders.new_oneshot_job(
                                        { "fd", "--hidden", "--no-ignore", "--type", "x" },
                                        {}
                                    ),
                                    sorter = conf.generic_sorter(opts),
                                    attach_mappings = function(buffer_number)
                                        actions.select_default:replace(function()
                                            actions.close(buffer_number)
                                            coroutine.resume(coro, action_state.get_selected_entry()[1])
                                        end)
                                        return true
                                    end,
                                })
                                :find()
                        end)
                    end,
                    cwd = "${workspaceFolder}",
                    stopAtEntry = true,
                    setupCommands = {
                        {
                            text = "-enable-pretty-printing",
                            description = "enable pretty printing",
                            ignoreFailures = false,
                        },
                    },
                },
                {
                    name = "Attach to gdbserver :1234",
                    type = "cppdbg",
                    request = "launch",
                    MIMode = "gdb",
                    miDebuggerServerAddress = "localhost:1234",
                    miDebuggerPath = "/usr/bin/gdb",
                    console = "integratedTerminal",
                    cwd = "${workspaceFolder}",
                    program = function()
                        return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
                    end,
                    setupCommands = {
                        {
                            text = "-enable-pretty-printing",
                            description = "enable pretty printing",
                            ignoreFailures = false,
                        },
                    },
                },
            },
        }
        -- require("dap.ext.vscode").load_launchjs()
    end,
}

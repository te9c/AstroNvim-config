return {
    "jay-babu/mason-nvim-dap.nvim",
    opts = {
        ensure_installed = { 'coreclr' },
        handlers = {
            function(config)
                -- all sources with no handler get passed here

                -- Keep original functionality
                require('mason-nvim-dap').default_setup(config)
            end,
            coreclr = function(config)
                -- local function get_dll()
                --     return coroutine.create(function(dap_run_co)
                --         local items = vim.fn.globpath(vim.fn.getcwd(), '**/bin/Debug/**/*.dll', 0, 1)
                --         local opts = {
                --             format_item = function(path)
                --                 return vim.fn.fnamemodify(path, ':t')
                --             end,
                --         }
                --         local function cont(choice)
                --             if choice == nil then
                --                 return nil
                --             else
                --                 coroutine.resume(dap_run_co, choice)
                --             end
                --         end
                --
                --         vim.ui.select(items, opts, cont)
                --     end)
                -- end

                vim.g.dotnet_build_project = function()
                    local default_path = vim.fn.getcwd() .. '/'
                    if vim.g['dotnet_last_proj_path'] ~= nil then
                        default_path = vim.g['dotnet_last_proj_path']
                    end
                    local path = vim.fn.input('Path to your *proj file', default_path, 'file')
                    vim.g['dotnet_last_proj_path'] = path
                    local cmd = 'dotnet build -c Debug ' .. path .. ' > /dev/null'
                    print('')
                    print('Cmd to execute: ' .. cmd)
                    local f = os.execute(cmd)
                    if f == 0 then
                        print('\nBuild: ✔️ ')
                    else
                        print('\nBuild: ❌ (code: ' .. f .. ')')
                    end
                end

                vim.g.dotnet_get_dll_path = function()
                    local request = function()
                        return vim.fn.input('Path to dll', vim.fn.getcwd() .. '/bin/Debug/', 'file')
                    end

                    if vim.g['dotnet_last_dll_path'] == nil then
                        vim.g['dotnet_last_dll_path'] = request()
                    else
                        if vim.fn.confirm('Do you want to change the path to dll?\n' .. vim.g['dotnet_last_dll_path'], '&yes\n&no', 2) == 1 then
                            vim.g['dotnet_last_dll_path'] = request()
                        end
                    end

                    return vim.g['dotnet_last_dll_path']
                end

                local configp = {
                    {
                        type = "coreclr",
                        name = "launch - netcoredbg",
                        request = "launch",
                        program = function()
                            if vim.fn.confirm('Should I recompile first?', '&yes\n&no', 2) == 1 then
                                vim.g.dotnet_build_project()
                            end
                            return vim.g.dotnet_get_dll_path()
                        end,
                    },
                }

                local dap = require('dap')

                dap.adapters.coreclr = config.adapters
                dap.configurations.cs = configp
                dap.configurations.fsharp = configp
            end,
        }
    }
}
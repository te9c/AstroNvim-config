return {
  -- Configure AstroNvim updates
  updater = {
    remote = "origin",     -- remote to use
    channel = "stable",    -- "stable" or "nightly"
    version = "latest",    -- "latest", tag name, or regex search like "v1.*" to only do updates before v2 (STABLE ONLY)
    branch = "nightly",    -- branch name (NIGHTLY ONLY)
    commit = nil,          -- commit hash (NIGHTLY ONLY)
    pin_plugins = nil,     -- nil, true, false (nil will pin plugins on stable only)
    skip_prompts = false,  -- skip prompts about breaking changes
    show_changelog = true, -- show the changelog after performing an update
    auto_quit = false,     -- automatically quit the current session after a successful update
    remotes = {            -- easily add new remotes to track
      --   ["remote_name"] = "https://remote_url.come/repo.git", -- full remote url
      --   ["remote2"] = "github_user/repo", -- GitHub user/repo shortcut,
      --   ["remote3"] = "github_user", -- GitHub user assume AstroNvim fork
    },
  },

  -- Set colorscheme to use
  colorscheme = "astrodark",

  -- Diagnostics configuration (for vim.diagnostics.config({...})) when diagnostics are on
  diagnostics = {
    virtual_text = true,
    underline = true,
  },

  lsp = {
    -- customize lsp formatting options
    formatting = {
      -- control auto formatting on save
      format_on_save = {
        enabled = true,     -- enable or disable format on save globally
        allow_filetypes = { -- enable format on save for specified filetypes only
          -- "go",
        },
        ignore_filetypes = { -- disable format on save for specified filetypes
          "cpp"
        },
      },
      disabled = { -- disable formatting capabilities for the listed language servers
        -- disable lua_ls formatting capability if you want to use StyLua to format your lua code
        -- "lua_ls",
      },
      timeout_ms = 1000, -- default format timeout
      -- filter = function(client) -- fully override the default formatting function
      --   return true
      -- end
    },
    -- enable servers that you already have installed without mason
    servers = {
      -- "omnisharp",
    },
    config = {
      -- omnisharp = {
      --   cmd = "omnisharp",
      -- }
    }
  },

  -- Configure require("lazy").setup() options
  lazy = {
    defaults = { lazy = true },
    performance = {
      rtp = {
        -- customize default disabled vim plugins
        disabled_plugins = { "tohtml", "gzip", "matchit", "zipPlugin", "netrwPlugin", "tarPlugin" },
      },
    },
  },

  -- This function is run last and is a good place to configuring
  -- augroups/autocommands and custom filetypes also this just pure lua so
  -- anything that doesn't fit in the normal config locations above can go here
  polish = function()
    vim.api.nvim_create_autocmd("LspAttach", {
      desc = "Fix startup error by disabling semantic tokens for omnisharp",
      group = vim.api.nvim_create_augroup("OmnisharpHook", {}),
      callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        local function toSnakeCase(str)
          return string.gsub(str, "%s*[- ]%s*", "_")
        end

        if client.name == 'omnisharp' then
          local tokenModifiers = client.server_capabilities.semanticTokensProvider.legend.tokenModifiers
          for i, v in ipairs(tokenModifiers) do
            tokenModifiers[i] = toSnakeCase(v)
          end
          local tokenTypes = client.server_capabilities.semanticTokensProvider.legend.tokenTypes
          for i, v in ipairs(tokenTypes) do
            tokenTypes[i] = toSnakeCase(v)
          end
        end
      end,
    })

    local CompileAndRunCpp = function()
      local stripExtension = function(path)
        local file_name = path:match("[^/]*.cpp$")
        return file_name:sub(0, #file_name - 4)
      end

      local compilatorCommand = "g++"
      local compilationArgs = { "-std=c++17" }

      local cmd = compilatorCommand .. ' '
      for i, v in pairs(compilationArgs) do
        cmd = cmd .. v .. ' '
      end
      local path = vim.api.nvim_buf_get_name(0)
      cmd = cmd .. path .. ' -o ' .. stripExtension(path) .. ' && ./' .. stripExtension(path)

      -- local run = Terminal:new({ cmd = cmd, direction = 'float',})
      vim.cmd('TermExec cmd="' .. cmd .. '"')
    end

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
      pattern = { "*.cpp" },
      desc = "Compile and run cpp file",
      callback = function()
        vim.keymap.set("n", "<leader>tr", CompileAndRunCpp, { desc = "ToggleTerm compile and run" })
      end
    })

    require('dap.ext.vscode').load_launchjs()
  end,
}

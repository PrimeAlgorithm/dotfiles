-- Leaders
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Set system clipboard
vim.opt.clipboard = "unnamedplus"

-- Plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    vim.fn.system(
        {
            "git",
            "clone",
            "--filter=blob:none",
            "--branch=stable",
            "https://github.com/folke/lazy.nvim.git",
            lazypath
        }
    )
end
vim.opt.rtp:prepend(lazypath)

-- Code editor stuff
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 300

-- Declare plugins
require("lazy").setup(
    {
        -- Util libs
	{"nvim-lua/plenary.nvim"},
	{"nvim-tree/nvim-web-devicons"},
        {"MunifTanjim/nui.nvim"},
        -- Themes
        {
            "folke/tokyonight.nvim",
            priority = 1000,
            config = function()
                vim.cmd.colorscheme("tokyonight")
            end
        },
	-- Statusline
        {
            "nvim-lualine/lualine.nvim",
            config = function()
                require("lualine").setup({options = {globalstatus = true}})
            end
        },
	-- Tab like bars for buffers
        {
            "akinsho/bufferline.nvim",
            version = "*",
            config = function()
                require("bufferline").setup({})
            end
        },
        -- File explorer
        {
            "nvim-neo-tree/neo-tree.nvim",
            branch = "v3.x",
            dependencies = {"nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons", "MunifTanjim/nui.nvim"},
            config = function()
                require("neo-tree").setup({ })
                vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle<cr>", {desc = "File Explorer"})
            end
        },
        -- Fuzzy finding (files, grep, buffers, etc.)
        {
            "nvim-telescope/telescope.nvim",
            branch = "0.1.x",
            dependencies = {"nvim-lua/plenary.nvim"},
            config = function()
                local telescope = require("telescope")
                telescope.setup(
                    {
                        defaults = {mappings = {i = {["<C-u>"] = false, ["<C-d>"] = false}}}
                    }
                )
                pcall(telescope.load_extension, "fzf")
                vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", {desc = "Find files"})
                vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", {desc = "Live grep (rg)"})
                vim.keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>", {desc = "Buffers"})
                vim.keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", {desc = "Help"})
            end
        },
        -- Native fast sorter for Telescope (builds with CMake)
        {
            "nvim-telescope/telescope-fzf-native.nvim",
            build = "cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release"
        },
        -- Treesitter (better highlighting & code-aware movements)
        {
            "nvim-treesitter/nvim-treesitter",
            build = ":TSUpdate",
            config = function()
                require("nvim-treesitter.configs").setup(
                    {
                        ensure_installed = {
                            "c",
                            "cpp",
                            "python",
                            "rust",
                            "lua",
                            "vim",
                            "vimdoc",
                            "bash",
                            "markdown",
                            "json",
                            "toml"
                        },
                        highlight = {enable = true},
                        indent = {enable = true}
                    }
                )
            end
        },
        -- LSP: install/manage servers (Mason) + connect them (lspconfig)
        {"mason-org/mason.nvim", config = true},
        {
            "mason-org/mason-lspconfig.nvim",
            dependencies = {"neovim/nvim-lspconfig"},
            config = function()
                require("mason-lspconfig").setup(
                    {
                        ensure_installed = {"clangd", "pyright", "ruff", "rust_analyzer"}
                    }
                )
                local lspconfig = require("lspconfig")
                local capabilities = require("cmp_nvim_lsp").default_capabilities()
                for _, server in ipairs({"clangd", "pyright", "rust_analyzer"}) do
                    lspconfig[server].setup({capabilities = capabilities})
                end
                -- ruff as a separate LSP for Python linting (optional)
                pcall(
                    function()
                        lspconfig.ruff.setup({capabilities = capabilities})
                    end
                )
                -- LSP keybinds
                local map = vim.keymap.set
                map("n", "K", vim.lsp.buf.hover, {desc = "Hover"})
                map("n", "gd", vim.lsp.buf.definition, {desc = "Go to definition"})
                map("n", "gr", vim.lsp.buf.references, {desc = "References"})
                map("n", "<leader>rn", vim.lsp.buf.rename, {desc = "Rename symbol"})
                map("n", "<leader>ca", vim.lsp.buf.code_action, {desc = "Code action"})
                map("n", "<leader>dd", vim.diagnostic.open_float, {desc = "Line diagnostics"})
                map("n", "[d", vim.diagnostic.goto_prev, {desc = "Prev diagnostic"})
                map("n", "]d", vim.diagnostic.goto_next, {desc = "Next diagnostic"})
            end
        },
        -- Autocomplete + snippets
        {
            "hrsh7th/nvim-cmp",
            dependencies = {
                "hrsh7th/cmp-nvim-lsp",
                "hrsh7th/cmp-buffer",
                "hrsh7th/cmp-path",
                "L3MON4D3/LuaSnip",
                "saadparwaiz1/cmp_luasnip",
                "rafamadriz/friendly-snippets"
            },
            config = function()
                require("luasnip.loaders.from_vscode").lazy_load()
                local cmp = require("cmp")
                local luasnip = require("luasnip")
                cmp.setup(
                    {
                        snippet = {expand = function(args)
                                luasnip.lsp_expand(args.body)
                            end},
                        mapping = cmp.mapping.preset.insert(
                            {
                                ["<CR>"] = cmp.mapping.confirm({select = true}),
                                ["<Tab>"] = cmp.mapping(
                                    function(fallback)
                                        if cmp.visible() then
                                            cmp.select_next_item()
                                        elseif luasnip.expand_or_jumpable() then
                                            luasnip.expand_or_jump()
                                        else
                                            fallback()
                                        end
                                    end,
                                    {"i", "s"}
                                ),
                                ["<S-Tab>"] = cmp.mapping(
                                    function(fallback)
                                        if cmp.visible() then
                                            cmp.select_prev_item()
                                        elseif luasnip.jumpable(-1) then
                                            luasnip.jump(-1)
                                        else
                                            fallback()
                                        end
                                    end,
                                    {"i", "s"}
                                )
                            }
                        ),
                        sources = {{name = "nvim_lsp"}, {name = "buffer"}, {name = "path"}, {name = "luasnip"}}
                    }
                )
            end
        },
        -- Formatting & linting (simple and fast)
        {
            "stevearc/conform.nvim",
            config = function()
                require("conform").setup(
                    {
                        formatters_by_ft = {
                            c = {"clang_format"},
                            cpp = {"clang_format"},
                            python = {"ruff_format"}, -- or "black"
                            rust = {"rustfmt"}
                        },
                        format_on_save = {lsp_fallback = true}
                    }
                )
                vim.api.nvim_create_user_command(
                    "Format",
                    function()
                        require("conform").format()
                    end,
                    {}
                )
                vim.keymap.set("n", "<leader>f", "<cmd>Format<cr>", {desc = "Format buffer"})
            end
        },
        {
            "mfussenegger/nvim-lint",
            config = function()
                require("lint").linters_by_ft = {
                    python = {"ruff"}
                    -- If you install clang-tidy, you can enable:
                    -- c = { "clangtidy" }, cpp = { "clangtidy" },
                }
                vim.api.nvim_create_autocmd(
                    {"BufWritePost", "InsertLeave"},
                    {
                        callback = function()
                            require("lint").try_lint()
                        end
                    }
                )
            end
        },
        -- Git signs in the gutter
        {"lewis6991/gitsigns.nvim", config = function()
                require("gitsigns").setup({})
            end},
        -- Helpful popups that show available keymaps
        {"folke/which-key.nvim", config = function()
                require("which-key").setup({})
            end},
        -- Integrated terminal
        {
            "akinsho/toggleterm.nvim",
            version = "*",
            config = function()
                require("toggleterm").setup({})
                vim.keymap.set("n", "<leader>t", "<cmd>ToggleTerm<cr>", {desc = "Terminal"})
            end
        },
        -- Indent guides
        {"lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {}},
	
	-- Multiline comment
	{"numToStr/Comment.nvim", config = function()
		require("Comment").setup()
	end},
	
	-- Discord Status
	{"andweeb/presence.nvim", 
		auto_update = true,
  		main_image = "neovim",
  		show_time = true,

  		editing_text = "Editing %s",
  		reading_text = "Reading %s",
  		file_explorer_text = "Browsing files",
  		git_commit_text = "Committing…",
  		plugin_manager_text = "Managing plugins",
  		workspace_text = "In Neovim",

  		enable_line_number = false,
  		buttons = false,
    	}
}
)



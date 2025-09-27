-- Leaders
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Set system clipboard
vim.opt.clipboard = "unnamedplus"

-- Tabbing (VSCode-like)
vim.opt.expandtab = true -- insert spaces instead of tabs
vim.opt.shiftwidth = 4 -- >> and autoindent use 4 spaces
vim.opt.tabstop = 4 -- a <Tab> shows as 4 spaces
vim.opt.softtabstop = 4 -- <Tab>/<BS> feel like 4 spaces
vim.opt.smarttab = true -- <Tab> at line start uses shiftwidth

-- Plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "--branch=stable",
        "https://github.com/folke/lazy.nvim.git",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- Code editor stuff
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 300

-- Helper: create FileType autocmd to start an LSP
local function start_on(ft_list, name, cfg)
    vim.api.nvim_create_autocmd("FileType", {
        pattern = ft_list,
        callback = function(args)
            local final = vim.tbl_deep_extend("force", {}, cfg or {}, { bufnr = args.buf, name = name })
            vim.lsp.start(final)
        end,
    })
end

-- Declare plugins
require("lazy").setup({
    -- Util libs
    { "nvim-lua/plenary.nvim" },
    { "nvim-tree/nvim-web-devicons" },
    { "MunifTanjim/nui.nvim" },

    -- Themes
    {
        "folke/tokyonight.nvim",
        priority = 1000,
        config = function()
            vim.cmd.colorscheme("tokyonight")
        end,
    },

    -- Statusline
    {
        "nvim-lualine/lualine.nvim",
        config = function()
            require("lualine").setup({ options = { globalstatus = true } })
        end,
    },

    -- Tab-like bars for buffers
    {
        "akinsho/bufferline.nvim",
        version = "*",
        config = function()
            require("bufferline").setup({})
        end,
    },

    -- File explorer
    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons", "MunifTanjim/nui.nvim" },
        config = function()
            require("neo-tree").setup({
                window = { width = 22 },
                file_system = {
                    filtered_items = {
                        visible = true,
                        hide_dotfiles = false,
                        hide_gitignored = false,
                    },
                },
            })
            vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle<cr>", { desc = "File Explorer" })
        end,
    },

    -- Fuzzy finding
    {
        "nvim-telescope/telescope.nvim",
        branch = "0.1.x",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            local telescope = require("telescope")
            telescope.setup({
                defaults = { mappings = { i = { ["<C-u>"] = false, ["<C-d>"] = false } } },
            })
            pcall(telescope.load_extension, "fzf")
            vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find files" })
            vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Live grep (rg)" })
            vim.keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Buffers" })
            vim.keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", { desc = "Help" })
        end,
    },

    -- Native sorter for Telescope (builds with CMake)
    {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release",
    },

    -- Treesitter
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter.configs").setup({
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
                    "toml",
                    "html",
                    "xml",
                    "javascript",
                    "typescript",
                    "tsx",
                    "css",
                },
                highlight = { enable = true },
                indent = { enable = true },
                autotag = { enable = true },
            })
        end,
    },

    -- Auto-close/rename HTML tags
    {
        "windwp/nvim-ts-autotag",
        config = function()
            require("nvim-ts-autotag").setup()
        end,
    },

    -- TypeScript/JavaScript LSP (vtsls)
    { "yioneko/nvim-vtsls" },

    -- Optional: Emmet
    { "olrtg/emmet-language-server" },

    -- Mason (installer) + mason-lspconfig only for ensuring installs
    { "mason-org/mason.nvim", config = true },
    {
        "mason-org/mason-lspconfig.nvim",
        -- keep lspconfig as a dependency for server metadata (but we won't require it in *your* code)
        dependencies = { "neovim/nvim-lspconfig" },
        config = function()
            require("mason-lspconfig").setup({
                ensure_installed = {
                    "clangd",
                    "pyright",
                    "ruff",
                    "rust_analyzer",
                    "html",
                    "cssls",
                    "eslint",
                    "emmet_language_server",
                    "vtsls",
                },
            })

            -- capabilities from nvim-cmp
            local capabilities = require("cmp_nvim_lsp").default_capabilities()

            -- Define server configs using the new API
            local cfg = vim.lsp.config -- alias, just for brevity

            -- C / C++
            cfg["clangd"] = {
                cmd = { "clangd" },
                capabilities = capabilities,
            }
            start_on({ "c", "cpp", "objc", "objcpp" }, "clangd", cfg["clangd"])

            -- Python (pyright + ruff)
            cfg["pyright"] = {
                cmd = { "pyright-langserver", "--stdio" },
                capabilities = capabilities,
            }
            start_on({ "python" }, "pyright", cfg["pyright"])

            cfg["ruff"] = {
                cmd = { "ruff", "server" },
                capabilities = capabilities,
            }
            start_on({ "python" }, "ruff", cfg["ruff"])

            -- Rust
            cfg["rust_analyzer"] = {
                cmd = { "rust-analyzer" },
                capabilities = capabilities,
            }
            start_on({ "rust" }, "rust_analyzer", cfg["rust_analyzer"])

            -- HTML / CSS
            cfg["html"] = {
                cmd = { "vscode-html-language-server", "--stdio" },
                capabilities = capabilities,
            }
            start_on({ "html" }, "html", cfg["html"])

            cfg["cssls"] = {
                cmd = { "vscode-css-language-server", "--stdio" },
                capabilities = capabilities,
            }
            start_on({ "css", "scss", "less" }, "cssls", cfg["cssls"])

            -- Emmet
            cfg["emmet_language_server"] = {
                cmd = { "emmet-language-server", "--stdio" },
                filetypes = {
                    "html",
                    "css",
                    "sass",
                    "scss",
                    "less",
                    "javascriptreact",
                    "typescriptreact",
                    "javascript",
                    "typescript",
                    "vue",
                    "svelte",
                    "astro",
                },
                capabilities = capabilities,
            }
            start_on(
                {
                    "html",
                    "css",
                    "sass",
                    "scss",
                    "less",
                    "javascriptreact",
                    "typescriptreact",
                    "javascript",
                    "typescript",
                    "vue",
                    "svelte",
                    "astro",
                },
                "emmet_language_server",
                cfg["emmet_language_server"]
            )

            -- ESLint
            cfg["eslint"] = {
                cmd = { "vscode-eslint-language-server", "--stdio" },
                capabilities = capabilities,
                settings = { workingDirectory = { mode = "auto" } },
            }
            start_on(
                { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte" },
                "eslint",
                cfg["eslint"]
            )

            -- TypeScript/JavaScript via vtsls
            cfg["vtsls"] = {
                cmd = { "vtsls" },
                capabilities = capabilities,
                settings = {
                    typescript = { preferences = { importModuleSpecifier = "non-relative" } },
                    javascript = { preferences = { importModuleSpecifier = "non-relative" } },
                },
            }
            start_on(
                { "typescript", "typescriptreact", "tsx", "javascript", "javascriptreact", "jsx" },
                "vtsls",
                cfg["vtsls"]
            )

            -- LSP keybinds
            local map = vim.keymap.set
            map("n", "K", vim.lsp.buf.hover, { desc = "Hover" })
            map("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
            map("n", "gr", vim.lsp.buf.references, { desc = "References" })
            map("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })
            map("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
            map("n", "<leader>dd", vim.diagnostic.open_float, { desc = "Line diagnostics" })
            map("n", "[d", vim.diagnostic.goto_prev, { desc = "Prev diagnostic" })
            map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
        end,
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
            "rafamadriz/friendly-snippets",
        },
        config = function()
            require("luasnip.loaders.from_vscode").lazy_load()
            local cmp = require("cmp")
            local luasnip = require("luasnip")

            local has_words_before = function()
                local line, col = unpack(vim.api.nvim_win_get_cursor(0))
                if col == 0 then
                    return false
                end
                local text = vim.api.nvim_buf_get_text(0, line - 1, col - 1, line - 1, col, {})[1]
                return not text:match("%s")
            end

            cmp.setup({
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ["<CR>"] = cmp.mapping.confirm({ select = true }),
                    ["<Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_next_item()
                        elseif luasnip.expand_or_jumpable() then
                            luasnip.expand_or_jump()
                        elseif has_words_before() then
                            cmp.complete()
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                    ["<S-Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_prev_item()
                        elseif luasnip.jumpable(-1) then
                            luasnip.jump(-1)
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                }),
                sources = {
                    { name = "nvim_lsp" },
                    { name = "buffer" },
                    { name = "path" },
                    { name = "luasnip" },
                },
            })
        end,
    },

    -- nvim-lint (deduped)
    {
        "mfussenegger/nvim-lint",
        config = function()
            require("lint").linters_by_ft = {
                python = { "ruff" },
                javascript = { "eslint_d" },
                javascriptreact = { "eslint_d" },
                typescript = { "eslint_d" },
                typescriptreact = { "eslint_d" },
                -- c = { "clangtidy" }, cpp = { "clangtidy" }, -- if you install clang-tidy
            }
            vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
                callback = function()
                    require("lint").try_lint()
                end,
            })
        end,
    },

    -- Git signs
    {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup({})
        end,
    },

    -- Which-key
    {
        "folke/which-key.nvim",
        config = function()
            require("which-key").setup({})
        end,
    },

    -- Integrated terminal
    {
        "akinsho/toggleterm.nvim",
        version = "*",
        config = function()
            require("toggleterm").setup({
                shell = "powershell",
            })
            vim.keymap.set("t", "<Esc>", "<cmd>ToggleTerm<cr>", { desc = "Close Terminal" })
            vim.keymap.set("n", "<leader>t", "<cmd>ToggleTerm<cr>", { desc = "Terminal" })
        end,
    },

    -- Indent guides
    { "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {} },

    -- Multiline comment
    {
        "numToStr/Comment.nvim",
        config = function()
            require("Comment").setup()
        end,
    },

    -- Conform (Formatting) with 4-space clang-format defaults
    {
        "stevearc/conform.nvim",
        config = function()
            require("conform").setup({
                formatters_by_ft = {
                    c = { "clang_format" },
                    cpp = { "clang_format" },
                    python = { "ruff_format" }, -- or "black"
                    rust = { "rustfmt" },
                    lua = { "stylua" },
                    javascript = { "prettierd", "prettier", "biome" },
                    typescript = { "prettierd", "prettier", "biome" },
                    javascriptreact = { "prettierd", "prettier", "biome" },
                    typescriptreact = { "prettierd", "prettier", "biome" },
                    json = { "prettierd", "prettier", "biome" },
                    jsonc = { "prettierd", "prettier", "biome" },
                    html = { "prettierd", "prettier" },
                    css = { "prettierd", "prettier" },
                    scss = { "prettierd", "prettier" },
                    markdown = { "prettierd", "prettier" },
                    yaml = { "prettierd", "prettier" },
                },
                formatters = {
                    clang_format = {
                        prepend_args = {
                            "-style",
                            "{BasedOnStyle: LLVM, IndentWidth: 4, TabWidth: 4, UseTab: Never}",
                        },
                    },
                    stylua = { prepend_args = { "--indent-type", "Spaces", "--indent-width", "4" } },
                },
                format_on_save = { lsp_fallback = true },
            })

            vim.api.nvim_create_user_command("Format", function()
                require("conform").format()
            end, {})

            vim.keymap.set("n", "<leader>f", "<cmd>Format<cr>", { desc = "Format buffer" })
        end,
    },

    -- Autopairs
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        dependencies = { "hrsh7th/nvim-cmp" },
        config = function()
            local npairs = require("nvim-autopairs")
            npairs.setup({
                check_ts = true,
                fast_wrap = {},
                disable_filetype = { "TelescopePrompt", "vim" },
            })

            local cmp_autopairs = require("nvim-autopairs.completion.cmp")
            local cmp = require("cmp")
            cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
        end,
    },
})

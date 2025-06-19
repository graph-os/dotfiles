" Enhanced Vim configuration for public dotfiles

" Basic settings
set nocompatible              " Use Vim defaults
set encoding=utf-8            " UTF-8 encoding
set fileencoding=utf-8
set backspace=indent,eol,start " Allow backspace in insert mode
set history=1000              " Command history
set showcmd                   " Show incomplete commands
set showmode                  " Show current mode
set autoread                  " Reload files changed outside vim
set hidden                    " Allow hidden buffers
set ttyfast                   " Optimize for fast terminal connections
set lazyredraw                " Don't redraw while executing macros
set updatetime=250            " Faster completion
set timeoutlen=500            " Faster key sequence completion
set clipboard=unnamedplus     " Use system clipboard

" UI settings
set number                    " Show line numbers
set relativenumber            " Relative line numbers
set ruler                     " Show cursor position
set cursorline                " Highlight current line
set wildmenu                  " Visual command line completion
set wildmode=list:longest,full " Command completion behavior
set wildignore=*.o,*~,*.pyc,*/.git/*,*/.hg/*,*/.svn/*,*/.DS_Store
set laststatus=2              " Always show status line
set scrolloff=7               " Keep 7 lines visible when scrolling
set sidescrolloff=5           " Keep 5 columns visible when scrolling horizontally
set showmatch                 " Show matching brackets
set mat=2                     " Tenths of second to blink matching brackets
set noerrorbells              " No annoying sound on errors
set novisualbell              " No annoying flash on errors
set t_vb=
set tm=500

" Search settings
set incsearch                 " Incremental search
set hlsearch                  " Highlight search results
set ignorecase                " Case insensitive search
set smartcase                 " Case sensitive when uppercase present
set magic                     " Enable extended regex

" Indentation
set autoindent                " Copy indent from current line
set smartindent               " Smart autoindenting
set expandtab                 " Use spaces instead of tabs
set smarttab                  " Be smart when using tabs
set tabstop=2                 " Tab width (display)
set shiftwidth=2              " Indent width
set softtabstop=2             " Soft tab width
set shiftround                " Round indent to multiple of shiftwidth

" Text rendering
set wrap                      " Wrap long lines
set linebreak                 " Wrap lines at convenient points
set textwidth=0               " No automatic line breaks
set colorcolumn=80,120        " Show column markers

" File handling
set nobackup                  " No backup files
set nowb                      " No write backup
set noswapfile                " No swap files
set autowrite                 " Automatically save before commands

" Enable mouse support
set mouse=a

" File type detection and syntax highlighting
filetype on
filetype plugin on
filetype indent on
syntax enable

" Color scheme (use default if no fancy schemes available)
set background=dark
silent! colorscheme desert

" Key mappings
let mapleader = " "           " Space as leader key
let g:mapleader = " "

" Quick escape
inoremap jk <ESC>
inoremap kj <ESC>

" Clear search highlighting
nnoremap <leader><space> :nohlsearch<CR>

" Quick save and quit
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>x :x<CR>
nnoremap <leader>Q :qa!<CR>

" Buffer navigation
nnoremap <leader>bn :bnext<CR>
nnoremap <leader>bp :bprevious<CR>
nnoremap <leader>bd :bdelete<CR>
nnoremap <leader>bb :buffers<CR>

" Window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Window resizing
nnoremap <leader>+ :vertical resize +5<CR>
nnoremap <leader>- :vertical resize -5<CR>
nnoremap <leader>= <C-w>=

" Tab navigation
nnoremap <leader>tn :tabnew<CR>
nnoremap <leader>tc :tabclose<CR>
nnoremap <leader>to :tabonly<CR>
nnoremap <leader>tm :tabmove<CR>

" Move lines up/down
nnoremap <A-j> :m .+1<CR>==
nnoremap <A-k> :m .-2<CR>==
inoremap <A-j> <Esc>:m .+1<CR>==gi
inoremap <A-k> <Esc>:m .-2<CR>==gi
vnoremap <A-j> :m '>+1<CR>gv=gv
vnoremap <A-k> :m '<-2<CR>gv=gv

" Better indentation
vnoremap < <gv
vnoremap > >gv

" Yank to end of line
nnoremap Y y$

" Center screen after navigation
nnoremap n nzz
nnoremap N Nzz
nnoremap * *zz
nnoremap # #zz
nnoremap g* g*zz
nnoremap g# g#zz

" Quick macro playback
nnoremap Q @q

" Toggle paste mode
set pastetoggle=<F2>

" File type specific settings
augroup filetype_settings
    autocmd!
    " Python
    autocmd FileType python setlocal tabstop=4 shiftwidth=4 softtabstop=4
    autocmd FileType python setlocal textwidth=79 colorcolumn=79
    
    " YAML
    autocmd FileType yaml setlocal tabstop=2 shiftwidth=2 softtabstop=2
    
    " Markdown
    autocmd FileType markdown setlocal wrap linebreak textwidth=0
    autocmd FileType markdown setlocal spell spelllang=en_us
    
    " Git commit
    autocmd FileType gitcommit setlocal textwidth=72 colorcolumn=72
    autocmd FileType gitcommit setlocal spell spelllang=en_us
    
    " JSON
    autocmd FileType json setlocal tabstop=2 shiftwidth=2 softtabstop=2
    
    " Shell scripts
    autocmd FileType sh setlocal tabstop=2 shiftwidth=2 softtabstop=2
    
    " Makefile (requires tabs)
    autocmd FileType make setlocal noexpandtab
augroup END

" Remove trailing whitespace on save
augroup trailing_whitespace
    autocmd!
    autocmd BufWritePre * :%s/\s\+$//e
augroup END

" Return to last edit position when opening files
augroup last_edit_position
    autocmd!
    autocmd BufReadPost *
        \ if line("'\"") > 1 && line("'\"") <= line("$") |
        \   exe "normal! g`\"" |
        \ endif
augroup END

" Highlight extra whitespace
highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/

" Status line configuration
set statusline=
set statusline+=%#PmenuSel#
set statusline+=%{StatuslineGit()}
set statusline+=%#LineNr#
set statusline+=\ %f
set statusline+=%m
set statusline+=%=
set statusline+=%#CursorColumn#
set statusline+=\ %y
set statusline+=\ %{&fileencoding?&fileencoding:&encoding}
set statusline+=\[%{&fileformat}\]
set statusline+=\ %p%%
set statusline+=\ %l:%c
set statusline+=\ 

" Simple git branch detection for statusline
function! GitBranch()
    return system("git rev-parse --abbrev-ref HEAD 2>/dev/null | tr -d '\n'")
endfunction

function! StatuslineGit()
    let l:branchname = GitBranch()
    return strlen(l:branchname) > 0?'  '.l:branchname.' ':''
endfunction

" Useful commands
command! W w !sudo tee % > /dev/null
command! Wq wq
command! WQ wq
command! Q q

" Quick editing of config files
nnoremap <leader>ev :vsplit $MYVIMRC<CR>
nnoremap <leader>sv :source $MYVIMRC<CR>

" Toggle relative line numbers
nnoremap <leader>rn :set relativenumber!<CR>

" Format JSON
command! FormatJSON %!python -m json.tool

" Create parent directories on save
augroup create_parent_dirs
    autocmd!
    autocmd BufWritePre * if !isdirectory(expand('%:h')) | call mkdir(expand('%:h'), 'p') | endif
augroup END

" Source private vimrc if it exists
if filereadable(expand("~/.dotfiles-private/.vimrc"))
    source ~/.dotfiles-private/.vimrc
endif

" Source local vimrc if it exists
if filereadable(expand("~/.vimrc.local"))
    source ~/.vimrc.local
endif
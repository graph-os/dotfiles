" Minimal Vim configuration for public dotfiles

" Basic settings
set nocompatible              " Use Vim defaults
set encoding=utf-8            " UTF-8 encoding
set backspace=indent,eol,start " Allow backspace in insert mode
set history=1000              " Command history
set showcmd                   " Show incomplete commands
set showmode                  " Show current mode
set autoread                  " Reload files changed outside vim
set hidden                    " Allow hidden buffers

" UI settings
set number                    " Show line numbers
set relativenumber            " Relative line numbers
set ruler                     " Show cursor position
set wildmenu                  " Visual command line completion
set wildmode=list:longest     " Command completion behavior
set laststatus=2              " Always show status line
set scrolloff=5               " Keep 5 lines visible when scrolling

" Search settings
set incsearch                 " Incremental search
set hlsearch                  " Highlight search results
set ignorecase                " Case insensitive search
set smartcase                 " Case sensitive when uppercase present

" Indentation
set autoindent                " Copy indent from current line
set smartindent               " Smart autoindenting
set expandtab                 " Use spaces instead of tabs
set tabstop=4                 " Tab width
set shiftwidth=4              " Indent width
set softtabstop=4             " Soft tab width

" File type detection
filetype on
filetype plugin on
filetype indent on

" Syntax highlighting
syntax enable

" Key mappings
let mapleader = " "           " Space as leader key

" Clear search highlighting
nnoremap <leader><space> :nohlsearch<CR>

" Quick save
nnoremap <leader>w :w<CR>

" Quick quit
nnoremap <leader>q :q<CR>

" Move between windows
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Disable arrow keys in normal mode
nnoremap <Up> <Nop>
nnoremap <Down> <Nop>
nnoremap <Left> <Nop>
nnoremap <Right> <Nop>

" Source private vimrc if it exists
if filereadable(expand("~/.dotfiles-private/.vimrc"))
    source ~/.dotfiles-private/.vimrc
endif

" Local customizations
if filereadable(expand("~/.vimrc.local"))
    source ~/.vimrc.local
endif
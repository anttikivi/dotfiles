set nocompatible

let mapleader = "\<space>"
let maplocalleader = "\<space>"

if !isdirectory(expand('~/.vim/swap'))
  call mkdir(expand('~/.vim/swap'), 'p')
endif

if !isdirectory(expand('~/.vim/backups'))
  call mkdir(expand('~/.vim/backups'), 'p')
endif

let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')
Plug 'airblade/vim-gitgutter'
Plug 'editorconfig/editorconfig-vim'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-vinegar'

Plug 'https://codeberg.org/ziglang/zig.vim'

Plug '~/src/personal/granite.vim'
Plug '~/src/personal/substratum.vim'
call plug#end()

filetype plugin indent on
syntax enable

set backspace=indent,eol,start
set backupdir=~/.vim/backups//
set clipboard=unnamedplus,unnamed
set colorcolumn=80
set directory=~/.vim/swap//
set noerrorbells
set expandtab
set hidden
set hlsearch
set ignorecase
set incsearch
set laststatus=2
set linebreak
set modeline
set number
set relativenumber
set ruler
set shiftwidth=4
let &showbreak = '> '
set signcolumn=yes
set smartcase
set t_vb=
set tabstop=4
set tags=./tags;,tags
set title
set visualbell
set wildignore+=.DS_Store

if has('termguicolors')
  set termguicolors
endif

if has('persistent_undo')
  call mkdir(expand('~/.vim/undodir'), 'p')
  set undodir=~/.vim/undodir//
  set undofile
endif

nnoremap <space> <nop>

" Clear search.
nnoremap <silent> <Esc><Esc> :nohlsearch<CR>

" Manage and navigate arglist.
nnoremap <leader>aa :execute 'argadd' fnameescape(expand('%'))<cr>
nnoremap <leader>aD :execute 'argdelete' fnameescape(expand('%'))<cr>
nnoremap <leader>al :args<cr>
nnoremap ]a :next<cr>
nnoremap [a :Next<cr>
nnoremap <leader>1 :argument 1<cr>
nnoremap <leader>2 :argument 2<cr>
nnoremap <leader>3 :argument 3<cr>
nnoremap <leader>4 :argument 4<cr>
nnoremap <leader>5 :argument 5<cr>
nnoremap <leader>6 :argument 6<cr>
nnoremap <leader>7 :argument 7<cr>
nnoremap <leader>8 :argument 8<cr>
nnoremap <leader>9 :argument 9<cr>

" Take line wrapping into account when moving up and down.
nnoremap <silent> <expr> j v:count == 0 ? 'gj' : 'j'
onoremap <silent> <expr> j v:count == 0 ? 'gj' : 'j'
xnoremap <silent> <expr> j v:count == 0 ? 'gj' : 'j'
nnoremap <silent> <expr> k v:count == 0 ? 'gk' : 'k'
onoremap <silent> <expr> k v:count == 0 ? 'gk' : 'k'
xnoremap <silent> <expr> k v:count == 0 ? 'gk' : 'k'

" Keep selection after indenting.
xnoremap < <gv
xnoremap > >gv

" Delete without yanking.
nnoremap <leader>d "_d
vnoremap <leader>d "_d

" Move between windows.
nnoremap <C-j> <C-W>j
nnoremap <C-k> <C-W>k
nnoremap <C-h> <C-W>h
nnoremap <C-l> <C-W>l

" Ctags.
nnoremap <leader>cg :call job_start(['ctags', '-R', '.'])<CR>
nnoremap <leader>tv :vertical stag <C-R><C-W><CR>
nnoremap <leader>ts :stag <C-R><C-W><CR>
nnoremap gd <C-]>
nnoremap gD g<C-]>
nnoremap <leader>tf :tag /

" Fzf.
nnoremap <leader>ff :Files<CR>
nnoremap <leader>fg :Rg<CR>
nnoremap <leader>fb :Buffers<CR>
nnoremap <leader>fr :call fzf#vim#resume()<CR>
nnoremap <leader>fa :Args<CR>

autocmd FileType fzf tnoremap <buffer> <esc> <C-c>

colorscheme granite

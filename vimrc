" === Auto-install vim-plug if not found === 
if empty(glob('~/.vim/autoload/plug.vim'))
    silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
    autocmd VimEnter * PlugInstall | source $MYVIMRC
endif

" === General Settings ===
set mouse=a              " Enable the mouse in all modes
set number               " Show line numbers
set wrap                 " Wrap overflowing lines
set linebreak            " Wrap happens at natural word boundaries
set hidden               " Allow switching between unsaved files
set clipboard=unnamed    " Use the OS clipboard by default
syntax on                " Enable syntax highlighting
filetype plugin indent on " Enable file type detection and indentation

" === Tabs and Indentation ===
set tabstop=4            " Set tab width to 4 spaces
set shiftwidth=4         " Set indentation width to 4 spaces
set expandtab            " Use spaces instead of tabs

" === Searching ===
set hlsearch             " Highlight search results
set ignorecase           " Ignore case in searches
set smartcase            " Enable case-sensitive search if uppercase is used

" === Highlighting ===
set colorcolumn=60,80,100
set cursorline           " Highlight the current line
highlight CursorLine cterm=NONE ctermbg=grey ctermfg=NONE guibg=#2E2E2E " Subtle highlight for current line

" === Status Line and Split Management ===
set laststatus=2         " Always show the status line
set showcmd              " Display the current command
set ruler                " Show cursor position (line and column)

set statusline=%f        " File name and path
set statusline+=%m       " Modified flag (+ if modified, - if not)
set statusline+=%=       " Center the rest of the content
set statusline+=%l,%c    " Cursor position (line,column)
set statusline+=\ [%L]   " Total number of lines
set statusline+=\ [%p%%] " Show percentage through the file
set statusline+=\ %y     " File type
set statusline+=\ [%{&fileencoding}] " Encoding
set statusline+=\ [%{&fileformat}]   " File format

set showtabline=2        " Always show the tab bar
set foldcolumn=1         " Add a margin for folds

" Define colors for active and inactive splits
hi StatusLine cterm=bold ctermbg=darkblue ctermfg=white guibg=#005f87 guifg=#ffffff
hi StatusLineNC cterm=NONE ctermbg=darkgrey ctermfg=black guibg=#3a3a3a guifg=#d0d0d0

" === Key Mappings for Navigation ===
nnoremap <leader>s :w<CR>   " Save file with \s
nnoremap <leader>x :x<CR>   " Save and exit with \x
nnoremap <Space> i_<Esc>r   " Insert a char and return to normal mode 
nnoremap <Enter> o<ESC>     " Insert a blank line below
nnoremap <leader>t :tabnew<CR>    " Open a new tab
nnoremap <leader>e :e<Space>      " Quickly open a file
nnoremap <leader>q :q<CR>         " Quit Vim
nnoremap <leader>w :w<CR>         " Save the file

" Split Navigation
nnoremap <C-h> <C-w>h " Move left
nnoremap <C-l> <C-w>l " Move right
nnoremap <C-j> <C-w>j " Move down
nnoremap <C-k> <C-w>k " Move up

" Open terminal below with 10-line height
nnoremap <leader>tt :below terminal<CR><C-\><C-n>:resize 10<CR>

" === Mode Switching ===
inoremap kj <Esc>
tnoremap <leader>nn <C-\><C-n>

" Set comment style for C files
autocmd FileType c setlocal commentstring=//%s 

" === Plugins ===
" Install Vim-Plug manually if not installed
" !curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim


call plug#begin('~/.vim/plugged')

" Plugins List
Plug 'tpope/vim-commentary'  " Comment out code easily
Plug 'NLKNguyen/papercolor-theme'
Plug 'arcticicestudio/nord-vim'

" Install fzf based on OS
if system('uname') =~ "Darwin"
    " macOS: Install fzf via Homebrew
    Plug 'junegunn/fzf'
    Plug 'junegunn/fzf.vim'
elseif system('uname') =~ "Linux"
    " Linux: Clone fzf manually
    Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
    Plug 'junegunn/fzf.vim'
endif

call plug#end()

" Activate PaperColor theme
set background=light
colorscheme PaperColor

" Use Ctrl-p to search files
nnoremap <C-p> :Files<Cr> 

" Prevent bad habits (disable arrow keys)
nnoremap <Left>  :echoe "Use h"<CR>
nnoremap <Right> :echoe "Use l"<CR>
nnoremap <Up>    :echoe "Use k"<CR>
nnoremap <Down>  :echoe "Use j"<CR>
inoremap <Left>  <ESC>:echoe "Use h"<CR>
inoremap <Right> <ESC>:echoe "Use l"<CR>
inoremap <Up>    <ESC>:echoe "Use k"<CR>
inoremap <Down>  <ESC>:echoe "Use j"<CR>

" Auto-save when idle
autocmd CursorHold,CursorHoldI * silent! wall

" Auto-save session on exit
autocmd VimLeavePre * mksession! ~/.vim-last-session.vim
set updatetime=2000

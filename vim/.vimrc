" Usa plug.vim como gerenciador de plugins
call plug#begin('~/.vim/plugged')

set laststatus=2

" Melhor barra de status (lightline + gitbranch)
Plug 'itchyny/lightline.vim'
Plug 'itchyny/vim-gitbranch'

Plug 'prabirshrestha/vim-lsp'

" Melhor barra superior para navegação entre buffers
Plug 'akinsho/bufferline.nvim'

" Terminal flutuante dentro do Vim
Plug 'voldikss/vim-floaterm'

" Alternativa ao Telescope (busca rápida)
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" Melhor realce de sintaxe sem Treesitter
Plug 'sheerun/vim-polyglot'

" Tema escuro de alto contraste com fundo transparente
Plug 'sainnhe/everforest'

call plug#end()

" Ativa cores no terminal
set termguicolors

" Configuração do tema Everforest (alto contraste, fundo transparente)
let g:everforest_background = 'hard'
let g:everforest_transparent_background = 1
colorscheme everforest

" Ativa números de linha e números relativos
set number
set relativenumber

" Configuração do lightline (barra inferior leve e funcional)
" let g:lightline

" Plugin para exibir branch do Git no lightline
function! FugitiveHead()
  return exists('*FugitiveHead') ? FugitiveHead() : ''
endfunction


" Configuração do Floaterm (terminal flutuante no Vim)
let g:floaterm_keymap_toggle = '<F12>'
let g:floaterm_transparency = 0

" Melhor navegação com setas no bufferline
nnoremap <S-Tab> :BufferLineCyclePrev<CR>
nnoremap <Tab> :BufferLineCycleNext<CR>

" Mapeamento do FZF para busca de arquivos
nnoremap <C-p> :Files<CR>

" Melhor integração com Kitty
if $TERM == "xterm-kitty"
  set termguicolors
endif

let g:lsp_diagnostics_enabled = 1
let g:lsp_text_edit_enabled = 1


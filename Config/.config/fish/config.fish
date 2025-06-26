set -g fish_greeting

# Environment variables for Qt theming
set -gx QT_QPA_PLATFORMTHEME qt5ct
set -gx QT_STYLE_OVERRIDE Fusion

if status is-interactive
    starship init fish | source
end

# List Directory (optimized)
alias l='eza -lh --icons=auto' # long list
alias ls='eza -1 --icons=auto' # short list  
alias ll='eza -lha --icons=auto --sort=name --group-directories-first' # long list all
alias ld='eza -lhD --icons=auto' # long list dirs
alias lt='eza --icons=auto --tree --level=2' # list folder as tree (limited depth for performance)
alias ltt='eza --icons=auto --tree' # full tree when needed

# Handy change dir shortcuts
abbr .. 'cd ..'
abbr ... 'cd ../..'
abbr .3 'cd ../../..'
abbr .4 'cd ../../../..'
abbr .5 'cd ../../../../..'

# Always mkdir a path (this doesn't inhibit functionality to make a single dir)
abbr mkdir 'mkdir -p'

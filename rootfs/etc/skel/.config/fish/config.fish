
set fish_greeting # Disable greeting
fish_vi_key_bindings

status is-login; and begin

    # Login shell initialisation
end

status is-interactive; and begin

    # Abbreviations
    abbr --add -- cat 'bat --paging=never'
    abbr --add -- l 'ls -l'
#     abbr --add -- lst 'eza --sort newest -l'

    # Aliases
#     alias eza 'eza --icons auto'
#     alias la 'eza -a'
#     alias ll 'eza -l'
#     alias lla 'eza -la'
#     alias ls eza
#     alias lt 'eza --tree'
    # alias nmtui 'NEWT_COLORS="root=lavender,crust border=sapphire,base window=overlay0,base title=rosewater,crust button=surface2,lavender button_active=crust,maroon" nmtui'

    # Interactive shell initialisation
    if test "$TERM" != dumb
        starship init fish | source
        fzf --fish | source
        zoxide init fish | source
    end

end

# Temporarily change options.
'builtin' 'local' '-a' 'p10k_config_opts'
[[ ! -o 'aliases'         ]] || p10k_config_opts+=('aliases')
[[ ! -o 'sh_glob'         ]] || p10k_config_opts+=('sh_glob')
[[ ! -o 'no_brace_expand' ]] || p10k_config_opts+=('no_brace_expand')
'builtin' 'setopt' 'no_aliases' 'no_sh_glob' 'brace_expand'

() {
  emulate -L zsh -o extended_glob

  # Unset all configuration options.
  unset -m '(POWERLEVEL9K_*|DEFAULT_USER)~POWERLEVEL9K_GITSTATUS_DIR'

  # Zsh >= 5.1 is required.
  [[ $ZSH_VERSION == (5.<1->*|<6->.*) ]] || return

  # Prompt colors.
  local grey='242'
  local red='1'
  local yellow='3'
  local blue='4'
  local magenta='5'
  local cyan='6'
  local white='7'
  local purple='105'

  # Left prompt segments.
  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
    # =========================[ Line #1 ]=========================
    dir                       # current directory
    vcs                       # git status
    virtualenv                # python virtual environment
    nix_shell                 # self explanatory
    #command_execution_time    # previous command duration
    # =========================[ Line #2 ]=========================
    newline                   # \n
    background_jobs           # self explanatory
    prompt_char               # prompt symbol
  )

  # Right prompt segments.
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    kubecontext
    newline                   # \n
  )

  # Basic style options that define the overall prompt look.
  typeset -g POWERLEVEL9K_BACKGROUND=                               # transparent background
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_{LEFT,RIGHT}_WHITESPACE=     # no surrounding whitespace
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SUBSEGMENT_SEPARATOR=''     # separate segments with a space
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SEGMENT_SEPARATOR=           # no end-of-line symbol
  typeset -g POWERLEVEL9K_VISUAL_IDENTIFIER_EXPANSION=              # no segment icons
  typeset -g POWERLEVEL9K_LEFT_SEGMENT_END_SEPARATOR=
  typeset -g POWERLEVEL9K_LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL=' '


  # Add an empty line before each prompt except the first. This doesn't emulate the bug
  # in Pure that makes prompt drift down whenever you use the Alt-C binding from fzf or similar.
  typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=false

  # Magenta prompt symbol if the last command succeeded.
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS}_FOREGROUND=$blue
  # Red prompt symbol if the last command failed.
  typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS}_FOREGROUND=$red
  # Default prompt symbol.
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIINS_CONTENT_EXPANSION='$ '

  # Python Virtual Environment.
  typeset -g POWERLEVEL9K_VIRTUALENV_FOREGROUND=$yellow
  typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_PYTHON_VERSION=false
  typeset -g POWERLEVEL9K_VIRTUALENV_{LEFT,RIGHT}_DELIMITER=
  typeset -g POWERLEVEL9K_VIRTUALENV_VISUAL_IDENTIFIER_EXPANSION='%f via%3F 󰌠'

  # Kubernetes context
  typeset -g POWERLEVEL9K_KUBECONTEXT_FOREGROUND=$purple
  typeset -g POWERLEVEL9K_KUBECONTEXT_PREFIX=

  # Current directory.
  typeset -g POWERLEVEL9K_DIR_FOREGROUND=$blue

  typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique
  typeset -g POWERLEVEL9K_SHORTEN_DELIMITER=
  local anchor_files=(
    .git
  )
  typeset -g POWERLEVEL9K_SHORTEN_FOLDER_MARKER="(${(j:|:)anchor_files})"
  typeset -g POWERLEVEL9K_DIR_TRUNCATE_BEFORE_MARKER="first"
  typeset -g POWERLEVEL9K_DIR_MAX_LENGTH=80

  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=10
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=0
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FORMAT='d h m s'
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=$yellow
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PREFIX=' '



  # Disable async loading indicator to make directories that aren't Git repositories
  # indistinguishable from large Git repositories without known state.
  typeset -g POWERLEVEL9K_VCS_LOADING_TEXT=

  # Don't wait for Git status even for a millisecond, so that prompt always updates
  # asynchronously when Git state changes.
  typeset -g POWERLEVEL9K_VCS_MAX_SYNC_LATENCY_SECONDS=0

  typeset -g POWERLEVEL9K_VCS_DISABLE_GITSTATUS_FORMATTING=true

  function custom_git_formatter() {
    emulate -L zsh

    if [[ -n $P9K_CONTENT ]]; then
      # If P9K_CONTENT is not empty, use it. It's either "loading" or from vcs_info (not from
      # gitstatus plugin). VCS_STATUS_* parameters are not available in this case.
      typeset -g my_git_format=$P9K_CONTENT
      return
    fi

    if (( $1 )); then
      # Styling for up-to-date Git status.
      local branch_color='%4F'
      local git_status_color='%1F'
      local tag_color='%2F'
      local commit_color='%2F'
    else
      # Styling for incomplete and stale Git status -> grey
      local branch_color='%244F'
      local git_status_color='%244F'
      local tag_color='%244F'
      local commit_color='%244F'
    fi

    local res=

    if [[ -n $VCS_STATUS_LOCAL_BRANCH ]]; then
      local branch=${(V)VCS_STATUS_LOCAL_BRANCH}
      res+="$branch_color ${(g::)POWERLEVEL9K_VCS_BRANCH_ICON}${branch//\%/%%}"
    fi

    if [[ -n $VCS_STATUS_TAG ]]; then
      local tag=${(V)VCS_STATUS_TAG}
      res+="$tag_color(${tag//\%/%%})"
    fi

    # Display the current Git commit if there is no branch and no tag.
    # Tip: To always display the current Git commit, delete the next line.
    [[ -z $VCS_STATUS_LOCAL_BRANCH && -z $VCS_STATUS_TAG ]] &&  # <-- this line
      res+="$commit_color(${VCS_STATUS_COMMIT[1,8]})"

    local git_status=

    (( VCS_STATUS_STASHES        )) && git_status+='$'
    (( VCS_STATUS_NUM_STAGED     )) && git_status+="+"
    (( VCS_STATUS_NUM_UNSTAGED   )) && git_status+="!"
    (( VCS_STATUS_NUM_UNTRACKED  )) && git_status+="?"
    [[ -n $VCS_STATUS_ACTION     ]] && git_status+="${VCS_git_status_ACTION}"
    (( VCS_STATUS_NUM_CONFLICTED )) && git_status+="~"
    (( VCS_STATUS_COMMITS_BEHIND )) && git_status+="⇣"
    (( VCS_STATUS_COMMITS_AHEAD  )) && git_status+="⇡"

    [[ -n $git_status ]] && res+="$git_status_color"" [$git_status]"

    typeset -g custom_git_format=$res
  }

  functions -M custom_git_formatter 2>/dev/null

  typeset -g POWERLEVEL9K_VCS_PREFIX=" %fon "
  typeset -g POWERLEVEL9K_VCS_CONTENT_EXPANSION='${$((custom_git_formatter(1)))+${custom_git_format}}'
  typeset -g POWERLEVEL9K_VCS_LOADING_CONTENT_EXPANSION='${$((custom_git_formatter(0)))+${custom_git_format}}'

  #######################[ background_jobs: presence of background jobs ]#######################
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VERBOSE=false
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=$blue
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VISUAL_IDENTIFIER_EXPANSION='✦ '


  typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=off
  typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
  typeset -g POWERLEVEL9K_DISABLE_HOT_RELOAD=false


  #######################[ nix-shell: activated if in a nix-shell ]#######################
  typeset -g POWERLEVEL9K_NIX_SHELL_FOREGROUND=$cyan

  # Display the icon of nix_shell if PATH contains a subdirectory of /nix/store.
  # typeset -g POWERLEVEL9K_NIX_SHELL_INFER_FROM_PATH=false

  # Tip: If you want to see just the icon without "pure" and "impure", uncomment the next line.
  typeset -g POWERLEVEL9K_NIX_SHELL_CONTENT_EXPANSION="($name)"

  # Custom icon.
  typeset -g POWERLEVEL9K_NIX_SHELL_VISUAL_IDENTIFIER_EXPANSION='%f via%6F ❄️'


  # If p10k is already loaded, reload configuration.
  # This works even with POWERLEVEL9K_DISABLE_HOT_RELOAD=true.
  (( ! $+functions[p10k] )) || p10k reload
}

# Tell `p10k configure` which file it should overwrite.
typeset -g POWERLEVEL9K_CONFIG_FILE=${${(%):-%x}:a}

(( ${#p10k_config_opts} )) && setopt ${p10k_config_opts[@]}
'builtin' 'unset' 'p10k_config_opts'

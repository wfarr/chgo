unset GO_AUTO_VERSION

: ${PREEXEC_FUNCTIONS:=""}

function chgo_auto() {
  local dir="$PWD"
  local version

  until [[ -z "$dir" ]]; do
    if { read -r version <"$dir/.go-version"; } 2>/dev/null; then
      if [[ "$version" == "$GO_AUTO_VERSION" ]]; then return
      else
        GO_AUTO_VERSION="$version"
        chgo "$version"
        return $?
      fi
    fi

    dir="${dir%/*}"
  done

  if [[ -n "$GO_AUTO_VERSION" ]]; then
    if { read -r version <"$CHGO_ROOT/version"; } 2>/dev/null; then
      if [[ "$version" == "$GO_AUTO_VERSION" ]]; then return
      else
        GO_AUTO_VERSION="$version"
        chgo "$version"
        return $?
      fi
    else
      chgo_reset
      unset GO_AUTO_VERSION
    fi
  fi
}

if [[ -n "$ZSH_VERSION" ]]; then
  if [[ ! "$preexec_functions" == *chgo_auto* ]]; then
    preexec_functions+=("chgo_auto")
  fi
elif [[ -n "$BASH_VERSION" ]]; then
  if [[ -n "$PREEXEC_FUNCTIONS" ]]; then
    PREEXEC_FUNCTIONS="${PREEXEC_FUNCTIONS}; [[ \"\$BASH_COMMAND\" != \"\$PROMPT_COMMAND\" ]] && chgo_auto"
  else
    PREEXEC_FUNCTIONS="[[ \"\$BASH_COMMAND\" != \"\$PROMPT_COMMAND\" ]] && chgo_auto"
  fi

  trap 'eval "$PREEXEC_FUNCTIONS"' DEBUG
fi

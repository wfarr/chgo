SCRIPT_SOURCE=`dirname "${BASH_SOURCE:-$0}"`
CHGO_ROOT=$(cd "$SCRIPT_SOURCE"/../.. && pwd)
CHGO_VERSION="0.3.7"
GOES=()

for dir in "$CHGO_ROOT/versions"; do
  [[ -d "$dir" && -n "$(ls -A "$dir")" ]] && GOES+=("$dir"/*)
done
unset dir

mkdir -p $CHGO_ROOT/tmp

function chgo_reset()
{
  [[ -z "$GOROOT" ]] && return

  PATH=":$PATH:"; PATH="${PATH//:$GOROOT\/bin:/:}"
  PATH="${PATH#:}"; PATH="${PATH%:}"
  unset GOROOT
  hash -r
}

function chgo_install()
{
  version=$1
  installdir=$CHGO_ROOT/versions/$version
  logfile=$CHGO_ROOT/tmp/$version-$(date "+%s").log

  platform="$(uname -s | tr '[:upper:]' '[:lower:]')"

  if [ "$(uname -m)" = "x86_64" ]; then arch="amd64"
    else                                arch="386"
  fi

  # Default settings for new download location (1.2.2+)
  protocol="https"
  domain="storage.googleapis.com"
  url_path="golang"
  download_url="${protocol}://${domain}/${url_path}/go${version}.${platform}-${arch}.tar.gz"


  if [[ "$platform" = "darwin" ]]; then
    OSX_VERSION=$(sw_vers | grep ProductVersion | cut -f 2 -d ':'  | awk '{ print $1; }')

    if $(echo $OSX_VERSION | egrep '10\.6|10\.7'); then
      alternate_url="${protocol}://${domain}/${url_path}/go${version}.${platform}-${arch}-osx10.6.tar.gz"
      echo $alternate_url

    elif $(echo $OSX_VERSION | egrep '10\.8'); then
      alternate_url="${protocol}://${domain}/${url_path}/go${version}.${platform}-${arch}-osx10.8.tar.gz"
      echo $alternate_url
    else
      echo $download_url
    fi
  fi

  mkdir -p "${installdir}"

  ( \
    ( \
      (curl -v -f $download_url) || (curl -v -f $alternate_url) \
    ) | \
     tar zxv --strip-components 1 -C $installdir; [[ "${PIPESTATUS[0]}" != 0 ]] && exit 1 \
  ) 2>$logfile >$logfile || \
    {
      rm -rf $installdir

      echo "chgo: unable to install Go \`${version}'" >&2
      echo "chgo: see ${logfile} for details" >&2
      return 1
    }

    rm $logfile
    echo "chgo: installed ${version} to ${installdir}"

  GOES+=($installdir)
}

function chgo_use()
{
  [[ -n "$GOROOT" ]] && chgo_reset

  export GOROOT="$1"
  export PATH="$GOROOT/bin:$PATH"
}

function chgo()
{
  case "$1" in
    -h|--help)
      echo "usage: chgo [GO|VERSION|system]"
      ;;
    -V|--version)
      echo "chgo: $CHGO_VERSION"
      ;;
    "")
      local dir star
      for dir in "${GOES[@]}"; do
        dir="${dir%%/}"
        if [[ "$dir" == "$GOROOT" ]]; then star="*"
        else                               star=" "
        fi

        echo " $star ${dir##*/}"
      done
      ;;
    system) chgo_reset ;;
    *)
      local dir match
      for dir in "${GOES[@]}"; do
        dir="${dir%%/}"
        [[ "${dir##*/}" == *"$1"* ]] && match="$dir"
      done

      if [ -z "$match" ]; then
        if $(echo "${1}" | egrep -q -m1 '([0-9]{1,}\.)+[0-9]{1,}'); then
          echo "chgo: $1 not installed, trying to install" >&2
        else
          echo "chgo: $1 doesn't seems to be a version number (matching '([0-9]{1,}\.)+[0-9]{1,}')" >&2
          return 1
        fi
        if [ -n "$CHGO_SKIP_AUTO_INSTALL" ]; then
          return 1
        else
          chgo_install $1
          match="$CHGO_ROOT/versions/$1"
        fi
      fi

      shift
      chgo_use "$match" "$*"
      ;;
  esac
}

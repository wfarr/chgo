CHGO_ROOT=$(cd "$(dirname $BASH_SOURCE[@])"/../.. && pwd)
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

  mkdir -p $installdir
  platform="$(uname -s | tr '[:upper:]' '[:lower:]')"

  if [ "$(uname -m)" = "x86_64" ]; then arch="amd64"
  else                                  arch="386"
  fi

  download_url="https://go.googlecode.com/files/go${version}.${platform}-${arch}.tar.gz"

  if [[ "$platform" = "darwin" ]]; then
    OSX_VERSION=`sw_vers | grep ProductVersion | cut -f 2 -d ':'  | awk ' { print $1; } '`

    if !(echo $OSX_VERSION | egrep '10\.6|10\.7'); then
      alternate_url="https://go.googlecode.com/files/go${version}.${platform}-${arch}-osx10.6.tar.gz"
    else
      alternate_url="https://go.googlecode.com/files/go${version}.${platform}-${arch}-osx10.8.tar.gz"
    fi
  fi

  ( \
    ( \
      (curl -v -f $download_url) || (curl -v -f $alternate_url) \
    ) | \
    tar zxv --strip-components 1 -C $installdir; exit "${PIPESTATUS[0]}" \
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
        echo "chgo: $1 not installed, trying to install" >&2

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

# Version comparison shamelessly stolen from Dennis Williamson
# http://stackoverflow.com/users/26428/dennis-williamson
# http://stackoverflow.com/a/4025065/339727
function vercomp ()
{
    if [[ $1 == $2 ]]
    then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 2
        fi
    done
    return 0
}

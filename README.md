# chgo

Change go versions with ease. Sorry, [Billy](http://www.youtube.com/watch?v=tJWM5FmZyqU).

## Features

* Everything chruby has, but, you know, for go.
	* Which means it sets `$GOROOT`, mostly.
	* Obviously this means a ton of credit goes to [@postmodern](https://github.com/postmodern) for making [chruby](https://github.com/postmodern/chruby).
* Automatic installation of missing go versions.

## Installation

Grab the [latest release](https://github.com/wfarr/chgo/releases) from GitHub and put it somewhere.
Then source `$CHGO_ROOT/share/chgo/chgo.sh` in your configuration, somewhere (`$CHGO_ROOT` is wherever you put the release at).

### Auto-switching

After installation, source the auto-switcher:

```
source $CHGO_ROOT/share/chgo/auto.sh
```

It'll look for `.go-version` files in your projects (or any parent directory) and automatically switch versions for you. We also support setting a global `$CHGO_ROOT/version` file for a default version to activate.

#### Automatic installation of versions

By default, if you request to `chgo` to an uninstalled version, `chgo` will try and install it for you (using the precompiled binaries from the official downloads site).

If you find this behavior undesirable, you can disable it by setting:

```
CHGO_SKIP_AUTO_INSTALL=1
```

## Uninstallation

```
rm -rf $CHGO_ROOT
```

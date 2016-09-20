# CBO bash suite

Run common bash functions from a menu.

> Most of this scripts are under development, so use them **only for inspirational purpose!** They were "developed on Debian" and no testing has been performed on other distributions.

## Requirements

**cbo_helpers.sh** is required by every other scripts so download it first and put it in **/usr/local/bin**.

**cbo_completion** is only useful to have completion when using scripts as command line. Just check the path at the top of the file, run clickpanic_helpers.sh to install completion then logout/in. 

**cbo_menu.sh** is a global menu for all script (in development, don't use it).

## Plugins

Every other scripts can be run separately. Download the one you need and put it beside **cbo_helpers.sh**.

## Usage

```
cbo_{plugin}.sh [options] [function]
```

Options:
- **-m|--menu** Run with a select menu.
- **-h|--help** Know more about available functions.

## Contribution

Don't hesitate to improve or adapt this code for your needs!

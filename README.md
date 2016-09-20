# CBO bash suite

Run common bash functions from a menu.

> Most of this scripts are under development, so use them **only for inspirational purpose**! They were developed **for Debian** and no testing has been performed on other distributions.

## Requirements

**cbo.sh** is required by every other scripts. Download it first and put it in **/usr/local/bin/** (for a global access) or **/home/{user}/bin/**.

<!--
**cbo_completion** is only useful to have completion when using scripts as command line. Just check the path at the top of the file, run cbo_helpers.sh to install completion then logout/in.

**cbo_menu.sh** is a global menu for all script (in development, don't use it).
-->

## Plugins

Every other scripts can be run separately. Download the one you need and put it beside **cbo_helpers.sh**.

## Usage

```bash
[sudo] bash cbo.sh [-c|--configure] [-i|--interactive] [--install] [--purge] [--uninstall] [-V|--version] [-h|--help]
[sudo] bash cbo.sh [available_functions|calc|edit_var|escape_string|in_array|include_once|lstree|progress_bar|spinner|translate] [arg]... [-h|--help]
```

##### Options:
- **-c, --configure**
    Edit the configuration file with the default editor.
- **-i, --interactive**
    Run script with an interactive menu.
- **--install**
    Install the completion script, aliases and other stuffs in user folder.
- **--purge**
    Delete current configuration file.
- **--uninstall**
    Remove tracks of this script in user folder (excepted the config file).
- **-V, --version**
    Print version information and exit successfully.
- **-h, --help**
    Print this help screen and exit.

## Contribution

Don't hesitate to improve or adapt this code for your needs!

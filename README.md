GoToImp v0.7.0
==============

This is a BASH and ZSH directory traversal tool inspired by [goto][iridakos/goto - GitHub] from Lazarus Lazaridis. His tool is awesome and has features mine does not have. I highly recommend reviewing both tools as they are similar but the few differences between them might make one a better fit for you than the other.


Features
--------

1. Store long or hard to remember paths with an easy to remember alias
2. Store titles for aliases to retitle the terminal window
3. The stored paths can be dynamic:
	1. `~/path/to/target/directory` will be expanded when accessed by GoToImp at run time
	2. `$ENVIRONMENT_VARIABLE` will be expanded when accessed by GoToImp at run time
	3. `$(subshell + code)` will be run and its output used by GoToImp at run time


### Warning

Number 3 up there is potentially very dangerous as `eval` is used for the shell expansions. Therefor if someone makes changes to your `alias_db.txt` then they could potentially run any code they like (as you) if you use an alias they have tinkered with. Now, let's put things into perspective. If they were able to edit your `alias_db.txt` file then they probably already have pretty good access to your system. That does not negate the potential for harm being done by such tinkering with `alias_db.txt`. GoToImp does not create a security hole that just anyone can jump though. An attacker would need:

* Access to your system
* Knowledge that GoToImp is installed on your system
* Access to `alias_db.txt`
* Permission to edit `alias_db.txt`
* Understanding of how to edit `alias_db.txt` in a malicious fashion

None of those things are insurmountable for a dedicated attacker. But it is also highly unlikely. Anyone who meets all of those qualifications wouldn't likely bother messing with the `alias_db.txt` except as a prank. But the warning is here so you (the user) are aware. Now if that is all too scary (no judgement here) then set the following environment variable:

```bash
export GOTO_DYNAMIC='safe'
```

This will allow for safe `~` expansion only.


Installation
------------

### Initial Setup


#### Config Setup For a Collection of Aliases Potentially Shared Between System

```bash
$ mkdir -p ~/.config
$ cd ~/.config
```


#### Local Setup For a Unique Collection of Aliases Per System

```bash
$ mkdir -p ~/.local/share
$ cd ~/.local/share
```


### Get Library Using Git

```bash
$ git clone git@github.com:runeimp/gotoimp.git
```


### Get Library Using cURL

```bash
$ curl -LO https://github.com/runeimp/gotoimp/archive/refs/tags/v0.7.0.tar.gz
$ tar xfz v0.7.0.tar.gz
$ mv gotoimp-0.7.0 gotoimp
```


### Source the Code

Add `source ~/.local/lib/gotoimp/gotoimp.bash` to your `.bash_profile`, `.profile` or whatever you personally use for such things where BASH can find it when you login, open Terminal, etc. Add it to `.bashrc` instead if you need shells scripts to use it when your not logged in.


### Test the Install

To start using it immediately and check the install do

```bash
$ exec $SHELL --login
$ goto -v
gotoimp v0.7.0
```


Usage
-----

```bash
$ goto -h
gotoimp v0.7.0

Command for storing and utilizing aliases to directories

OPTIONS:
   -a | --add <alias> <path>                    Add a alias path
  -at | --add-title <alias> <path> <title>      Add an alias path with title
   -d | --del | --delete <alias>                Delete a goto alias, including title if present
   -e | --edit                                  Display configuration paths for editing
   -h | --help                                  Display this help info
   -l | --list                                  List goto aliases
   -t | --title <alias> <title>                 Add an alias title
   -u | --up | --update                         Update a goto alias
  -ut | --update-title  <alias> <path> <title>  Update a goto alias path with title
   -v | --version                               Show the goto version

```


### Add an Alias

```bash
$ goto -a shorty /long/path/to/your/target/directory
  gotoimp 'shorty' alias added to /Users/runeimp/.local/share/gotoimp/alias_db.txt
```


### Add a Window Title to an Alias

```bash
$ goto -t shorty 'The Long Road'
  gotoimp 'The Long Road' alias title added to /Users/runeimp/.local/share/gotoimp/title_db.txt
```


### Add an Alias and Window Title at the Same Time

```bash
$ goto -at shorty /long/path/to/your/target/directory 'The Long Road'
  gotoimp 'shorty' alias added to /Users/runeimp/.local/share/gotoimp/alias_db.txt
  gotoimp 'The Long Road' alias title added to /Users/runeimp/.local/share/gotoimp/title_db.txt
```


### Add a Dynamic Alias Based on an Environment Variable or Subshell Code

#### Environment Variable Example

```bash
$ goto -at python-prefix '$PYTHON_PREFIX' 'Python Prefix'
  gotoimp 'python-prefix' alias added to /Users/runeimp/.local/share/gotoimp/alias_db.txt
  gotoimp 'Python Prefix' alias title added to /Users/runeimp/.local/share/gotoimp/title_db.txt
```

```bash
$ pwd
/Users/markgardner
$ goto python-prefix
$ pwd
/usr/local/opt/python@3.9/Frameworks/Python.framework/Versions/3.9
```

#### Subshell Code Example

```bash
$ goto -at goroot '$(go env | grep -F GOROOT --line-buffered | cut -d\" -f2)' '$GOROOT'
  gotoimp 'goroot' alias added to /Users/runeimp/.local/share/gotoimp/alias_db.txt
  gotoimp '$GOROOT' alias title added to /Users/runeimp/.local/share/gotoimp/title_db.txt
```

```bash
$ pwd
/Users/markgardner
$ goto goroot
$ pwd
/usr/local/Cellar/go/1.16.2/libexec
```

Note that in both cases the environment variable and subshell code were enclosed in single-quotes to ensure the reference was maintained and not expanded by the shell before being handed off to the goto function. This ensures that the dynamic references stay dynamic. If the variable changes or the subshell code returns a different result later goto will reflect those changes. If double-quotes or no quotes were used the reference would be expanded by the shell and the result, not the reference, would be stored by GoToImp and the goto alias would not be dynamic.


Rational
--------

I came across [iridakos/goto][iridakos/goto - GitHub] via Homebrew on my Mac and thought "This is awesome!" when I read the description. I had been looking for something like this but hadn't found the right fit yet. So I tried it. And unfortunately had several problems with it. I had some problems with it on macOS which I had fun fixing. And I'm not being sarcastic at all. It was an interesting challenge and ultimately taught me more about finagling files with BASH. Thanks for the inspiration Lazarus. Good times! :-)

Following are the main reasons I decided to roll my own:

1. [iridakos/goto][iridakos/goto - GitHub] as installed by Homebrew on macOS requires [bash-completion][scop/bash-completion - GitHub] as a dependency. As of this writing there are a few problems with that for me:
	1. [bash-completion][scop/bash-completion - GitHub] is not installed automatically as a dependency when installing [iridakos/goto][iridakos/goto - GitHub].
	2. Once manually installed [bash-completion][scop/bash-completion - GitHub] was messing with the default completions on my system under iTerm2 and Terminal.
2. [iridakos/goto][iridakos/goto - GitHub] cannot handle `~` expansion. For a single system that is no issue. Why bother storing a path with a `~` anyway. Well I share my setup between multiple computers with different login names via Dropbox and symlinks. Storing a path within my home directory on one system will not work on another as I can rarely use `runeimp` as my account name for work computers.
3. I like setting the terminal title and so added that feature as well.
4. I didn't like the parameter naming. No biggy but having the option of using parameters that were more intuitive to me makes the tool a lot easier.

Now you can simply download [`goto.sh`][iridakos/goto - GitHub] and source it into your `.bash_profile` or whatever your using. That does work. But it still doesn't fix issues 2, 3, and 4. Admittedly #4 is pretty minor. And to be honest the API isn't all that bad. It would have been easy enough to get used to. But #3 really makes me happy and #2 is a major issue for my use case.


ToDo
----

* [ ] Add fish tab completions
* [ ] Add ion tab completions
* [ ] Add ksh tab completions
* [ ] Add PowerShell tab completions?
* [ ] Add tcsh tab completions
* [ ] Add zsh tab completions




[iridakos/goto - GitHub]: https://github.com/iridakos/goto
[scop/bash-completion - GitHub]: https://github.com/scop/bash-completion
[How to make PowerShell tab completion work like Bash]: https://stackoverflow.com/questions/8264655/how-to-make-powershell-tab-completion-work-like-bash

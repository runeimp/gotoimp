GoToImp
=======

This is a BASH directory traversal enhancement inspired by [goto][iridakos/goto - GitHub] from Lazarus Lazaridis. His tool is awesome and has features mine does not. I highly recommend trying both tools as they are similar but the few differences might make one a better fit for you than the other.


Installation
------------

```bash
$ mkdir -p ~/.local/lib
$ cd ~/.local/lib
$ git clone git@github.com:runeimp/gotoimp.git
```

Then add `source ~/.local/lib/gotoimp/gotoimp.bash` to your `.bash_profile`, `.profile` or whatever you personally use for such things where BASH can find it when you login, open Terminal, etc.

To start using it immediately and check the install do

```
$ exec $SHELL --login
$ goto -v
gotoimp v0.5.0
```


Usage
-----

```bash
$ goto -h
gotoimp v0.5.0

Command for storing and utilizing aliases to directories

OPTIONS:
   -a | --add <alias> <path>                    Add a alias path
  -at | --add-title <alias> <path> <title>      Add an alias path with title
   -d | --del | --delete <alias>                Delete a goto alias
   -h | --help                                  Display this help info
   -l | --list                                  List goto aliases
   -t | --title <alias> <title>                 Add an alias title
   -u | --up | --update                         Update a goto alias
  -ut | --update-title  <alias> <path> <title>  Update a goto alias path with title
   -v | --version                               Show the goto version

```



Rational
--------

I came across [iridakos/goto][iridakos/goto - GitHub] via Homebrew on my Mac and thought "This is awesome!" when I read the description. I had been looking for something like this but hadn't found the right fit yet. So I tried it. And unfortunately had several problems with it.

I had some problems with it on macOS which I had fun fixing. And I'm not being sarcastic at all. It was an interesting challenge and ultimately taught me more about finagling files with BASH. Thanks for the insperation Lazarus. Good times! :-)

1. [iridakos/goto][iridakos/goto - GitHub] as installed by Homebrew on macOS requires [bash-completion][scop/bash-completion - GitHub] as a dependency. As of this writing there are a few problems with that for me:
	1. [bash-completion][scop/bash-completion - GitHub] is not installed automatically as a dependency when installing [iridakos/goto][iridakos/goto - GitHub].
	2. Once manually installed [bash-completion][scop/bash-completion - GitHub] was messing with the default completions on my system under iTerm2 and Terminal.
2. [iridakos/goto][iridakos/goto - GitHub] cannot handle `~` expansion. For a single system that is no issue. Why bother storing a path with a `~` anyway. Well I share my setup between multiple computers with different login names via Dropbox and symlinks. Storing a path within my home directory on one system will not work on another.
3. I like setting the terminal title and so added that feature as well.
4. I didn't like the parameter naming. No biggy but having the option of using parameters that were more intuitive to me makes the tool easier.

Now you can simply download [`goto.sh`][iridakos/goto - GitHub] and source it into your `.bash_profile` or whatever your using. That does work. But it still doesn't fix issues 2, 3, and 4. Admitedly #4 is pretty minor. And to be honest the API isn't all that bad. It would easy enough to get used to. But #3 really makes me happy and #2 is a major issue for my use case.


ToDo
----

* [ ] Add fish tab completions
* [ ] Add ion tab completions
* [ ] Add ksh tab completions
* [ ] Add PowerShell tab completions
* [ ] Add tcsh tab completions
* [ ] Add zsh tab completions




[iridakos/goto - GitHub]: https://github.com/iridakos/goto
[scop/bash-completion - GitHub]: https://github.com/scop/bash-completion
[How to make PowerShell tab completion work like Bash]: https://stackoverflow.com/questions/8264655/how-to-make-powershell-tab-completion-work-like-bash

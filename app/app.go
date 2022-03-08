package app

import (
	"fmt"
	"os"
	"strings"

	"github.com/runeimp/gotoimp/clog"
	"github.com/runeimp/gotoimp/internal/appdata"
	// "github.com/runeimp/gotoimp/internal/arguments"
)

const (
	appName    = "GoToImp"
	appVersion = "0.7.0"
	appLabel   = appName + " v" + appVersion
	cliName    = "gotoimp"
	PS         = string(os.PathSeparator)
	usage      = `
gotoimp v%s

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
   -v | --ver | --version                       Show the goto version

`
)

var appData *appdata.AppData

func Parse(args []string) (aliasID string) {
	skip := 0

	for i, arg := range args {
		clog.Debug("app.parseArgs() | i: %d | arg: %q | skip: %d", i, arg, skip)

		if skip > 0 {
			skip--
			continue
		}
		switch arg {
		case "-a", "-add", "--add":
			if i+2 >= len(args) {
				clog.Fatal("incorrect usage of %s", arg)
				os.Exit(1)
			}

			skip = i + 1
			id := args[skip]
			skip++
			path := args[skip]

			appData.AliasSet(id, path)
			clog.Debug("app.parseArgs() | i: %d | id: %q | data: %#v", i, id, appData.AliasGet(id))
		case "-at", "-add-title", "--add-title":
			if i+3 >= len(args) {
				clog.Fatal("incorrect usage of %s", arg)
				os.Exit(1)
			}

			skip = i + 1
			id := args[skip]
			skip++
			path := args[skip]
			skip++
			title := args[skip]

			appData.AliasSet(id, path, title)
			clog.Debug("app.parseArgs() | i: %d | id: %q | data: %#v", i, id, appData.AliasGet(id))
		case "-d", "-del", "--del", "-delete", "--delete":
			skip = i + 1
			id := args[skip]
			appData.AliasRemove(id)
		case "-e", "-edit", "--edit":
			fmt.Println(appData.AliasPath())
		case "-completion", "--completion":
			skip = i + 1
			if strings.ToLower(args[skip]) == "bash" {
				fmt.Println(appData.AliasListCompletion())
				os.Exit(0)
			}
		case "-h", "-help", "--help":
			clog.Debug("app.parseArgs() | -h/--help | arg: %s", arg)
			fmt.Printf(usage, appVersion)
			os.Exit(0)
		case "-l", "-list", "--list":
			appData.AliasList()
			os.Exit(0)
		case "-t", "-title", "--title":
			if i+2 >= len(args) {
				clog.Fatal("incorrect usage of %s", arg)
				os.Exit(1)
			}

			skip = i + 1
			id := args[skip]
			skip++
			path := args[skip]

			appData.AliasTitle(id, path)
			clog.Debug("app.parseArgs() | i: %d | id: %q | data: %#v", i, id, appData.AliasGet(id))
		case "-u", "-up", "--up", "-update", "--update":
			if i+2 >= len(args) {
				clog.Fatal("incorrect usage of %s", arg)
				os.Exit(1)
			}

			skip = i + 1
			id := args[skip]
			skip++
			path := args[skip]

			appData.AliasUpdate(id, path)
		case "-ut", "-update-title", "--update-title":
			if i+3 >= len(args) {
				clog.Fatal("incorrect usage of %s", arg)
				os.Exit(1)
			}

			skip = i + 1
			id := args[skip]
			skip++
			path := args[skip]
			skip++
			title := args[skip]

			appData.AliasUpdateTitle(id, path, title)
		case "-v", "-ver", "--ver", "-version", "--version":
			fmt.Println(appLabel)
			os.Exit(0)
		default:
			aliasID = arg
			clog.Debug("arguments.Parse() | aliasID: %q", aliasID)
		}
	}

	return aliasID
}

func Run(args []string) {
	clog.DebugLevel = clog.DebugLevelInfo
	clog.Debug("app.Run() | len(args): %d", len(args))
	clog.Debug("app.Run() | args: %q", args)

	appData = appdata.New(appName, cliName, appVersion)
	id := Parse(args)
	clog.Debug("app.Run() | id: %q", id)

	if id != "" {
		v := appData.AliasGet(id)
		clog.Debug("app.Run() | appData.AliasGet(%q): %#v", id, v)
		if v.Title != "" {
			fmt.Printf("%s	%s\n", v.ParsedPath(), v.Title)
		} else {
			fmt.Println(v.ParsedPath())
		}
	}

	clog.Debug("app.Run() | appData.ConfigPath(): %q", appData.ConfigPath())
	clog.Debug("app.Run() | appData.AliasPath(): %q", appData.AliasPath())
	// clog.Debug("app.parseArgs() | i: %d | id: %q | data: %#v", i, id, appData.AliasGet(id))

	err := appData.AliasDataSave()
	if err != nil && err.Error() != "no config data to save" {
		clog.Error("app.Run() | appData.AliasDataSave() | err: %v", err)
	}
}

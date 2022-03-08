package appdata

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"sort"
	"strings"

	"github.com/runeimp/gotoimp/clog"
)

const PS = string(os.PathSeparator)

type AliasData struct {
	ID    string `json:"id"`
	Path  string `json:"path"`
	Title string `json:"title"`
}

func (ad AliasData) ParsedPath() string {
	if len(ad.Path) > 0 {
		switch ad.Path[0:1] {
		case "~":
			home, err := os.UserHomeDir()
			if err != nil {
				clog.Fatal(err)
			}
			if len(ad.Path) > 1 {
				return home + ad.Path[1:]
			}
			return home
		}
	}

	return ad.Path
}

type AppData struct {
	aliasData      map[string]AliasData
	aliasPath      string
	CLI            string
	DataChanged    bool
	Name           string
	Version        string
	configPath     string
	configVerified bool
}

func (ad *AppData) AliasGet(id string) *AliasData {
	if v, ok := ad.aliasData[id]; ok {
		return &v
	}

	return nil
}

func (ad *AppData) AliasSet(id, path string, title ...string) {
	if len(title) > 0 {
		ad.aliasData[id] = AliasData{
			ID:    id,
			Path:  path,
			Title: title[0],
		}
		// ad.aliasData[id].Title = title[0]
	} else {
		ad.aliasData[id] = AliasData{
			ID:   id,
			Path: path,
		}
	}
	ad.DataChanged = true
}

func (ad *AppData) AliasDataLoad() (err error) {
	clog.Debug("app.AppData.AliasDataLoad() | ad.configVerified: %t | dataLength: %d", ad.configVerified, len(ad.aliasData))
	if ad.configVerified {
		isDir := false
		if IsPathFound(ad.aliasPath, isDir) {
			var jsonBytes []byte
			jsonBytes, err = os.ReadFile(ad.aliasPath)
			if err != nil {
				return err
			}
			json.Unmarshal(jsonBytes, &ad.aliasData)
		}
	}

	return err
}

// AliasDataSave writes any alias data to disk
func (ad *AppData) AliasDataSave() (err error) {
	clog.Debug("app.AppData.AliasDataSave() | ad.configVerified: %t | ad.DataChanged: %t", ad.configVerified, ad.DataChanged)
	if ad.configVerified {
		if ad.DataChanged {
			if err != nil {
				clog.Error("alias loading error: %v", err)
				return err
			}
			var jsonBytes []byte
			jsonBytes, err = json.MarshalIndent(&ad.aliasData, "", "    ")
			clog.Debug("app.AppData.AliasDataSave() | string(jsonBytes):\n%s", string(jsonBytes))
			err = os.WriteFile(ad.aliasPath, jsonBytes, 0600)
		} else {
			err = fmt.Errorf("no config data to save")
		}
	} else {
		err = fmt.Errorf("app config path not verified")
	}

	return err
}

func (ad *AppData) AliasList() {
	var list []string
	for id, _ := range ad.aliasData {
		list = append(list, id)
	}
	sort.Strings(list)

	maxID := 0
	maxPath := 0
	maxTitle := 0

	for _, id := range list {
		d := ad.aliasData[id]
		if len(d.ID) > maxID {
			maxID = len(d.ID)
		}
		if len(d.Path) > maxPath {
			maxPath = len(d.Path)
		}
		if len(d.Title) > maxTitle {
			maxTitle = len(d.Title)
		}
	}

	if len("Alias ID") > maxID {
		maxID = len("Alias ID")
	}

	rowFormat := fmt.Sprintf("%%-%ds | ", maxID)
	rowFormat += fmt.Sprintf("%%-%ds | ", maxPath)
	rowFormat += fmt.Sprintf("%%-%ds\n", maxTitle)

	fmt.Println()
	// fmt.Println(rowFormat)
	fmt.Printf(rowFormat, "Alias ID", "Path", "Title")
	fmt.Printf(rowFormat, strings.Repeat("-", maxID), strings.Repeat("-", maxPath), strings.Repeat("-", maxTitle))

	for _, id := range list {
		d := ad.aliasData[id]
		fmt.Printf(rowFormat, d.ID, d.Path, d.Title)
	}
	fmt.Println()
}

func (ad *AppData) AliasListCompletion() (list string) {
	var s []string
	for id, _ := range ad.aliasData {
		s = append(s, id)
	}
	sort.Strings(s)

	for _, w := range s {
		list += " " + w
	}

	return list[1:]
}

func (ad *AppData) AliasPath() string {
	clog.Debug(`appdata.AppData.AliasPath() | ad.aliasPath: "%s"`, ad.aliasPath)
	return ad.aliasPath
}

func (ad *AppData) AliasRemove(id string) {
	delete(ad.aliasData, id)
	ad.DataChanged = true
}

func (ad *AppData) AliasTitle(id, title string) {
	if aliasData, ok := ad.aliasData[id]; ok {
		aliasData.Title = title
		ad.aliasData[id] = aliasData
		ad.DataChanged = true
	}
}

func (ad *AppData) AliasUpdate(id, path string) {
	if aliasData, ok := ad.aliasData[id]; ok {
		aliasData.Path = path
		ad.aliasData[id] = aliasData
		ad.DataChanged = true
	}
}

func (ad *AppData) AliasUpdateTitle(id, path, title string) {
	if aliasData, ok := ad.aliasData[id]; ok {
		aliasData.Path = path
		aliasData.Title = title
		ad.aliasData[id] = aliasData
		ad.DataChanged = true
	}
}

// Check and create the apps config path
func (ad *AppData) ConfigPath() string {
	clog.Debug(`appdata.AppData.ConfigPath() | configPath: "%s" | configVerified: %t`, ad.configPath, ad.configVerified)
	clog.Debug(`appdata.AppData.ConfigPath() | aliasPath: "%s"`, ad.aliasPath)
	if ad.configVerified {
		return ad.configPath
	}

	var err error

	if xdgConfigHome, ok := os.LookupEnv("XDG_CONFIG_HOME"); ok {
		clog.Debug("appdata.AppData.ConfigPath() | xdgConfigHome: %q | ok: %t", xdgConfigHome, ok)
		ad.configPath = xdgConfigHome + PS + ad.CLI
	} else {
		clog.Info("appdata.AppData.ConfigPath() | xdgConfigHome: %q | ok: %t", xdgConfigHome, ok)

		ad.configPath, err = os.UserConfigDir()
		if err != nil {
			clog.Fatal("User Config Error: %v", err)
		}
		ad.configPath += PS + ad.Name
	}

	isDir := true
	if IsPathFound(ad.configPath, isDir) {
		ad.configVerified = true
	} else {
		clog.Info(`appdata.AppData.ConfigPath() | Creating configuration path: "%s"`, ad.configPath)
		err = os.MkdirAll(ad.configPath, 0700)
		if err != nil {
			clog.Error("error: creation of configuration path failed")
			clog.Error("defaulting to the current working directory for configuration files")
		} else {
			ad.configVerified = true
		}
	}

	ad.aliasPath = ad.configPath + PS + "alias-db.json"
	clog.Debug("appdata.AppData.ConfigPath() | ad.configVerified: %t", ad.configVerified)
	clog.Debug(`appdata.AppData.ConfigPath() | ad.aliasPath: "%s"`, ad.aliasPath)

	return ad.configPath
}

func New(name, cli, ver string) *AppData {
	clog.Debug("appdata.New() | name: %q | cli: %q | ver: %q", name, cli, ver)
	ad := &AppData{
		aliasData: make(map[string]AliasData),
		CLI:       cli,
		Name:      name,
		Version:   ver,
	}

	ad.ConfigPath()

	ad.AliasDataLoad()

	return ad
}

// IsPathFound checks if a path exists and if it exists if it is or is-not a directory
func IsPathFound(p string, isDir bool) (result bool) {
	fileStat, err := os.Stat(p)
	if err == nil {
		result = true
	} else {
		// Schrodinger: file may or may not exist
		result = errors.Is(err, os.ErrExist)
	}

	if result && isDir != fileStat.IsDir() {
		result = false
	}

	return result
}

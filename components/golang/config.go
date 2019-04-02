package main

import (
	"fmt"
	// "io/ioutil"
	"os"
	"os/user"
	"path/filepath"

	toml "github.com/BurntSushi/toml"
)

type configWrapper struct {
	Config Configuration `toml:"chef_license"`
}

// Configuration TODO
type Configuration struct {
	ReadPaths   []string `toml:"read_paths"`
	PersistPath string   `toml:"persist_path"`
	Persist     bool
}

// LoadConfig TODO
func LoadConfig() Configuration {
	location, set := os.LookupEnv("CHEF_LICENSE_CONFIG")
	if set == false {
		location = "./config/development.toml"
	}
	// We default Persist to true because the zero value of boolean is false
	cw := configWrapper{Config: Configuration{Persist: true}}
	if _, err := toml.DecodeFile(location, &cw); err != nil {
		fmt.Println("Could not load config file")
		os.Exit(172)
	}
	var config = cw.Config

	if len(config.ReadPaths) == 0 {
		config.ReadPaths = append(config.ReadPaths, "/etc/chef/accepted_licenses")
		if currentUser := GetCurrentUser(); currentUser.Uid != "0" {
			config.ReadPaths = append(config.ReadPaths, filepath.Join(currentUser.HomeDir, ".chef/accepted_licenses"))
		}
	}

	if config.PersistPath == "" {
		if currentUser := GetCurrentUser(); currentUser.Uid == "0" {
			config.PersistPath = "/etc/chef/accepted_licenses"
		} else {
			config.PersistPath = filepath.Join(currentUser.HomeDir, ".chef/accepted_licenses")
		}
	}
	return config
}

// GetCurrentUser - wrapper function for looking up the current user and failing
// if it cannot be looked up
func GetCurrentUser() *user.User {
	currentUser, err := user.Current()
	if err != nil {
		fmt.Println("Could not look up current user")
		os.Exit(172)
	}
	return currentUser
}

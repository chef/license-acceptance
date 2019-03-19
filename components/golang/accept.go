package main // import "github.com/chef/license-acceptance"

import (
	"fmt"
	"os"
	"time"
)

func main() {
	if len(os.Args) != 4 {
		fmt.Println("3 required arguments: acceptance 'true', habitat package id and habitat package version")
		os.Exit(172)
	}

	acceptance := os.Args[1]
	habPkgID := os.Args[2]
	version := os.Args[3]

	config := LoadConfig()
	productInfo := ReadProductInfo()

	if acceptance == "undefined" {
		// Attempt to read from existing marker files
		missingLicenses := make([]Product, 0)
		requiredLicenses := productInfo.RequiredProductLicenses(habPkgID)
		for _, product := range requiredLicenses {
			if !HasAcceptedLicense(config, product) {
				missingLicenses = append(missingLicenses, product)
			}
		}
		if len(missingLicenses) > 0 {
			fmt.Println("Can not start application without accepting license")
			os.Exit(172)
		}
	} else if acceptance == "true" {
		// attempt to write persistence - do not fail if we cannot
		requiredLicenses := productInfo.RequiredProductLicenses(habPkgID)
		acceptingProduct := requiredLicenses[0]
		for _, product := range requiredLicenses {
			AttemptPersistLicense(config, product, time.Now(), acceptingProduct.Name, version, GetCurrentUser().Username)
		}
	} else {
		fmt.Println("Can not start application without accepting license")
		os.Exit(172)
	}
}

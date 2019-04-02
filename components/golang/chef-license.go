package main // import "github.com/chef/license-acceptance"

import (
	"fmt"
	"os"
	"strings"
	"time"
)

func main() {
	if len(os.Args) != 4 {
		fmt.Println("3 required arguments: 'accept', habitat package id, habitat package version")
		os.Exit(172)
	}

	acceptance := os.Args[1]
	habPkgID := os.Args[2]
	version := os.Args[3]

	config := LoadConfig()
	productInfo := ReadProductInfo()

	if acceptance == "accept" && config.Persist == true {
		// attempt to write persistence - do not fail if we cannot
		requiredLicenses := productInfo.RequiredProductLicenses(habPkgID)
		acceptingProduct := requiredLicenses[0]
		numPersisted := 0
		for _, product := range requiredLicenses {
			numPersisted += AttemptPersistLicense(config, product, time.Now(), acceptingProduct.Name, version, GetCurrentUser().Username)
		}
		if numPersisted > 0 {
			s := ""
			if numPersisted > 1 {
				s = "s"
			}
			out := "+---------------------------------------------+\n" +
				"%d product license%s accepted.\n" +
				"+---------------------------------------------+\n"
			fmt.Printf(out, numPersisted, s)
		}
	} else if acceptance != "accept" {
		// Attempt to read from existing marker files
		missingLicenses := make([]Product, 0)
		requiredLicenses := productInfo.RequiredProductLicenses(habPkgID)
		for _, product := range requiredLicenses {
			if !HasAcceptedLicense(config, product) {
				missingLicenses = append(missingLicenses, product)
			}
		}
		if len(missingLicenses) > 0 {
			s := ""
			if len(missingLicenses) > 1 {
				s = "s"
			}
			header := `+---------------------------------------------+
            Chef License Acceptance

Before you can continue, %d product license%s
must be accepted. View the license at
https://www.chef.io/end-user-license-agreement/

License%s that need accepting:`

			var msg strings.Builder
			fmt.Fprintf(&msg, header, len(missingLicenses), s, s)

			for _, l := range missingLicenses {
				fmt.Fprintf(&msg, "\n  * %s", l.HabPkgID)
			}

			fmt.Fprint(&msg, "\n\n")
			footer := `If you do not accept this license you will
not be able to use Chef products.
+---------------------------------------------+
`
			fmt.Fprint(&msg, footer)

			fmt.Print(msg.String())
			os.Exit(172)
		}
	}
}

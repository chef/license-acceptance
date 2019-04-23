package main // import "github.com/chef/license-acceptance"

import (
	"fmt"
	"os"
	"time"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("1 required argument")
		os.Exit(172)
	}

	acceptance := os.Args[1]
	if acceptance != "accept" {
		msg := `+---------------------------------------------+
            Chef License Acceptance

Before you can continue, you must accept the Chef
End User License Agreement. View the license at
https://www.chef.io/end-user-license-agreement/
+---------------------------------------------+
`

		fmt.Print(msg)
		// We sleep when the user has not yet accepted the license so their Habitat
		// log isn't filled with messages about the service failing then getting
		// restarted immediately.
		time.Sleep(60 * time.Second)
		os.Exit(172)
	}
	os.Exit(0)
}

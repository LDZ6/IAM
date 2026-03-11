
// iamctl is the command line tool for iam platform.
package main

import (
	"os"

	"github.com/LDZ6/iam/internal/iamctl/cmd"
)

func main() {
	command := cmd.NewDefaultIAMCtlCommand()
	if err := command.Execute(); err != nil {
		os.Exit(1)
	}
}

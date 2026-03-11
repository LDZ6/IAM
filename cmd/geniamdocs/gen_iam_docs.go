
package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra/doc"

	"github.com/LDZ6/iam/internal/apiserver"
	"github.com/LDZ6/iam/internal/authzserver"
	"github.com/LDZ6/iam/internal/iamctl/cmd"
	"github.com/LDZ6/iam/internal/pump"
	"github.com/LDZ6/iam/internal/watcher"
	"github.com/LDZ6/iam/pkg/util/genutil"
)

func main() {
	// use os.Args instead of "flags" because "flags" will mess up the man pages!
	path, module := "", ""
	if len(os.Args) == 3 {
		path = os.Args[1]
		module = os.Args[2]
	} else {
		fmt.Fprintf(os.Stderr, "usage: %s [output directory] [module] \n", os.Args[0])
		os.Exit(1)
	}

	outDir, err := genutil.OutDir(path)
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to get output directory: %v\n", err)
		os.Exit(1)
	}

	switch module {
	case "iam-apiserver":
		// generate docs for iam-apiserver
		apiServer := apiserver.NewApp("iam-apiserver").Command()
		_ = doc.GenMarkdownTree(apiServer, outDir)
	case "iam-authz-server":
		// generate docs for iam-authz-server
		authzServer := authzserver.NewApp("iam-authz-server").Command()
		_ = doc.GenMarkdownTree(authzServer, outDir)
	case "iam-pump":
		// generate docs for iam-pump
		iamPump := pump.NewApp("iam-pump").Command()
		_ = doc.GenMarkdownTree(iamPump, outDir)
	case "iam-watcher":
		// generate docs for iam-watcher
		iamWatcher := watcher.NewApp("iam-watcher").Command()
		_ = doc.GenMarkdownTree(iamWatcher, outDir)
	case "iamctl":
		// generate docs for iamctl
		iamctl := cmd.NewDefaultIAMCtlCommand()
		_ = doc.GenMarkdownTree(iamctl, outDir)
	default:
		fmt.Fprintf(os.Stderr, "Module %s is not supported", module)
		os.Exit(1)
	}
}

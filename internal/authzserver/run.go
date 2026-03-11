
package authzserver

import (
	"github.com/LDZ6/iam/internal/authzserver/config"
)

// Run runs the specified AuthzServer. This should never exit.
func Run(cfg *config.Config) error {
	server, err := createAuthzServer(cfg)
	if err != nil {
		return err
	}

	return server.PrepareRun().Run()
}

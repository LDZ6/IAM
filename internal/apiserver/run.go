
package apiserver

import "github.com/LDZ6/iam/internal/apiserver/config"

// Run runs the specified APIServer. This should never exit.
func Run(cfg *config.Config) error {
	server, err := createAPIServer(cfg)
	if err != nil {
		return err
	}

	return server.PrepareRun().Run()
}

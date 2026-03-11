
package pump

import (
	genericapiserver "github.com/LDZ6/iam/internal/pkg/server"
	"github.com/LDZ6/iam/internal/pump/config"
)

// Run runs the specified pump server. This should never exit.
func Run(cfg *config.Config, stopCh <-chan struct{}) error {
	go genericapiserver.ServeHealthCheck(cfg.HealthCheckPath, cfg.HealthCheckAddress)

	server, err := createPumpServer(cfg)
	if err != nil {
		return err
	}

	return server.PrepareRun().Run(stopCh)
}

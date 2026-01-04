
package watcher

import (
	genericapiserver "github.com/marmotedu/iam/internal/pkg/server"
	"github.com/marmotedu/iam/internal/watcher/config"
)

// Run runs the specified pump server. This should never exit.
func Run(cfg *config.Config) error {
	go genericapiserver.ServeHealthCheck(cfg.HealthCheckPath, cfg.HealthCheckAddress)

	return createWatcherServer(cfg).PrepareRun().Run()
}

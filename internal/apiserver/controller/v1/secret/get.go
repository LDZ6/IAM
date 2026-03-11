
package secret

import (
	"github.com/gin-gonic/gin"
	"github.com/LDZ6/component-base/pkg/core"
	metav1 "github.com/LDZ6/component-base/pkg/meta/v1"

	"github.com/LDZ6/iam/internal/pkg/middleware"
	"github.com/LDZ6/iam/pkg/log"
)

// Get get an policy by the secret identifier.
func (s *SecretController) Get(c *gin.Context) {
	log.L(c).Info("get secret function called.")

	secret, err := s.srv.Secrets().Get(c, c.GetString(middleware.UsernameKey), c.Param("name"), metav1.GetOptions{})
	if err != nil {
		core.WriteResponse(c, err, nil)

		return
	}

	core.WriteResponse(c, nil, secret)
}

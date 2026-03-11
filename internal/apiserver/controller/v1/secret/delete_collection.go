
package secret

import (
	"github.com/gin-gonic/gin"
	"github.com/LDZ6/component-base/pkg/core"
	metav1 "github.com/LDZ6/component-base/pkg/meta/v1"

	"github.com/LDZ6/iam/internal/pkg/middleware"
	"github.com/LDZ6/iam/pkg/log"
)

// DeleteCollection delete secrets by secret names.
func (s *SecretController) DeleteCollection(c *gin.Context) {
	log.L(c).Info("batch delete policy function called.")

	if err := s.srv.Secrets().DeleteCollection(
		c,
		c.GetString(middleware.UsernameKey),
		c.QueryArray("name"),
		metav1.DeleteOptions{},
	); err != nil {
		core.WriteResponse(c, err, nil)

		return
	}

	core.WriteResponse(c, nil, nil)
}

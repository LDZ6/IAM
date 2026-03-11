
package secret

import (
	"github.com/gin-gonic/gin"
	"github.com/LDZ6/component-base/pkg/core"
	metav1 "github.com/LDZ6/component-base/pkg/meta/v1"

	"github.com/LDZ6/iam/internal/pkg/middleware"
	"github.com/LDZ6/iam/pkg/log"
)

// Delete delete a secret by the secret identifier.
func (s *SecretController) Delete(c *gin.Context) {
	log.L(c).Info("delete secret function called.")
	opts := metav1.DeleteOptions{Unscoped: true}
	if err := s.srv.Secrets().Delete(c, c.GetString(middleware.UsernameKey), c.Param("name"), opts); err != nil {
		core.WriteResponse(c, err, nil)

		return
	}

	core.WriteResponse(c, nil, nil)
}

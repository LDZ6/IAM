
package policy

import (
	"github.com/gin-gonic/gin"
	"github.com/LDZ6/component-base/pkg/core"
	metav1 "github.com/LDZ6/component-base/pkg/meta/v1"

	"github.com/LDZ6/iam/internal/pkg/middleware"
	"github.com/LDZ6/iam/pkg/log"
)

// Delete deletes the policy by the policy identifier.
func (p *PolicyController) Delete(c *gin.Context) {
	log.L(c).Info("delete policy function called.")

	if err := p.srv.Policies().Delete(c, c.GetString(middleware.UsernameKey), c.Param("name"),
		metav1.DeleteOptions{}); err != nil {
		core.WriteResponse(c, err, nil)

		return
	}

	core.WriteResponse(c, nil, nil)
}


package policy

import (
	"github.com/gin-gonic/gin"
	"github.com/LDZ6/component-base/pkg/core"
	metav1 "github.com/LDZ6/component-base/pkg/meta/v1"
	"github.com/LDZ6/errors"

	"github.com/LDZ6/iam/internal/pkg/code"
	"github.com/LDZ6/iam/internal/pkg/middleware"
	"github.com/LDZ6/iam/pkg/log"
)

// List return all policies.
func (p *PolicyController) List(c *gin.Context) {
	log.L(c).Info("list policy function called.")

	var r metav1.ListOptions
	if err := c.ShouldBindQuery(&r); err != nil {
		core.WriteResponse(c, errors.WithCode(code.ErrBind, err.Error()), nil)

		return
	}

	policies, err := p.srv.Policies().List(c, c.GetString(middleware.UsernameKey), r)
	if err != nil {
		core.WriteResponse(c, err, nil)

		return
	}

	core.WriteResponse(c, nil, policies)
}

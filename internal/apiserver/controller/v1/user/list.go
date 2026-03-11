
package user

import (
	"github.com/gin-gonic/gin"
	"github.com/LDZ6/component-base/pkg/core"
	metav1 "github.com/LDZ6/component-base/pkg/meta/v1"
	"github.com/LDZ6/errors"

	"github.com/LDZ6/iam/internal/pkg/code"
	"github.com/LDZ6/iam/pkg/log"
)

// List list the users in the storage.
// Only administrator can call this function.
func (u *UserController) List(c *gin.Context) {
	log.L(c).Info("list user function called.")

	var r metav1.ListOptions
	if err := c.ShouldBindQuery(&r); err != nil {
		core.WriteResponse(c, errors.WithCode(code.ErrBind, err.Error()), nil)

		return
	}

	users, err := u.srv.Users().List(c, r)
	if err != nil {
		core.WriteResponse(c, err, nil)

		return
	}

	core.WriteResponse(c, nil, users)
}

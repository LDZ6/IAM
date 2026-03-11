
// Package authorize implements the authorize handlers.
package authorize

import (
	"github.com/gin-gonic/gin"
	"github.com/LDZ6/component-base/pkg/core"
	"github.com/LDZ6/errors"
	"github.com/ory/ladon"

	"github.com/LDZ6/iam/internal/authzserver/authorization"
	"github.com/LDZ6/iam/internal/authzserver/authorization/authorizer"
	"github.com/LDZ6/iam/internal/pkg/code"
)

// AuthzController create a authorize handler used to handle authorize request.
type AuthzController struct {
	store authorizer.PolicyGetter
}

// NewAuthzController creates a authorize handler.
func NewAuthzController(store authorizer.PolicyGetter) *AuthzController {
	return &AuthzController{
		store: store,
	}
}

// Authorize returns whether a request is allow or deny to access a resource and do some action
// under specified condition.
func (a *AuthzController) Authorize(c *gin.Context) {
	var r ladon.Request
	if err := c.ShouldBind(&r); err != nil {
		core.WriteResponse(c, errors.WithCode(code.ErrBind, err.Error()), nil)

		return
	}

	auth := authorization.NewAuthorizer(authorizer.NewAuthorization(a.store))
	if r.Context == nil {
		r.Context = ladon.Context{}
	}

	r.Context["username"] = c.GetString("username")
	rsp := auth.Authorize(&r)

	core.WriteResponse(c, nil, rsp)
}

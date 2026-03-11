
package secret

import (
	"github.com/AlekSi/pointer"
	"github.com/gin-gonic/gin"
	v1 "github.com/LDZ6/api/apiserver/v1"
	"github.com/LDZ6/component-base/pkg/core"
	metav1 "github.com/LDZ6/component-base/pkg/meta/v1"
	"github.com/LDZ6/component-base/pkg/util/idutil"
	"github.com/LDZ6/errors"

	"github.com/LDZ6/iam/internal/pkg/code"
	"github.com/LDZ6/iam/internal/pkg/middleware"
	"github.com/LDZ6/iam/pkg/log"
)

const maxSecretCount = 10

// Create add new secret key pairs to the storage.
func (s *SecretController) Create(c *gin.Context) {
	log.L(c).Info("create secret function called.")

	var r v1.Secret

	if err := c.ShouldBindJSON(&r); err != nil {
		core.WriteResponse(c, errors.WithCode(code.ErrBind, err.Error()), nil)

		return
	}

	if errs := r.Validate(); len(errs) != 0 {
		core.WriteResponse(c, errors.WithCode(code.ErrValidation, errs.ToAggregate().Error()), nil)

		return
	}

	username := c.GetString(middleware.UsernameKey)

	secrets, err := s.srv.Secrets().List(c, username, metav1.ListOptions{
		Offset: pointer.ToInt64(0),
		Limit:  pointer.ToInt64(-1),
	})
	if err != nil {
		core.WriteResponse(c, err, nil)

		return
	}

	if secrets.TotalCount >= maxSecretCount {
		core.WriteResponse(c, errors.WithCode(code.ErrReachMaxCount, "secret count: %d", secrets.TotalCount), nil)

		return
	}

	// must reassign username
	r.Username = username

	// generate secret id and secret key
	r.SecretID = idutil.NewSecretID()
	r.SecretKey = idutil.NewSecretKey()

	if err := s.srv.Secrets().Create(c, &r, metav1.CreateOptions{}); err != nil {
		core.WriteResponse(c, err, nil)

		return
	}

	core.WriteResponse(c, nil, r)
}

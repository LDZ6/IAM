
// Package jwt can be used to sign/show/verify jwt token with given secretID and secretKey.
package jwt

import (
	"github.com/spf13/cobra"

	cmdutil "github.com/marmotedu/iam/internal/iamctl/cmd/util"
	"github.com/marmotedu/iam/internal/iamctl/util/templates"
	"github.com/marmotedu/iam/pkg/cli/genericclioptions"
)

var jwtLong = templates.LongDesc(`
	JWT command.

	This commands is used to sigin/show/verify jwt token.`)

// NewCmdJWT returns new initialized instance of 'jwt' sub command.
func NewCmdJWT(f cmdutil.Factory, ioStreams genericclioptions.IOStreams) *cobra.Command {
	cmd := &cobra.Command{
		Use:                   "jwt SUBCOMMAND",
		DisableFlagsInUseLine: true,
		Short:                 "JWT command-line tool",
		Long:                  jwtLong,
		Run:                   cmdutil.DefaultSubCommandRun(ioStreams.ErrOut),
	}

	// add subcommands
	cmd.AddCommand(NewCmdSign(f, ioStreams))
	cmd.AddCommand(NewCmdShow(f, ioStreams))
	cmd.AddCommand(NewCmdVerify(f, ioStreams))

	return cmd
}

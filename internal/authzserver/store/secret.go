
package store

import pb "github.com/LDZ6/api/proto/apiserver/v1"

// SecretStore defines the secret storage interface.
type SecretStore interface {
	// List(ctx context.Context, username string, opts metav1.ListOptions) (*v1.SecretList, error)
	List() (map[string]*pb.SecretInfo, error)
}

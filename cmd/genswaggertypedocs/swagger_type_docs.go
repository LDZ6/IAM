
package main

//go:generate swagger generate spec -o ../../api/swagger/swagger.yaml --scan-models

import (
	_ "github.com/marmotedu/iam/api/swagger/docs"
)

func main() {
}

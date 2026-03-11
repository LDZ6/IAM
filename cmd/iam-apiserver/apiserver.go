package main

import (
	"math/rand"
	"time"

	_ "go.uber.org/automaxprocs"

	_ "go.uber.org/automaxprocs"

	"github.com/LDZ6/iam/internal/apiserver"
)

func main() {
	rand.Seed(time.Now().UTC().UnixNano())
	apiserver.NewApp("iam-apiserver").Run()
}

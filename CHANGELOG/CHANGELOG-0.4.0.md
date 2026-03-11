
<a name="v0.4.0"></a>
## [v0.4.0](https://github.com/LDZ6/iam/compare/v0.3.1...v0.4.0) (2021-02-04)

### Bug Fixes

* fix default ConfigFlags

### Code Refactoring

* optimize log output
* iamctl code match LDZ6-sdk-go sdk changes
* optimize variable name
* change encoding/json to jsoniter
* create mysql/etcd storage in singleton mode
* fix golangci-lint error
* change datastore.go to fake.go
* remove short flag `s` in generated demo command
* **authzserver:** refactor authzserver storage code

### Features

* add --outdir option for iamctl new command


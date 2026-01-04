# IAM - Enterprise-Grade Identity and Access Management System

<div align="center">

![Go Version](https://img.shields.io/badge/Go-1.21.4-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![Release](https://img.shields.io/badge/Release-v1.7.0-orange.svg)
[![Go Report Card](https://goreportcard.com/badge/github.com/marmotedu/iam)](https://goreportcard.com/report/github.com/marmotedu/iam)

**A powerful and scalable enterprise-grade Identity and Access Management (IAM) solution**

[Features](#features) • [Quick Start](#quick-start) • [Architecture](#architecture) • [Documentation](#documentation) • [Contributing](#contributing)

</div>

---

## 📖 Introduction

IAM (Identity and Access Management) is an enterprise-grade identity and access management system developed in Go. The system provides comprehensive user management, secret key management, policy management, and resource authorization capabilities, suitable for unified authentication and authorization scenarios in microservice architectures.

### Core Advantages

- 🏢 **Enterprise-Grade Design**: Complete production deployment solution with high availability and horizontal scaling support
- 🔐 **Secure and Reliable**: JWT-based authentication with multiple authorization policy models
- 🚀 **High Performance**: Optimized with Redis caching, database connection pooling, and other techniques for high concurrency
- 🔧 **Easy to Extend**: Modular design with clear code structure for easy secondary development
- 📊 **Comprehensive Monitoring**: Built-in audit logging, performance monitoring, and data analysis
- 🛠️ **Developer Friendly**: Complete RESTful API, SDK, and command-line tools

---

## 🎯 Features

### Core Capabilities

- **User Management**
  - User registration, login, and logout
  - User information management and password modification
  - User permissions and role management

- **Secret Key Management**
  - Secret key pair (SecretID/SecretKey) creation and management
  - Automatic secret key rotation and expiration management
  - API access authentication based on secret keys

- **Policy Management**
  - Flexible policy definition (JSON format supported)
  - Access control based on resources, actions, and conditions
  - Policy versioning and auditing

- **Authorization Management**
  - RESTful resource authorization
  - Ladon policy engine integration
  - Fine-grained permission control

### System Components

| Component | Description |
|-----------|-------------|
| **iam-apiserver** | RESTful API server providing CRUD interfaces for users, secrets, and policies |
| **iam-authz-server** | Authorization server providing resource authorization functionality |
| **iam-pump** | Data analysis and audit service, processing authorization logs and storing them in the database |
| **iam-watcher** | Cache synchronization service, syncing iam-apiserver data to Redis |
| **iamctl** | Command-line tool for interacting with the IAM system |

### Technical Features

- ✅ RESTful API design compliant with OpenAPI 3.0 specification
- ✅ gRPC service support for high-performance RPC calls
- ✅ Complete authentication mechanisms (Basic Auth, Bearer Token)
- ✅ Distributed caching (Redis) support
- ✅ Database support (MySQL/MariaDB)
- ✅ Hierarchical and structured logging
- ✅ Graceful shutdown and signal handling
- ✅ Prometheus monitoring metrics
- ✅ Performance profiling (pprof) support
- ✅ Automatic Swagger documentation generation

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Client Layer                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐         │
│  │   Web    │  │   SDK    │  │  iamctl  │  │3rd Party │         │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘         │
└────────────────────────┬────────────────────────────────────────┘
                         │
         ┌───────────────┴────────────────┐
         │                                │
┌────────▼────────┐             ┌────────▼──────────┐
│  iam-apiserver  │             │ iam-authz-server  │
│  (REST API)     │             │  (Authorization)  │
└────────┬────────┘             └────────┬──────────┘
         │                               │
         │      ┌──────────────┐         │
         ├──────┤ iam-watcher  │─────────┤
         │      │   (Sync)     │         │
         │      └──────────────┘         │
         │                               │
         │      ┌──────────────┐         │
         └──────┤  iam-pump    │◄────────┘
                │ (Analytics)  │
                └──────┬───────┘
                       │
         ┌─────────────┴─────────────┐
         │                           │
┌────────▼────────┐         ┌────────▼────────┐
│   MySQL/MariaDB │         │      Redis      │
│   (Persistent)  │         │     (Cache)     │
└─────────────────┘         └─────────────────┘
```

### Data Flow Description

1. **User Management Flow**: Client → iam-apiserver → MySQL
2. **Authorization Flow**: Client → iam-authz-server → Redis → Authorization Decision
3. **Cache Synchronization**: iam-apiserver → iam-watcher → Redis
4. **Audit Logging**: iam-authz-server → iam-pump → MySQL

---

## 🚀 Quick Start

### Requirements

- Go 1.21.4+
- MySQL 5.7+ / MariaDB 10.3+
- Redis 5.0+
- Linux or macOS (CentOS 8.x recommended)

### One-Click Installation

```bash
# 1. Clone the repository
git clone https://github.com/marmotedu/iam.git
cd iam

# 2. Set environment variables
export IAM_ROOT=$(pwd)
export IAM_INSTALL_DIR=/opt/iam
export IAM_CONFIG_DIR=/etc/iam
export IAM_DATA_DIR=/data/iam
export IAM_LOG_DIR=/var/log/iam

# 3. Run the installation script
./scripts/install/install.sh iam::install::install

# 4. Start services
systemctl start iam-apiserver
systemctl start iam-authz-server
systemctl start iam-pump
systemctl start iam-watcher
```

### Verify Installation

```bash
# Check service status
systemctl status iam-apiserver
systemctl status iam-authz-server

# Test with iamctl
iamctl user list
```

### Docker Deployment

```bash
# Build images
make image

# Start services (using docker-compose)
cd deployments
docker-compose up -d

# Check service status
docker-compose ps
```

---

## 📚 Documentation

### Installation Guide

- [Complete Installation Guide](docs/guide/zh-CN/installation/06_安装和配置IAM系统.md)
- [Dependency Installation](docs/guide/zh-CN/installation/)
- [Configuration Documentation](configs/README.md)

### User Manual

- [IAM User Manual](docs/guide/zh-CN/README.md)
- [API Documentation](api/swagger/README.md)
- [Command-Line Tool Usage](docs/guide/zh-CN/api/)

### Development Documentation

- [Development Guide](docs/devel/)
- [Code Standards](docs/devel/)
- [Architecture Design](docs/guide/zh-CN/)

### API Documentation

- [Swagger Documentation](api/swagger/swagger.yaml)
- [OpenAPI Specification](api/openapi/)

---

## 🛠️ Development Guide

### Building the Project

```bash
# Install dependencies
make dependencies

# Code generation
make gen

# Build all components
make build

# Build specific components
make build BINS="iam-apiserver iam-authz-server"

# Run tests
make test

# Code coverage
make cover

# Code linting
make lint
```

### Project Structure

```
.
├── api/                  # API definition files (OpenAPI, Swagger)
├── build/                # Build scripts and Dockerfiles
├── cmd/                  # Main entry points for components
├── configs/              # Configuration file templates
├── deployments/          # Deployment configs (K8s, Docker)
├── docs/                 # Documentation
├── examples/             # Example code
├── init/                 # systemd service configurations
├── internal/             # Private application code
│   ├── apiserver/        # API server implementation
│   ├── authzserver/      # Authorization server implementation
│   ├── pump/             # Data analysis service implementation
│   └── watcher/          # Cache sync service implementation
├── pkg/                  # Public library code
├── scripts/              # Script files
├── test/                 # Test data and tools
├── third_party/          # Third-party code
└── tools/                # Tool code
```

### Makefile Commands

```bash
make help              # Show help information
make tidy              # Tidy dependencies
make gen               # Code generation
make format            # Format code
make lint              # Code linting
make test              # Run tests
make cover             # Generate coverage report
make build             # Build project
make image             # Build Docker images
make push              # Push Docker images
make deploy            # Deploy to Kubernetes
make clean             # Clean build artifacts
make release           # Create new release
```

---

## 🔧 Configuration

### iam-apiserver Configuration

```yaml
# /etc/iam/iam-apiserver.yaml
server:
  mode: release                    # Run mode: debug, release, test
  healthz: true                    # Enable health check
  middlewares: [recovery, logger, secure, nocache, cors, requestid]

grpc:
  bind-address: 0.0.0.0
  bind-port: 8081

insecure:
  bind-address: 0.0.0.0
  bind-port: 8080

secure:
  bind-address: 0.0.0.0
  bind-port: 8443
  tls:
    cert-key:
      cert-file: /etc/iam/cert/iam-apiserver.pem
      private-key-file: /etc/iam/cert/iam-apiserver-key.pem

mysql:
  host: 127.0.0.1:3306
  username: iam
  password: iam59!z$
  database: iam
  max-idle-connections: 100
  max-open-connections: 100
  max-connection-life-time: 10s
  log-level: 4

redis:
  host: 127.0.0.1
  port: 6379
  password: ""
  database: 0
```

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `IAM_INSTALL_DIR` | /opt/iam | Installation directory |
| `IAM_CONFIG_DIR` | /etc/iam | Configuration directory |
| `IAM_DATA_DIR` | /data/iam | Data directory |
| `IAM_LOG_DIR` | /var/log/iam | Log directory |

---

## 🧪 Testing

```bash
# Run all tests
make test

# Run unit tests
go test -v ./pkg/...

# Run integration tests
go test -v ./test/...

# Generate test coverage report
make cover

# View coverage report
go tool cover -html=coverage.out
```

---

## 📊 Performance Testing

```bash
# HTTP API performance test
./scripts/wrktest.sh

# gRPC performance test
ghz --insecure \
  --proto ./api/proto/apiserver/v1/apiserver.proto \
  --call apiserver.v1.Cache/ListSecrets \
  -d '{"offset": 0, "limit": 10}' \
  127.0.0.1:8081
```

---

## 🔐 Security

- **Authentication**: Supports Basic Auth and Bearer Token authentication methods
- **Transport Encryption**: TLS/SSL encryption support
- **Password Storage**: User passwords encrypted with bcrypt
- **Secret Key Management**: Support for periodic key rotation and automatic expiration
- **Audit Logging**: Complete operation audit log recording
- **Access Control**: Policy-based fine-grained permission control

---

## 📈 Monitoring & Operations

### Health Checks

```bash
# API Server health check
curl http://127.0.0.1:8080/healthz

# Authorization server health check
curl http://127.0.0.1:9090/healthz
```

### Prometheus Monitoring

```bash
# Access metrics endpoint
curl http://127.0.0.1:8080/metrics
```

### Log Viewing

```bash
# View service logs
journalctl -u iam-apiserver -f
journalctl -u iam-authz-server -f

# View log files
tail -f /var/log/iam/iam-apiserver.log
```

---

## 🤝 Contributing

We welcome all forms of contributions, including but not limited to:

- 🐛 Bug reports
- 💡 Feature suggestions
- 📝 Documentation improvements
- 🔧 Code fixes or new features

### Contribution Process

1. Fork this repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Code Standards

- Follow [Go Code Review Comments](https://github.com/golang/go/wiki/CodeReviewComments)
- Run `make lint` to ensure code passes checks
- Add necessary unit tests
- Update relevant documentation

---

## 📋 Version History

- **v1.7.0** (2024-01-04) - Latest stable release
- **v1.6.2** (2023-12-01) - Bug fixes and performance improvements
- **v1.0.0** (2021-07-08) - First official release

For detailed change history, please refer to the [CHANGELOG](CHANGELOG/) directory.

---

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## 👥 Community & Support

- **Issue Reporting**: [GitHub Issues](https://github.com/marmotedu/iam/issues)
- **Discussions**: [GitHub Discussions](https://github.com/marmotedu/iam/discussions)
- **Project Documentation**: [IAM Documentation](docs/)

---

## 🙏 Acknowledgments

Thanks to all the developers who have contributed to this project!

This project references and uses the following excellent open-source projects:

- [Gin Web Framework](https://github.com/gin-gonic/gin)
- [GORM](https://github.com/go-gorm/gorm)
- [Cobra](https://github.com/spf13/cobra)
- [Viper](https://github.com/spf13/viper)
- [Go Redis](https://github.com/go-redis/redis)
- [JWT Go](https://github.com/golang-jwt/jwt)

---

<div align="center">

**⭐ If this project helps you, please give it a Star! ⭐**

Made with ❤️ by [Marmotedu](https://github.com/marmotedu)

</div>

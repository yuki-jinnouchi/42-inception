# Inception

## Overview

Inception is a system administration project from the 42 curriculum that focuses on Docker containerization and infrastructure orchestration. The project requires building a complete web application stack using Docker Compose, demonstrating modern DevOps practices and container-based architecture design.

## Features

- **Multi-container Docker environment** - with three core services
- **Custom Dockerfiles** - for each service without using pre-built images
- **NGINX web server** - configured as reverse proxy with TLS/SSL
- **WordPress CMS** - with custom configuration and user management
- **MariaDB database** - with secure authentication and data persistence
- **Volume management** - for persistent data storage
- **Network isolation** - and secure inter-service communication

## How to Run

This project is made for run on VM on Linux machine at 42 school

<details>
<summary>*If VM is not prepared, run these before run docker by make </summary>

```bash
# Startup VM on Linux PC at school
make vm_startup

# Setup VM after finish installation
make vm_setup

# Access VM by SSH
make vm_ssh
```

</details>

If VM is prepared, run this

```bash
# Clone the repository
git clone https://github.com/yuki-jinnouchi/42-inception
cd inception

# Build and start all services
make

# Alternative commands
make up          # Start services
make down        # Stop services
make clean       # Remove containers and images
make fclean      # Full cleanup including volumes
```

Access the application at `https://localhost` or your configured domain.

(If VM is prepared, `https://yjinnouc.42.fr` will be redirected to `https://localhost`)

## Reference

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [NGINX Configuration Guide](https://nginx.org/en/docs/)
- [\[Lv5\]Inception｜syamashi (note)](https://note.com/syamashi/n/ndb5655f55ef8)
- [DockerでWordpress構築ハンズオン | 42 Inception (zenn)](https://zenn.dev/justhiro/articles/c454cc1fbc784e)

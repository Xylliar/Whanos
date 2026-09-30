# Whanos

Whanos automatically containerizes and deploys any application pushed to a linked Git repository.

Supported languages: Befunge, C, Java, JavaScript and Python.

## Quick start

```sh
cp .env.example .env    # then fill in the values
make
```

Jenkins is then available on http://localhost:8080 with the `admin` user.

## Documentation

- [Local deployment](docs/deployment.md): architecture, configuration and commands
- [Jenkins](docs/jenkins/jenkins.md): jobs, linking a project and private repositories
- [Kubernetes](docs/kubernetes.md): `whanos.yml` and accessing deployed applications

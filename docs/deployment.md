# Déploiement local de l'infrastructure Whanos

## Architecture

Toute l'infrastructure est décrite dans [`docker-compose.yml`](../docker-compose.yml) et tourne sur un seul réseau Docker :

| Service | Rôle | Accès depuis l'hôte |
| --- | --- | --- |
| `jenkins` | Instance Jenkins configurée par Configuration as Code | http://localhost:8080 |
| `registry` | Registry Docker officiel, reçoit les images des applications | `localhost:5001` |
| `k3s-server` | Nœud serveur du cluster Kubernetes (k3s) | API sur `https://localhost:6443`, applications sur les ports `30000` à `30099` |
| `k3s-agent-1`, `k3s-agent-2` | Nœuds workers du cluster | - |

Le cluster compte donc 3 nœuds.

Jenkins n'embarque pas de démon Docker : il pilote le démon Docker de l'hôte via le socket `/var/run/docker.sock`. Les images construites par les jobs sont donc directement disponibles sur l'hôte, puis poussées dans le registry sous le nom `localhost:5001/<projet>`.

Les nœuds k3s récupèrent ces images via un miroir déclaré dans [`k3s/registries.yaml`](../k3s/registries.yaml), qui redirige `localhost:5001` vers le registry sur le réseau Docker.

Le registry est exposé sur le port 5001 plutôt que 5000, car ce dernier est occupé par AirPlay sur macOS.

## Prérequis

- Docker avec le plugin Compose v2 (Docker Desktop sur macOS, Docker Engine sur Linux). Sur Linux, `make install` installe Docker s'il est absent.
- Environ 6 Go de mémoire alloués à Docker.
- Les ports `8080`, `5001`, `6443` et `30000` à `30099` libres sur l'hôte.

## Configuration

```sh
cp .env.example .env
```

| Variable | Obligatoire | Description |
| --- | --- | --- |
| `JENKINS_ADMIN_PASSWORD` | oui | Mot de passe de l'utilisateur `admin` de Jenkins |
| `K3S_TOKEN` | oui | Secret partagé entre les nœuds du cluster k3s (n'importe quelle chaîne) |
| `SSH_PRIVATE_KEY` | non | Clé privée SSH utilisée pour cloner les dépôts privés, voir [la documentation Jenkins](jenkins/jenkins.md#dépôts-privés) |

Le fichier `.env` contient des secrets : il est ignoré par Git et ne doit jamais être commité.

## Commandes

| Commande | Effet |
| --- | --- |
| `make` | Construit l'image Jenkins et démarre toute l'infrastructure |
| `make down` | Arrête l'infrastructure en conservant les données |
| `make clean` | Arrête l'infrastructure et supprime ses volumes et l'image Jenkins |
| `make re` | `make clean` puis `make` |
| `make logs` | Affiche les logs de tous les services |
| `make kubeconfig` | Écrit un fichier `k3s.yaml` pour utiliser `kubectl` depuis l'hôte : `KUBECONFIG=k3s.yaml kubectl get nodes` |

Jenkins est prêt quand http://localhost:8080 affiche la page de connexion (environ une minute après `make`).

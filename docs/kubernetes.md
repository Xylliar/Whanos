# Déploiement des applications dans Kubernetes

## Fichier `whanos.yml`

Une application est déployée dans le cluster si son dépôt contient à sa racine un fichier `whanos.yml` avec une propriété `deployment` :

```yaml
deployment:
  replicas: 2
  resources:
    limits:
      memory: "128Mi"
    requests:
      memory: "64Mi"
  ports:
    - 3000
```

| Propriété | Défaut | Description |
| --- | --- | --- |
| `replicas` | `1` | Nombre de pods à faire tourner en même temps |
| `resources` | aucune | Besoins en ressources, avec [la syntaxe Kubernetes](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/) |
| `ports` | aucun | Liste des ports du conteneur à rendre accessibles depuis l'extérieur |

Un fichier invalide fait échouer le build avec un message explicite. Sans `whanos.yml`, ou sans propriété `deployment`, l'image est construite et poussée mais pas déployée.

Le déploiement est fait par [`utils/whanos_deploy.py`](../utils/whanos_deploy.py), qui génère et applique :

- un `Deployment` nommé comme le projet, utilisant l'image du build courant ;
- un `Service` de type `NodePort` si des ports sont déclarés.

Le build attend que tous les pods soient prêts : une application qui plante au démarrage fait échouer le build.

## Accéder à une application

Chaque port déclaré dans `whanos.yml` reçoit un port du cluster entre `30000` et `30099`. Cette plage est publiée sur l'hôte par le conteneur `k3s-server`, et Kubernetes route le trafic vers les pods quel que soit le nœud sur lequel ils tournent.

La fin du log du job indique l'adresse à utiliser :

```
Port 3000 is reachable at localhost:30042
```

L'application répond alors sur http://localhost:30042. Le port attribué reste le même d'un build à l'autre.

Pour retrouver les ports depuis l'hôte :

```sh
make kubeconfig
KUBECONFIG=k3s.yaml kubectl get services
```

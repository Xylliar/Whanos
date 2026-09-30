# Instance Jenkins

L'instance est entièrement configurée au démarrage par [Configuration as Code](../../jenkins-casc.yaml) : utilisateurs, droits, identifiants et jobs (décrits dans [`jobs.groovy`](../../jobs.groovy)). Aucune configuration manuelle n'est nécessaire.

## Connexion

- URL : http://localhost:8080
- Identifiant : `admin` (nom affiché : *Admin*), avec tous les droits
- Mot de passe : la valeur de `JENKINS_ADMIN_PASSWORD` dans `.env`

L'inscription est désactivée.

## Jobs

| Job | Rôle |
| --- | --- |
| `Whanos base images/whanos-<langage>` | Construit l'image de base `whanos-<langage>` sur l'hôte |
| `Whanos base images/Build all base images` | Déclenche les cinq jobs précédents |
| `link-project` | Relie un dépôt Git à Whanos en créant un job dans `Projects` |
| `Projects/<nom>` | Job créé par `link-project` pour un dépôt |

### Paramètres de `link-project`

| Paramètre | Description |
| --- | --- |
| `PROJECT_NAME` | Nom du job créé dans `Projects`, aussi utilisé comme nom d'image et de déploiement |
| `REPO_URL` | URL du dépôt, en SSH (`git@host:user/repo.git`) ou en HTTPS |
| `BRANCH` | Branche par défaut du dépôt (`main` par défaut) |
| `GIT_CREDENTIALS` | Identifiants utilisés pour cloner le dépôt (`ssh-key` par défaut, vide pour un dépôt public) |

Le job créé est lancé immédiatement, puis vérifie les changements sur la branche chaque minute.

### Déroulement d'un job de projet

Chaque build exécute [`utils/whanos_deliver.sh`](../../utils/whanos_deliver.sh), qui :

1. détecte le langage avec [`utils/language_detector.sh`](../../utils/language_detector.sh), selon les critères du sujet (`Makefile` pour C, `app/pom.xml` pour Java, `package.json` pour JavaScript, `requirements.txt` pour Python, `app/main.bf` pour Befunge). Le build échoue si aucun critère ou plusieurs critères correspondent ;
2. construit l'image : avec l'image standalone du langage si le dépôt n'a pas de `Dockerfile`, sinon avec le `Dockerfile` du dépôt (l'image de base `whanos-<langage>` est construite au préalable si elle n'existe pas encore) ;
3. pousse l'image dans le registry sous `localhost:5001/<projet>:build-<numéro>` et `localhost:5001/<projet>:latest` ;
4. déploie l'application dans le cluster si le dépôt contient un `whanos.yml` avec une propriété `deployment`, voir [la documentation Kubernetes](../kubernetes.md).

## Dépôts privés

N'importe quel serveur Git est supporté (GitHub, GitLab, Gitea, serveur SSH personnel…), en SSH ou en HTTPS. La vérification des clés d'hôte SSH est désactivée pour ne pas avoir à déclarer chaque serveur.

### Avec une clé SSH (méthode par défaut)

1. Générer une clé dédiée : `ssh-keygen -t ed25519 -f whanos_key -N ""`.
2. Ajouter la clé publique (`whanos_key.pub`) au serveur Git, par exemple comme *deploy key* du dépôt.
3. Mettre la clé privée dans `.env`, entre guillemets doubles, sur plusieurs lignes :

   ```
   SSH_PRIVATE_KEY="-----BEGIN OPENSSH PRIVATE KEY-----
   ...
   -----END OPENSSH PRIVATE KEY-----"
   ```

4. Relancer l'infrastructure avec `make`. La clé est chargée dans l'identifiant `ssh-key`, utilisé par défaut par `link-project`.

### Avec d'autres identifiants

Dans *Administrer Jenkins > Credentials > System > Global credentials*, ajouter un identifiant *SSH Username with private key* ou *Username with password* (un token d'accès fait office de mot de passe pour GitHub ou GitLab en HTTPS), puis le sélectionner dans le paramètre `GIT_CREDENTIALS` de `link-project`.

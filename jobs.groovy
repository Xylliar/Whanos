def languages = ['befunge', 'c', 'java', 'javascript', 'python']

folder('Whanos base images') {
    description('Jobs building the Whanos base images')
}

folder('Projects') {
    description('Jobs created by link-project for each linked repository')
}

languages.each { language ->
    freeStyleJob("Whanos base images/whanos-${language}") {
        description("Builds the whanos-${language} base image")
        steps {
            shell("docker build -t whanos-${language} - < /images/${language}/Dockerfile.base")
        }
    }
}

freeStyleJob('Whanos base images/Build all base images') {
    description('Triggers every Whanos base image build job')
    publishers {
        downstream(languages.collect { "whanos-${it}" }.join(', '), 'SUCCESS')
    }
}

freeStyleJob('link-project') {
    description('Links a Git repository to the Whanos infrastructure by creating a job in the Projects folder')
    parameters {
        stringParam('PROJECT_NAME', '', 'Name of the job to create in the Projects folder')
        stringParam('REPO_URL', '', 'URL of the Git repository (SSH or HTTPS)')
        stringParam('BRANCH', 'main', 'Default branch of the repository')
        credentialsParam('GIT_CREDENTIALS') {
            type('com.cloudbees.plugins.credentials.common.StandardCredentials')
            required(false)
            defaultValue('ssh-key')
            description('Credentials used to fetch the repository (SSH key or username/password)')
        }
    }
    steps {
        dsl {
            text('''
                freeStyleJob("Projects/${PROJECT_NAME}") {
                    description("Whanos job for ${REPO_URL}")
                    scm {
                        git {
                            remote {
                                url(REPO_URL)
                                if (GIT_CREDENTIALS) {
                                    credentials(GIT_CREDENTIALS)
                                }
                            }
                            branch(BRANCH)
                        }
                    }
                    triggers {
                        scm('* * * * *')
                    }
                    steps {
                        shell('bash /utils/whanos_deliver.sh')
                    }
                }
                queue("Projects/${PROJECT_NAME}")
            ''')
        }
    }
}

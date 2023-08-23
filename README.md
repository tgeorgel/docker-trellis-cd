## tgeorgel/docker-trellis-cd

This repository is a fork of `zessx/trellis-cd`, updated for newer version of Ubuntu, Ansible and NodeJS.

It provides a deploy image for Trellis with:
  - Ubuntu
  - Ansible
  - Node.js
  - Yarn

This image can be used as a base image for your CI/CD pipeline.

## Releases

 - 1.0-node*: Ubuntu 18.04 / Ansible 2.7 => see `zessx/trellis-cd` image
 - 1.2-node*: Ubuntu 18.04 / Ansible 2.9 => see `zessx/trellis-cd` image
 - 1.3-node*: Ubuntu 20.04 / Ansible 2.9
 - 1.3.1-node*: Ubuntu 20.04 / Ansible 2.15.3
 - 1.4-node*: Ubuntu 22.04 / Ansible 2.15.3


## Adding new image

After updating the Dockerfile, you can build and push the image with:

```bash
docker build - < Dockerfile
docker images # get the sha
docker tag [sha] tgeorgel/docker-trellis-cd:[TAG]
docker push tgeorgel/docker-trellis-cd:[TAG]
```


## Example usage with Gitlab CI/CD

You will need to configure a deploy token on your Gitlab project, create a RSA key pair on the host, and add the created public key to your project's deploy keys.

It is recommended to configure the following variables as CI/CD hidden+protected vars, instead of hardcoding them in your `.gitlab-ci.yml` file :
- TRELLIS_DEPLOY_USER
- TRELLIS_DEPLOY_TOKEN
- TRELLIS_VAULT_PASS
- TRELLIS_BRANCH

#### Single environment 

This job will deploy your site when you push to the `main` branch of your project.

```yaml
variables:
  TRELLIS_LOCAL_PATH: site
  TRELLIS_ENV: production
  TRELLIS_SITE: example.com

deploy_site:
  stage: deploy
  image: tgeorgel/docker-trellis-cd:1.4-node14
  cache: {}
  script:
    # Prepare Folder Structure
    - cd ..
    - rm -rf deploy
    - mkdir -p deploy/$TRELLIS_LOCAL_PATH
    - cp -ra $CI_PROJECT_NAME/. deploy/$TRELLIS_LOCAL_PATH/

    # Retrieve Trellis code
    - git clone https://$TRELLIS_DEPLOY_USER:$TRELLIS_DEPLOY_TOKEN@gitlab.com/[GROUP]/trellis.git deploy/trellis
    - cd deploy/trellis && git checkout $TRELLIS_BRANCH

    # Create Vault Pass file
    - export VAULT_FILE_PATH=$(grep ^vault_password_file ansible.cfg | cut -d " " -f 3)
    - echo $TRELLIS_VAULT_PASS >> $VAULT_FILE_PATH

    # Manage SSH KEY
    - mkdir -p ~/.ssh
    - chmod 700 ~/.ssh
    - echo -e "Host *\n\tStrictHostKeyChecking no\n\n" > ~/.ssh/config
    - ansible-vault view ssh-keys/runner.key > ~/.ssh/id_rsa
    - chmod 600 ~/.ssh/id_rsa

    # Load SSH KEY
    - 'which ssh-agent || ( apt install openssh-client )'
    - eval "$(ssh-agent -s)"
    - ssh-add ~/.ssh/id_rsa

    # Deploy with Ansible
    - ansible-playbook deploy.yml -e env=$TRELLIS_ENV -e site=$TRELLIS_SITE
  only:
    - main
```


#### Multiple environments (production/preproduction)

In this example, your production environment is on the `main` branch, and your preproduction environment is on the `staging` branch of your project.
The job will be triggered when you push to either of these branches, guessing the site to deploy based on the branch name.

```yaml
variables:
  TRELLIS_LOCAL_PATH: site
  TRELLIS_ENV_MAIN: production
  TRELLIS_ENV_STAGING: production
  TRELLIS_SITE_MAIN: example.com
  TRELLIS_SITE_STAGING: demo.example.com

deploy_site:
  stage: deploy
  image: tgeorgel/docker-trellis-cd:1.4-node14
  cache: {}
  script:
    # Define Trellis environment
    - export TRELLIS_ENV=$(([ $CI_COMMIT_REF_NAME == "main" ] && echo $TRELLIS_ENV_MAIN) || ([ $CI_COMMIT_REF_NAME == "staging" ] && echo $TRELLIS_ENV_STAGING))
    - export TRELLIS_SITE=$(([ $CI_COMMIT_REF_NAME == "main" ] && echo $TRELLIS_SITE_MAIN) || ([ $CI_COMMIT_REF_NAME == "staging" ] && echo $TRELLIS_SITE_STAGING))

    [...] Same as above [...]

    # Deploy with Ansible
    - ansible-playbook deploy.yml -e env=$TRELLIS_ENV -e site=$TRELLIS_SITE
  only:
    - main
    - staging
```

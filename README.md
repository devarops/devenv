# Configura tu entorno para desarrollo

## Autenticación mediante SSH

Una única vez en tu cliente liviano:

1. Crea tu clave SSH con: `ssh-keygen`
1. Agrega tu clave SSH al agente para hacer _forwarding_: `ssh-add ~/.ssh/id_rsa`
1. Agrega la clave SSH pública[^ssh_pub] de tu estación de trabajo a:
    - [Bitbucket](https://bitbucket.org/account/settings/ssh-keys/),
    - [DigitalOcean](https://cloud.digitalocean.com/account/security) y
    - [GitHub](https://github.com/settings/keys/)

## En DigitalOcean

Crea una Droplet llamada `workstation`.

## Desde tu cliente liviano copia las credenciales hacia el servidor `workstation`

```shell
scp ~/.ssh/id_rsa root@<WORKSTATION IP>:/root/.ssh/
scp -pr ~/.vault root@<WORKSTATION IP>:/root/.vault
```

## Desde el servidor `workstation` crea y configura el servidor `devserver`

1. Entra con: `ssh root@<WORKSTATION IP>`
1. Agrega [bóveda secreta](https://docs.google.com/document/d/1lY7ycXs4J8wp1OyJCmPsvfB7YdQqscqL52cIZxBP6Rw)
1. Ejecuta:
    ```shell
    apt update && apt install --yes docker.io
    git clone https://github.com/IslasGECI/development_server_setup.git
    cd development_server_setup
    git checkout feature/create_droplet
    docker build --tag islasgeci/development_server_setup:latest .
    docker login
    docker push islasgeci/development_server_setup:latest
    source ${HOME}/.vault/.secrets
    docker run \
        --env DO_PAT \
        --interactive \
        --rm \
        --tty \
        --volume ${HOME}/.ssh/id_rsa:/root/.ssh/id_rsa \
        --volume ${HOME}/.vault/.secrets:/root/.vault/.secrets \
        islasgeci/development_server_setup:latest make
    ```
1. Destruye el servidor `workstation`

## En el servidor `devserver` crea una cuenta de usuario

1. Entra con:
    ```shell
    ssh-keygen -f "$HOME/.ssh/known_hosts" -R "islasgeci.dev"
    ssh root@islasgeci.dev
    ```
1. En el servidor ejecuta:
    ```shell
    export GITHUB_USERNAME=<GITHUB USERNAME>
    adduser $GITHUB_USERNAME
    usermod --append --groups docker,sudo $GITHUB_USERNAME
    sed --in-place 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sudo service ssh restart
    exit
    ```

> Reemplaza `<GITHUB USERNAME>` con tu nombre de usuario en GitHub

## En tu cliente liviano copia las credenciales hacia el servidor `devserver`

```shell
export GITHUB_USERNAME=<GITHUB USERNAME>
ssh-copy-id $GITHUB_USERNAME@islasgeci.dev
scp -pr ~/.vault $GITHUB_USERNAME@islasgeci.dev:/home/$GITHUB_USERNAME/.vault
```

## En el servidor `devserver` instala tu configuración personal

1. Entra con: `ssh -o ForwardAgent=yes $GITHUB_USERNAME@islasgeci.dev`[^forward].
2. Crea directorio para clonar repositorios: `mkdir --parents ~/repositorios`
3. Instala tu PDE:
    ```shell
    cd ~/repositorios
    git clone git@github.com:devarops/pde.git
    cd pde
    make
    ```
1. Instala tus archivos de configuración:
    ```shell
    git clone --bare git@github.com:$USER/dotfiles.git ~/repositorios/dotfiles.git
    git --git-dir=${HOME}/repositorios/dotfiles.git --work-tree=${HOME} checkout
    git --git-dir=${HOME}/repositorios/dotfiles.git --work-tree=${HOME} config --local status.showUntrackedFiles no
    source ~/.profile
    ```

[^forward]:
    Alternativamente, puedes agregar la opción `ForwardAgent yes` a `~/.ssh/config` en tu cliente liviano:
    ```
    Host islasgeci.dev
      ForwardAgent yes
    ```
    Revisa [este ejemplo](https://github.com/devarops/dotfiles/blob/develop/.ssh/config).

## Opcional: En tu cliente liviano monta los repositorios del servidor

```shell
sudo apt install sshfs
sudo mkdir --parents /mnt/$GITHUB_USERNAME/
sudo chown $USER:$USER /mnt/$GITHUB_USERNAME/
sshfs $GITHUB_USERNAME@islasgeci.dev:/home/$GITHUB_USERNAME/repositorios/ /mnt/$GITHUB_USERNAME/
```

> Para desmontar: `fusermount -u /mnt/$GITHUB_USERNAME/`

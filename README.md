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
export WORKSTATION_IP=<WORKSTATION IP>
scp ~/.ssh/id_rsa root@$WORKSTATION_IP:/root/.ssh/
scp -pr ~/.vault root@$WORKSTATION_IP:/root/.vault
```

## Desde el servidor `workstation` crea y configura el servidor `devserver`

1. Entra con: `ssh root@$WORKSTATION_IP`
1. Ejecuta:
    ```shell
    sudo apt update && sudo apt install --yes docker.io
    git clone https://github.com/IslasGECI/development_server_setup.git
    cd development_server_setup
    git checkout feature/import_dorfiles
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

> Reemplaza `<GITHUB USERNAME>` con tu nombre de usuario en GitHub

## En tu cliente liviano copia las credenciales hacia el servidor `devserver`

```shell
scp -pr ~/.vault $GITHUB_USERNAME@islasgeci.dev:/home/$GITHUB_USERNAME/.vault
```

## En el servidor `devserver` instala tu configuración personal

1. Entra con: `ssh -o ForwardAgent=yes $GITHUB_USERNAME@islasgeci.dev`[^forward].
1. Instala tus archivos de configuración:
    ```shell
    git clone https://github.com/devarops/dotfiles.git
    cd dotfiles
    make
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

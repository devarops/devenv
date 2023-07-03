# Configura tu entorno para desarrollo

## Autenticación mediante SSH

Una única vez en tu cliente liviano:

1. Crea tu clave SSH con: `ssh-keygen`
1. Agrega tu clave SSH al agente para hacer _forwarding_: `ssh-add ~/.ssh/id_rsa`
1. Agrega la clave SSH pública de tu estación de trabajo a:
    - [Bitbucket](https://bitbucket.org/account/settings/ssh-keys/),
    - [DigitalOcean](https://cloud.digitalocean.com/account/security) y
    - [GitHub](https://github.com/settings/keys/)
1. Instala [dotfiles](https://github.com/devarops/dotfiles):
```shell
git clone git@github.com:devarops/dotfiles.git
cd dotfiles
make install
```
1. Configura el cliente liviano:
```shell
sudo mv /etc/nixos/configuration.nix /etc/nixos/configuration.nix.orig
sudo ln -s ~/.config/nixos/configuration.nix /etc/nixos/configuration.nix
sudo nixos-rebuild switch --upgrade-all
```

## En DigitalOcean

Crea una Droplet llamada `provisioner`.

## Desde tu cliente liviano copia las credenciales hacia el servidor `provisioner`

```shell
export PROVISIONER_IP=<PROVISIONER IP>
scp ~/.ssh/id_rsa root@$PROVISIONER_IP:/root/.ssh/
```

## Desde el servidor `provisioner` crea y configura el servidor `devserver`

1. Entra con: `ssh root@$PROVISIONER_IP`
1. Ejecuta:
    ```shell
    sudo apt update && sudo apt install --yes docker.io
    docker pull islasgeci/development_server_setup:latest
    export DO_PAT=<Token de DigitalOcean>
    docker run \
        --env DO_PAT \
        --interactive \
        --rm \
        --tty \
        --volume ${HOME}/.ssh/id_rsa:/root/.ssh/id_rsa \
        islasgeci/development_server_setup:latest make
    ```
1. Destruye el servidor `provisioner`

## En tu cliente liviano copia las credenciales hacia el servidor `devserver`

```shell
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "islasgeci.dev"
ssh-keyscan "islasgeci.dev" >> "$HOME/.ssh/known_hosts"
export DEVELOPER=<Tu nombre de usuario del servidor>
scp -pr ~/.vault $DEVELOPER@islasgeci.dev:/home/$DEVELOPER/.vault
scp ~/todo.md $DEVELOPER@islasgeci.dev:/home/$DEVELOPER/todo.md
```

Finalmente, entra al `devserver` con: `ssh -o ForwardAgent=yes $DEVELOPER@islasgeci.dev`[^forward].

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

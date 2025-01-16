# Configura tu cliente liviano

1. Crea tu clave SSH con: `ssh-keygen`
1. Agrega tu clave SSH al agente para hacer _forwarding_
    - En Linux ejecuta: `ssh-add ~/.ssh/id_ed25519`
    - En WSL agrega a `~/.bashrc`:
    ```shell
    eval `ssh-agent -s`
    ssh-add ~/.ssh/id_ed25519
    ```
1. Agrega la clave SSH pública de tu estación de trabajo a:
    - [Bitbucket](https://bitbucket.org/account/settings/ssh-keys/) y
    - [GitHub](https://github.com/settings/keys/)
1. Crea directorio para clonar repositorios:
    ```shell
    mkdir --parents ~/repositorios/
    ```
1. Verifica instalación:
    ```shell
    cd ~/repositorios/
    git clone git@github.com:devarops/thin_client.git
    cd thin_client
    make check
    ```
    - Instalación del `rich`:

      ```
      sudo apt install pipx --yes
      pipx install rich-cli
      pipx ensurepath
      ```
      
   - En el `~/.bashrc` mover al inicio del archivo las líneas incertadas por `pipx`.
   
1. Instala [dotfiles](https://github.com/devarops/dotfiles):
    ```shell
    cd ~/repositorios/
    git clone git@github.com:devarops/dotfiles.git
    cd dotfiles
    make install
    ```
1. Agrega tu [bóveda secreta](https://docs.google.com/document/d/1lY7ycXs4J8wp1OyJCmPsvfB7YdQqscqL52cIZxBP6Rw/).

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

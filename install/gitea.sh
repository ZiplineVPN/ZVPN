#!/bin/bash
#../gitea-install/main.sh via condense.sh @ Thu 13 May 2021 09:23:54 AM HST
#Start '../gitea-install/main.sh' [condense.sh]
#Start 'funcs.sh' [condense.sh]
function downloadGitea()
{
    echo "Assuring/Aquiring $installExeName"
    if [ ! -f "$tmpExe" ]; then wget -O $tmpExe https://dl.gitea.io/gitea/$ver/$installExeName &>/dev/null; fi
    echo "Assuring/Aquiring $installAscName"
    if [ ! -f "$tmpAsc" ]; then wget -O $tmpAsc https://dl.gitea.io/gitea/$ver/$installAscName &>/dev/null; fi
}
function tmpCheck()
{
    if [ ! -d "$installTmpDir" ]; then 
        echo "Creating tmp work dir '$installTmpDir'"
        mkdir -p "$installTmpDir"
    fi
}
function installDirsCheck()
{
    if [ ! -d "$giteaInstallDir" ]; then
        echo "Creating gitea data folder & sub dirs"
        sleep 1
    fi
    if [ ! -d "$giteaConfDir" ]; then
        echo "Creating gitea config folder"
        sleep 1
        sudo mkdir -p "$giteaConfDir"
    fi
}
function permsFix()
{
    echo "Fixing perms..."
    sudo chown -R "$username":"$username" "$giteaInstallDir"
    sudo chmod -R 750 "$giteaInstallDir" 
    sudo chown -R "$username":"$username" "$giteaRepoDir"
    sudo chmod -R 750 "$giteaRepoDir" 
    sudo chown -R root:"$username" "$giteaConfDir"
    chmod 770 -R "$giteaConfDir"
}
function lockConf()
{
    sudo chmod 640 "$giteaConfFile"
}
function mkConf()
{
    if [ -d "$giteaConfDir" ]; then
        echo "Purging gitea config folder"
        sudo rm -rf "$giteaConfDir"
        sleep 1
    fi
    sudo mkdir "$giteaConfDir"
    sudo chown root:"$username" "$giteaConfDir"
    chmod 770 "$giteaConfDir"
}
function mkInstall()
{
    if [ -d "$giteaInstallDir" ]; then
        echo "Purging gitea installation folder"
        sleep 1
        sudo rm -rf "$giteaInstallDir"
    fi
    sudo mkdir "$giteaInstallDir"
    sudo mkdir -p "$giteaInstallDir/"{custom,data,log}
    sudo chown "$username":"$username" "$giteaInstallDir"
    sudo chmod 750 "$giteaInstallDir" 
}
function mkRepo()
{
    if [ -d "$giteaRepoDir" ]; then
        echo "Purging gitea installation folder"
        sleep 1
        sudo rm -rf "$giteaRepoDir"
    fi
    sudo mkdir "$giteaRepoDir"
    sudo chown "$username":"$username" "$giteaRepoDir"
    sudo chmod 750 "$giteaRepoDir" 
}
function cmdCheck()
 {
    echo "Checking for '$1'..."
    sleep 1
    valid=1
    which "$1" &>/dev/null
    if [ "$?" == 0 ]; then
        echo "'$1' installed: $("$1" --version 2>/dev/null)"
        valid=0
    else
        echo "'$1' not installed..."
    fi
    sleep 1
    return $valid;
}
function promptYN() {
    while true; do
        read -p "$1 [Y/N]:\n" yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "[Y]es or [N]o";;
        esac
    done
}
function generateSvcTmpl()
{
    if [ -f "$tmpService" ]; then
        rm $tmpService
    fi
    echo "Generating '$serviceName'..."
    echo "DB: $giteaDB.service"
    echo "Large Repo Settings: $giteaLargeRepos"
    echo "Low Port Settings: $giteaLowPorts"
    sleep 3
    gen="#Auto Generated via gitea-installer.sh
[Unit]
Description=Gitea (Git with a cup of tea)
After=syslog.target
After=network.target"
    #if [ ! "$giteaDB" == "" ]; then
   #     gen="$gen
  #  fi
    gen="$gen
[Install]
WantedBy=multi-user.target
[Service]
Restart=always
RestartSec=2s
Type=simple
User=$username
Group=$username
WorkingDirectory=$giteaInstallDir
ExecStart=$giteaExe web --config $giteaConfDir/app.ini
Environment=USER=$username HOME=/home/$username GITEA_WORK_DIR=$giteaInstallDir"
    if [ ! "$giteaLargeRepos" == false ]; then
        gen="$gen
LimitMEMLOCK=infinity
LimitNOFILE=65535"
    fi
    if [ ! "$giteaLowPorts" == false ]; then
        gen="$gen
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE"
    fi
    echo "$gen" > "$tmpService"
}
function cleanup()
{
    case "$1" in
        rollback-install)
            echo "The installer cleaned up without creating an installtion."
            echo "Rolling back any Gitea-related filesystem changes."
            echo "Please Note: User accounts, are NOT cleaned, or removed (on principal)"
            echo "Also Note: This cleanup preseves tmp data for next run."
            echo "Manually clean '$installTmpDir' if so desired"
            echo "Cleaning up Gitea data dir[$giteaInstallDir]..."
            rm -rf "$giteaInstallDir"
            echo "Cleaning up Gitea config dir[$giteaConfDir]..."
            rm -rf "$giteaConfDir"
        ;;
        install)
            echo "The installation completed sucessfully"
            rm -rf "$installTmpDir"
            ;;
    esac
}
#End 'funcs.sh' [condense.sh]
#Start 'env.sh' [condense.sh]
installTmpDir=/tmp/gitea-installer
ver=1.14.2
arch=linux-amd64
username=gitea
if [ "$EUID" -ne 0 ]
  then echo "gitea-wizard requires root permissions to manage gitea."
  exit
fi
declare -A aptNames=( [mysql]=mysql-server [redis]=redis-server [mariadb]=mariadb-server )
restoreFile=
backupFile=
if cmdCheck gitea; then
    installed=1
else
    installed=0
fi
serviceDir=/etc/systemd/system
giteaInstallDir=/var/lib/gitea
giteaConfDir=/etc/gitea
giteaExe=/usr/local/bin/gitea
giteaRepoDir="/home/$username/gitea-repositories"
tmpRestoreDir="$installTmpDir/restore-data"
serviceName=gitea
serviceFileName="$serviceName.service"
installExeName="gitea-$ver-$arch"
tmpExe="$installTmpDir/$installExeName"
installAscName="$installExeName.asc"
tmpAsc="$installTmpDir/$installAscName"
tmpService="$installTmpDir/$serviceName"
serviceFile="$serviceDir/$serviceFileName"
giteaConfFile="$giteaConfDir/app.ini"
giteaLargeRepos=false
giteaLowPorts=false
startAfter=false
giteaDB="mysql"
#End 'env.sh' [condense.sh]
#Start 'args.sh' [condense.sh]
while :; do
    if [ "$1" == "" ]; then break; fi
    case "$1" in
    --large) 
        giteaLargeRepos=true
        echo "Large repos enabled. LimitMEMLOCK/NOFILE will be written to '$serviceName'"
    ;;
    --start) 
        echo "Starting service automatically"
        startAfter=true
    ;;
    --low-ports)
        giteaLowPorts=true
        echo "Low ports enabled. Ambient Capabilities/Bounding Set will be written to '$serviceName'"
    ;;
    *)
        varSet=$(echo "$1" | cut -c2-)
        IFS='=' read -ra keyValue <<< "$varSet"
        case "${keyValue[0]}" in 
            db) 
                giteaDB="${keyValue[1]}"
            ;;
            backup) 
                backupFile="${keyValue[1]}"
                echo "Testing backup output '$backupFile'."
                if [ ! -f "$backupFile" ]; then
                    echo "Backup to output '$backupFile' is OK!"
                else
                    echo "Backup '$backupFile' already exists."
                    exit
                fi
            ;;
            restore) 
                restoreFile="${keyValue[1]}"
                echo "Testing backup restore '$restoreFile'."
                if [ -f "$restoreFile" ]; then
                    echo "Backup to restore '$restoreFile' exists. We'll use it!"
                else
                    echo "Backup to restore '$restoreFile' didn't exist."
                    exit
                fi
            ;;
        esac
    esac
    shift
done
if [ -v aptNames[$giteaDB] ]; then
    echo "Using valid DB kind: '$giteaDB'"
else 
    echo "Invalid DB kind: '$giteaDB'. No installation candidate."
    exit;
fi
if [ -n "$backupFile" ]; then
    if [ -f "$backupFile" ]; then
        echo "$backupFile already exists, disregarding backup directive."
        backupFile=
    fi
fi
if [ -n "$restoreFile" ]; then
    if [ ! -f "$restoreFile" ]; then
        echo "$restoreFile doesn't exist, disregarding restore directive."
        restoreFile=
    fi
fi
#End 'args.sh' [condense.sh]
sudo echo "Sudo elevation request"
if [ $installed == 0 ]; then
    echo "No Gitea present."
    if [ -n "$backupFile" ]; then
        echo "No reason to perform backup with no installation. Disregarding backup directive."
        backupFile=
    fi
    echo "Prepping installation..."
#Start 'install.sh' [condense.sh]
tmpCheck
cmdCheck git
if [ ! "$?" == 0 ]; then
    sudo apt install -y git
fi
echo "Checking for gitea user[$username]"
if id "$username" &>/dev/null; then
    echo "User '$username' exists."
else
    echo "Making user '$username'."
    sudo adduser --system --shell /bin/bash --gecos 'Gitea' --group --disabled-password --home /home/$username $username
fi
mkConf
mkInstall
mkRepo
downloadGitea
echo "Assuring/Aquiring PGP Key"
gpg --keyserver keys.openpgp.org --recv 7C9E68152594688862D62AF62D9AE806EC1592E2 &>/dev/null
echo "Verifying executable against PGP key"
gpg --verify "$tmpAsc" "$tmpExe" &>/dev/null 
if [ ! "$?" == 0 ]; then 
    echo "Invalid hash check. We'll clear tmp dir, and trying again"
    sleep 1
    rm -rf "$installTmpDir"
    tmpCheck
    downloadGitea
    echo "Verifying executable against PGP key"
    gpg --verify "$tmpAsc" "$tmpExe" &>/dev/null
    if [ ! "$?" == 0 ]; then echo "Invalid hash check?! Is someone haxxing you?!!"; cleanup rollback-install; fi
fi
echo "Successfully hashed executable"
sudo cp "$tmpExe" "$giteaExe"
sudo chmod +x "$giteaExe"
echo "Executable copied, installed, and marked as executable"
sudo ln -s "$giteaExe" "$giteaInstallDir"
echo "Linked executable to local bin"
#End 'install.sh' [condense.sh]
    permsFix
    sleep 1
    generateSvcTmpl
    sleep 1
    echo "Installing systemd service file"
    sudo mv "$tmpService" "$serviceFile"
    needsService=1
else 
    echo "Stopping running gitea service..."
    sudo service "$serviceName" stop
    echo "Service stopped."
fi
if [ -n "$backupFile" ]; then
    echo "Performing backup..."
    here="$PWD"
    sudo -H -u $username bash -c "cd $giteaInstallDir; ./gitea dump -c $giteaConfFile -f $backupFile;"
    sudo mv "$giteaInstallDir/$backupFile" "$here/$backupFile"
fi
if [ -n "$restoreFile" ]; then
    if [ $installed == 1 ] && 
        promptYN "Are you SURE, like SURE SURE SURE?
    This will OVERWRITE and ERASE any data on the git, not currently in the backup being restored.
Only continue if you're ABSOLUTELY-DOOTLY SURE that this is what you want." &&
 promptYN "You're really sure, that you're sure, you're sure about being sure, surely, you're sure?" && 
 echo "Alright then lets do it." || [ $installed == 0 ]; then
        cmdCheck unzip
        if [ ! "$?" == 0 ]; then
            echo "Installing unzip..."
            sudo apt install -y unzip &>/dev/null;
        fi
        echo "Beginning restore from '$restoreFile'"
        if [ -d "$tmpRestoreDir" ]; then 
            sudo rm -rf "$tmpRestoreDir"
        fi
        mkdir -p "$tmpRestoreDir"
        echo "Extracting zip backup..."
        sudo unzip "$restoreFile" -d "$tmpRestoreDir";
        echo "Done. Prepping restore"
        mkInstall
        mkConf
        mkRepo
        permsFix
        echo "Migrating app.ini"
        sudo mv "$tmpRestoreDir/app.ini" "$giteaConfFile"
        echo "Migrating gitea installation data..."
        sudo mv "$tmpRestoreDir/"{custom,log,data} "$giteaInstallDir"
        echo "Cleanup existing repo dir."
        if [ -d "$giteaRepoDir" ]; then 
            sudo rm -rf "$giteaRepoDir"
        fi
        sudo mkdir "$giteaRepoDir"
        echo "Migrating gitea repos..."
        sudo mv "$tmpRestoreDir/repos/"{.,}* "$giteaRepoDir"
        permsFix
        case "$giteaDB" in 
            mysql) 
                echo "Reading imported config ini..."
                mysqlDBName=$(sudo awk -F "=" '/^NAME/ {print $2}' "$giteaConfFile" | awk '{$1=$1};1')
                mysqlDBUser=$(sudo awk -F "=" '/^USER/ {print $2}' "$giteaConfFile" | awk '{$1=$1};1')
                mysqlDBPasswd=$(sudo awk -F "=" '/^PASSWD/ {print $2}' "$giteaConfFile" | awk '{$1=$1};1')
                echo "[Re]creating DB '$mysqlDBName' [if any exists]."
                echo "DROP DATABASE IF EXISTS \`$mysqlDBName\`" | sudo mysql -u root
                echo "CREATE DATABASE \`$mysqlDBName\`" | sudo mysql -u root
                echo "Importing '$tmpRestoreDir/gitea-db.sql' into '$mysqlDBName'"
                sudo mysql -u root "$mysqlDBName" < "$tmpRestoreDir/gitea-db.sql"
                echo "Creating DB users & assigning permissions for gitea"
                echo "CREATE USER IF NOT EXISTS '$mysqlDBUser'@'localhost' IDENTIFIED BY '$mysqlDBPasswd'" | sudo mysql -u root
                echo "GRANT ALL PRIVILEGES ON \`$mysqlDBName\`.* TO '$mysqlDBUser'@'localhost'" | sudo mysql -u root
                echo "FLUSH PRIVILEGES;" | sudo mysql -u root
            ;;
        esac
        needsService=1
    fi
fi
if [[ $needsService == 1 ]]; then
    echo "Reloading systemd daemon"
    sudo systemctl daemon-reload
    echo "Enabling the service"
    sudo systemctl enable "$serviceName"
fi
echo "Restarting gitea service"
sudo service "$serviceName" restart
    #echo "Done! launch gitea when ready."  
cleanup install
exit
#End '../gitea-install/main.sh' [condense.sh]

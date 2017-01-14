#!/bin/bash

PROJECT_NAME="symfony"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOCKER_DIR="$DIR/app/docker"
LOG_PATH="$DIR/var/logs/docker.txt"

SERVICE_REGEX="^nginx|php|mysql$"
SYMFONY_ENV_REGEX="^dev|prod|test$"
SYMFONY_COMMAND_REGEX="^[a-z0-9_]+(:[a-z0-9_]+)*(\s-((a-z)|(-[a-z-]+(=[a-zA-Z0-9/]+))))*$"

# Clear logs
echo "" > ${LOG_PATH}

# ----------------------------- HEADER -----------------------------

Title() {
    printf "\n\e[1;104m ----- $1 ----- \e[0m\n"
}

Warning() {
    printf "\n\e[31;43m$1\e[0m\n"
}

Help() {
    printf "\n\e[2m$1\e[0m\n";
}

Confirm () {
    printf "\n"
    choice=""
    while [ "$choice" != "n" ] && [ "$choice" != "y" ]
    do
        printf "Do you want to continue ? (N/Y)"
        read choice
        choice=$(echo ${choice} | tr '[:upper:]' '[:lower:]')
    done
    if [ "$choice" = "n" ]; then
        printf "\nAbort by user.\n"
        exit 0
    fi
    printf "\n"
}

## ValidateServiceName [service]
ValidateServiceName() {
    if [[ ! $1 =~ $SERVICE_REGEX ]]
    then
        printf "\e[31mInvalid service name\e[0m\n"
        exit 1
    fi
}

## ValidateSymfonyEnvName [env]
ValidateSymfonyEnvName() {
    if [[ ! $1 =~ $SYMFONY_ENV_REGEX ]]
    then
        printf "\e[31mInvalid environment\e[0m\n"
        exit 1
    fi
}

# ----------------------------- NETWORK -----------------------------

NetworkCreate() {
    printf "Creating network \e[1;33m$1\e[0m ... "
    if [[ "$(docker network ls | grep $1)" ]]
    then
        printf "\e[36mexists\e[0m\n"
    else
        docker network create $1 >> ${LOG_PATH} 2>&1 \
            && printf "\e[32mcreated\e[0m\n" \
            || (printf "\e[31merror\e[0m\n" && exit 1)
    fi
}

NetworkRemove() {
    printf "Removing network \e[1;33m$1\e[0m ... "
    if [[ "$(docker network ls | grep $1)" ]]
    then
        docker network rm $1 >> ${LOG_PATH} 2>&1 \
            && printf "\e[32mremoved\e[0m\n" \
            || (printf "\e[31merror\e[0m\n" && exit 1)
    else
        printf "\e[35munknown\e[0m\n"
    fi
}

# ----------------------------- VOLUME -----------------------------

VolumeCreate() {
    printf "Creating volume \e[1;33m$1\e[0m ... "
    if [[ "$(docker volume ls | grep $1)" ]]
    then
        printf "\e[36mexists\e[0m\n"
    else
        docker volume create --name $1 >> ${LOG_PATH} 2>&1 \
            && printf "\e[32mcreated\e[0m\n" \
            || (printf "\e[31merror\e[0m\n" && exit 1)
    fi
}

VolumeRemove() {
    printf "Removing volume \e[1;33m$1\e[0m ... "
    if [[ "$(docker volume ls | grep $1)" ]]
    then
        docker volume rm $1 >> ${LOG_PATH} 2>&1 \
            && printf "\e[32mremoved\e[0m\n" \
            || (printf "\e[31merror\e[0m\n" && exit 1)
    else
        printf "\e[35munknown\e[0m\n"
    fi
}

# ----------------------------- COMPOSE -----------------------------

IsUpAndRunning() {
    if [[ "$(docker ps | grep $1)" ]]
    then
        return 1
    fi
    return 0
}

# ComposeUp
ComposeUp() {
    # Check id other environment is up
    IsUpAndRunning "${PROJECT_NAME}_php"
    if [[ $? -eq 1 ]]
    then
        printf "\e[31mAlready up and running.\e[0m\n"
        exit 1
    fi

    printf "Composing up stack ... "
    cd ${DOCKER_DIR} && \
        docker-compose -f compose.yml up -d >> ${LOG_PATH} 2>&1 \
            && printf "\e[32mdone\e[0m\n" \
            || (printf "\e[31merror\e[0m\n" && exit 1)
}

# ComposeDown
ComposeDown() {
    printf "Composing down stack ... "
    cd ${DOCKER_DIR} && \
        docker-compose -f compose.yml down -v --remove-orphans >> ${LOG_PATH} 2>&1 \
            && printf "\e[32mdone\e[0m\n" \
            || (printf "\e[31merror\e[0m\n" && exit 1)
}

# ComposeBuild
ComposeBuild() {
    printf "Building stack ... "

    cd ${DOCKER_DIR} && \
        docker-compose -f compose.yml build >> ${LOG_PATH} 2>&1 \
            && printf "\e[32mdone\e[0m\n" \
            || (printf "\e[31merror\e[0m\n" && exit 1)
}

# ComposeStart
ComposeStart() {
    printf "Starting stack ... "

    cd ${DOCKER_DIR} && \
        docker-compose -f compose.yml start >> ${LOG_PATH} 2>&1 \
            && printf "\e[32mdone\e[0m\n" \
            || (printf "\e[31merror\e[0m\n" && exit 1)
}

# ComposeRestart
ComposeRestart() {
    ValidateDockerEnvName $1

    printf "Restarting stack ... "

    cd ${DOCKER_DIR} && \
        docker-compose -f compose.yml restart >> ${LOG_PATH} 2>&1 \
            && printf "\e[32mdone\e[0m\n" \
            || (printf "\e[31merror\e[0m\n" && exit 1)
}

# ComposeCreate
ComposeCreate() {
    printf "Creating stack ... "

    cd ${DOCKER_DIR} && \
        docker-compose -f composer.yml create --force-recreate >> ${LOG_PATH} 2>&1 \
            && printf "\e[32mdone\e[0m\n" \
            || (printf "\e[31merror\e[0m\n" && exit 1)
}

# ----------------------------- SERVICE -----------------------------

# ServiceBuild [service]
ServiceBuild() {
    ValidateServiceName $1

    printf "Building \e[1;33m$1\e[0m service ... "

    cd ${DOCKER_DIR} && \
        docker-compose -f compose.yml build $1 >> ${LOG_PATH} 2>&1 \
            && printf "\e[32mdone\e[0m\n" \
            || (printf "\e[31merror\e[0m\n" && exit 1)
}

# ServiceStart [service]
ServiceStart() {
    ValidateServiceName $1

    printf "Starting \e[1;33m$1\e[0m service ... "

    cd ${DOCKER_DIR} && \
        docker-compose -f compose.yml start -d $1 >> ${LOG_PATH} 2>&1 \
            && printf "\e[32mdone\e[0m\n" \
            || (printf "\e[31merror\e[0m\n" && exit 1)
}

# ServiceStop [service]
ServiceStop() {
    ValidateServiceName $1

    printf "Stopping \e[1;33m$1\e[0m service ... "

    cd ${DOCKER_DIR} && \
        docker-compose -f compose.yml stop $1 >> ${LOG_PATH} 2>&1 \
            && printf "\e[32mdone\e[0m\n" \
            || (printf "\e[31merror\e[0m\n" && exit 1)
}

# ServiceRestart [env] [service]
ServiceRestart() {
    ValidateServiceName $1

    printf "Restarting \e[1;33m$1\e[0m service ... "

    cd ${DOCKER_DIR} && \
        docker-compose -f compose.yml restart $1 >> ${LOG_PATH} 2>&1 \
            && printf "\e[32mdone\e[0m\n" \
            || (printf "\e[31merror\e[0m\n" && exit 1)
}

# ServiceCreate [service]
ServiceCreate() {
    ValidateServiceName $1

    printf "Creating \e[1;33m$1\e[0m service ... "

    cd ${DOCKER_DIR} && \
        docker-compose -f compose.yml create --force-recreate $1 >> ${LOG_PATH} 2>&1 \
            && printf "\e[32mdone\e[0m\n" \
            || (printf "\e[31merror\e[0m\n" && exit 1)
}

# ----------------------------- SYMFONY -----------------------------

SfCheckParameters() {
    if [[ ! -f "$DIR/app/config/parameters.yml" ]]
    then
        printf "\e[31mParameters file not found\e[0m\n"
        exit 1;
    fi
}

Execute() {
    ValidateServiceName $1

    printf "Executing [$1] $2\n"

    printf "\n"
    if [[ "$(uname -s)" = \MINGW* ]]
    then
        winpty docker exec -it ${PROJECT_NAME}_$1 $2
    else
        docker exec -it ${PROJECT_NAME}_$1 $2
    fi
    printf "\n"
}

Run() {
    ValidateServiceName $1

    printf "\n"
    printf "Running \e[1;33m$2\e[0m on \e[1;33m$1\e[0m service :\n"

    cd ${DOCKER_DIR} && \
        docker-compose -f compose.yml \
        run --rm $1 $2
}

SfCommand() {
    Execute php "php bin/console $1"
}

Composer() {
    Run php "composer $1"
}

# ----------------------------- INTERNAL -----------------------------

CreateNetworkAndVolumes() {
    NetworkCreate "${PROJECT_NAME}-network"
    VolumeCreate "${PROJECT_NAME}-database"
}

RemoveNetworkAndVolumes() {
    NetworkRemove "${PROJECT_NAME}-network"
    VolumeRemove "${PROJECT_NAME}-database"
}

InitializePhp() {
    [[ $1 != "" ]] && SF_ENV=$1 || SF_ENV=dev
    ValidateSymfonyEnvName ${SF_ENV}

    SfCommand "cache:clear -e ${SF_ENV}"
    SfCommand "assets:install --relative -e ${SF_ENV}"
    SfCommand "doctrine:schema:update --force -e ${SF_ENV}"
}

Reset() {
    ComposeDown
    RemoveNetworkAndVolumes

    sleep 5

    SfCheckParameters
    CreateNetworkAndVolumes
    ComposeUp

    sleep 5

    Execute php "chown -Rf root:root var/cache" >> /dev/null 2>&1
    Execute php "chmod -Rf +rwx var/cache" >> /dev/null 2>&1
    Execute php "rm -Rf var/cache" >> /dev/null 2>&1
    Execute php "mkdir var/cache" >> /dev/null 2>&1
    Execute php "touch var/cache/.gitkeep" >> /dev/null 2>&1
}

# ----------------------------- EXEC -----------------------------

case $1 in
    # -------------- UP --------------
    up)
        SfCheckParameters

        CreateNetworkAndVolumes

        ComposeUp
    ;;
    # ------------- DOWN -------------
    down)
        ComposeDown
    ;;
    # ------------- BUILD -------------
    build)
        if [[ "" != "$2" ]]
        then
            ServiceBuild $2
        else
            ComposeBuild
        fi
    ;;
    # ------------- CREATE -------------
    create)
        if [[ "" != "$2" ]]
        then
            ServiceCreate $2
        else
            ComposeCreate
        fi
    ;;
    # ------------- START -------------
    start)
        if [[ "" != "$2" ]]
        then
            ServiceStart $2
        else
            ComposeStart
        fi
    ;;
    # ------------- RESTART -------------
    restart)
        if [[ "" != "$2" ]]
        then
            ServiceRestart $2
        else
            ComposeRestart
        fi
    ;;
    # ------------- RESET ------------
    reset)
        Title "Resetting stack"
        Warning "All data will be lost !"
        Confirm

        Reset
    ;;
    # ------------- INIT ------------
    init)
        Title "Initializing php container"
        Confirm

        InitializePhp $2
    ;;
    # ------------- EXEC -------------
    exec)
        ValidateServiceName $2

        Execute $2 "${*:3}"
    ;;
    # ------------- SF (command) -------------
    sf)
        SfCommand "${*:2}"
    ;;
    # ------------- RUN -------------
    run)
        ValidateServiceName $2

        Run $2 "${*:3}"
    ;;
    # ------------- COMPOSER -------------
    composer)
        Composer "${*:2}"
    ;;
    # ------------- HELP --------------
    *)
        Help "Usage:  ./manage.sh [action] [options]

\t\e[0mup\e[2m\t\t\t Create and start containers.
\t\e[0mdown\e[2m\t\t\t Stop and remove containers.
\t\e[0mbuild\e[2m [service]\t\t Build the service(s) image(s).
\t\e[0mcreate\e[2m [service]\t Create the service(s) container(s).
\t\e[0mrestart\e[2m [service]\t Restart the service(s) container(s).
\t\e[0mreset\e[2m\t\t\t Reset the containers and data volumes.
\t\e[0minit\e[2m\t\t\t Initialize the php container.
\t\e[0mrun\e[2m service cmd\t\t Run the [command] in a detached [service] container.
\t\e[0mexec\e[2m service cmd\t Execute the [command] in the [service] container.
\t\e[0msf\e[2m command\t\t Run the symfony [command] in the php container.
\t\e[0mcomposer\e[2m command\t Run the composer [command] in the php container."
    ;;
esac

printf "\n"

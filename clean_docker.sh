#!/usr/bin/env bash

option=$1

function docker-cleanup {
  EXITED_CONTAINERS=$(docker ps -aqf status=exited)
  DANGLING_IMAGES=$(docker images -qf "dangling=true")
  DANGLING_VOLUMES=$(docker volume ls  -qf "dangling=true")

    set -e
    case "$option" in
        --dry-run)
                echo " Dry Run ..."
                echo "==> Folllowing Containers will be Stopped:"
                echo $EXITED_CONTAINERS
                echo "==> Folllowing Images will be Removed::"
                echo $DANGLING_IMAGES
                echo "==> Folllowing Volumes will be Removed:"
                echo $DANGLING_VOLUMES
        ;;
        start)
                if [ -n "$EXITED_CONTAINERS" ]; then
                  echo "Removing Containers:"
                  docker rm $EXITED_CONTAINERS
                else
                  echo "No containers to remove."
                fi
                if [ -n "$DANGLING_IMAGES" ]; then
                  echo "Removing Images:"
                  docker rmi $DANGLING_IMAGES
                else
                  echo "No Images to remove."
                fi
                if [ -n "$DANGLING_VOLUMES" ]; then
                  echo "Removing Volumes:"
                  docker volume rm $DANGLING_VOLUMES
                else
                  echo "No Images to remove."
                fi
        ;;
        gc)
                docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v /etc:/etc:ro spotify/docker-gc
        ;;
        *)
            echo "Usage: ./clean_docker.sh {--dry-run | start | gc } " >&2
            exit 1
        ;;
    esac
}

# use --dry-run to see what would happen
docker-cleanup

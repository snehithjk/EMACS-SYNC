if [ "$#" -lt 1 ]
then
  echo "Illegal number of parameters"
  echo "Usage: <array of directories> | <remote (default:origin)> | <sleep_duration in seconds (default:60)> | <storage_limit (default 5000)> | <storage_limit_description> "
  echo
  echo "Arguments:"
  echo "  array of directories: Give as first argument to use old sync logic."
  echo "  remote: Git remote to use."
  echo "  sleep_duration: Wait time between git sync attempts."
  echo "  storage_limit: Memory limit after which sync has to be stopped."
  echo "  storage_limit_description: Description for the limit set. To use in logging."
  exit 1
fi

command=git_sync

ARRAY=("$@")  

shift

if [ "$1" == "" ]
then
  remote="origin"
else
  remote="$1"
fi

shift

if [ "$1" == "" ]
then
  sleep_duration=60
else
  sleep_duration="$1"
fi

shift

if [ "$1" == "" ]
then
  allowed_storage=500000 
  allowed_storage_desc='0.5G'
else
  allowed_storage="$1"
  shift 
  allowed_storage_desc="$1"
fi

shift






function git_sync() {
    dir_path=$1

    cd "$dir_path"

    remote=$2


    git commit -a -m "Emacs bot commit : `date +'%Y-%m-%d %H:%M:%S'`" # commit changes of tracked .org file
    is_commit_made=$? #should return 0 if commit is made

    # git remote update "$remote"
    # is_remote_diverged=$?
    git remote update "$remote"

    if [ "$?" -eq 0 ]
    then
        base_commit=`git merge-base @ @{u}`
        remote_last_commit=`git rev-parse @{u}`
        local_last_commit=`git rev-parse @`
        

        if [ "$local_last_commit" == "$remote_last_commit" ]
        then
          echo "Up to date. Sync not needed!"
        elif [ "$remote_last_commit" == "$base_commit" ]
        then
          git push "$remote" main
        elif [ "$local_last_commit" == "$base_commit" ]
        then
          git pull "$remote" main
        else
          echo "Conflict! Attempting auto merge...."
          git pull "$remote" main
          if [ "$?" -eq 0 ]
          then
              echo "....Merge successful."
              git push "$remote" main
          else
              echo -e "\a Error!!"
              return 1
          fi
        fi
    else
        echo "!! Unexpected error, re-attempting... !!" # for network or other timeouts
    fi
}


if [ -z "$allowed_storage" ]
then
  allowed_storage=500000 
  allowed_storage_desc='0.5G'
fi

while true
do
  for dir in ${ARRAY[@]}
  do
    if [ ! -d "$dir" ]
    then
      echo "Skipping since $dir directory not found!!"
      continue
    fi
    available_storage=$(df -k --output=avail "$dir" | tail -n +2)
    if [ -f "$i/.git-disabled-flag" ]
    then
      echo "Skippig since sync has already for disabled for $dir"
    elif [ "$available_storage" -lt $allowed_storage ]
    then
      touch $dir/.git-disabled-flag
      echo "Disabling sync : $dir storage exceeded allowed limit ($allowed_storage_desc)"
    else
      echo "Performing git_sync for $dir"
      $command "$dir" "$remote" || continue;
    fi
  done

  echo "Sync on hold for: $sleep_duration seconds."
  sleep "$sleep_duration"
done
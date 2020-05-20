#!/bin/bash

usage() {
  echo "Usage: $(basename "$0") sync|delete [-n] --gh-token GH_TOKEN --nr-token NR_TOKEN [--delete]"
}

# https://stackoverflow.com/a/41069638/1872036
catch() {
  eval "$({
    __2="$(
      { __1="$("${@:3}")"; } 2>&1;
      ret=$?;
      printf '%q=%q\n' "$1" "$__1" >&2;
      exit $ret
      )"
    ret="$?";
    printf '%s=%q\n' "$2" "$__2" >&2;
    printf '( exit %q )' "$ret" >&2;
    } 2>&1 )";
}

get_starred_repos() {
  local token="$1"
  local gh_username

  cd "$(readlink -f "$(dirname "$0")")" || exit 9

  gh_username="$(./github.sh "$token" /user | jq -r '.login')"

  if [[ -z "$gh_username" ]]
  then
    echo "Failed to determine GitHub username" >&2
    return 8
  fi

  ./github.sh "$token" "/users/${gh_username}/starred" | \
    jq -r '.[].full_name' | \
    sort -f
}

_nr() {
  local extra_args=()

  if [[ -n "$NR_TOKEN" ]]
  then
    extra_args+=(--auth-key "$NR_TOKEN")
  fi

  newreleases "$@" "${extra_args[@]}"
}

nr() {
  local stderr
  local stdout

  while true
  do
    if catch stdout stderr _nr "$@"
    then
      echo "$stdout"
      return
    else
      if grep -qi "too many requests" <<< "$stderr"
      then
        echo "Too many requests. We need to wait to continue." >&2
        sleep 10m
      else
        echo "$stderr" >&2
        return 1
      fi
    fi
  done
}

get_discord_channel_id() {
  # Get first discord channel ID
  # NOTE This is *not* the Discord chan ID you can copy from the Discord UI
  nr discord | awk '!/^ID/{ print $1; exit }'
}

is_already_subscribed() {
  local repo="$1"

  for proj in $(nr project search "$repo" --provider github | \
                awk '!/^ID/ { print $2 }')
  do
    if [[ "$proj" == "$repo" ]]
    then
      return
    fi
  done
  return 1
}

nr_list_gh_sub_page() {
  local page="$1"

  nr project list --provider github -p "$page" 2>/dev/null | \
    awk '!/^ID/ { print $2 }'
}

nr_list_all_subscriptions() {
  local res
  local page=1
  local proj
  local projects=()

  while res="$(nr_list_gh_sub_page "$page")"
  do
    echo "Processing page ${page}" >&2

    while read -r proj
    do
      if [[ -z "$proj" ]]
      then
        # No more projects, return output
        for proj in "${projects[@]}"
        do
          echo "$proj"
        done
        return
      fi
      projects+=("$proj")
    done <<< "$res"

    page=$(( page + 1 ))

    # DEBUG
    echo "Current project list: ${projects[*]}" >&2
  done
}

nr_subscribe() {
  local repo="$1"
  local chan_id="${2:-$(get_discord_channel_id)}"
  local email_freq=none
  local action=add

  echo "Subscribing to $repo"

  if is_already_subscribed "$repo"
  then
    echo "Already subscribed to $repo. Updating." >&2
    action=update
  fi

  nr project "$action" github "$repo" \
    --exclude-prereleases \
    --email "$email_freq" \
    --discord "$chan_id"
}

nr_unsubscribe() {
  echo "Unsubscribing from $1"
  nr project remove github "$1"
}

sync_deletions() {
  local starred_repos
  local nr_projects
  local delete_repo

  mapfile -t starred_repos < <(get_starred_repos "$GITHUB_TOKEN")
  mapfile -t nr_projects < <(nr_list_all_subscriptions)

  if [[ -z "${starred_repos[*]}" ]]
  then
    echo "Failed to retrieve list of starred repos" >&2
    return 7
  fi

  if [[ -z "${nr_projects[*]}" ]]
  then
    echo "Failed to retrieve list of subscribed repositories" >&2
    return 9
  fi

  for proj in "${nr_projects[@]}"
  do
    delete_repo=1

    for repo in "${starred_repos[@]}"
    do
      if [[ "$repo" == "$proj" ]]
      then
        delete_repo=0
        break
      fi
    done

    if [[ "$delete_repo" == "1" ]]
    then
      if [[ -n "$DRYRUN" ]]
      then
        echo "DRY RUN: Would delete subscription to $proj" >&2
      else
        nr_unsubscribe "$proj"
      fi
    fi
  done
}

sync_starred() {
  local discord_channel_id
  local proj
  local starred_repos

  discord_channel_id="$(get_discord_channel_id)"

  if [[ -z "$discord_channel_id" ]]
  then
    echo "Unable to determine discord channel ID." >&2
    return 3
  fi

  # DEBUG
  # starred_repos="$1"
  # starred_repos="$(cat /tmp/stars_part2)"
  mapfile -t starred_repos < <(get_starred_repos "$GITHUB_TOKEN")

  if [[ -z "${starred_repos[*]}" ]]
  then
    echo "Failed to retrieve list of starred repos" >&2
    return 7
  fi

  for proj in "${starred_repos[@]}"
  do
    if [[ -n "$DRYRUN" ]]
    then
      echo "DRY RUN: Would subscribe to $proj" >&2
    else
      if ! nr_subscribe "$proj" "$discord_channel_id"
      then
        echo "SHIT." >&2
        return 7
        break
      fi
    fi
  done

  if [[ -n "$DELETE" ]]
  then
    sync_deletions
  fi
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  # Default action
  ACTION=sync

  case "$1" in
    help|h|-h|--help)
      usage
      exit 0
      ;;
    sync)
      ACTION=sync
      shift
      ;;
    delete)
      ACTION=delete
      shift
      ;;
  esac

  while [[ -n "$*" ]]
  do
    case "$1" in
      --delete|-d)
        # FIXME delete --delete is redundant
        DELETE=1
        shift
        ;;
      --nr-token|-t)
        NR_TOKEN="$2"
        shift 2
        ;;
      --gh-token|-g)
        GITHUB_TOKEN="$2"
        shift 2
        ;;
      --dryrun|-n)
        DRYRUN=1
        shift
        ;;
      *)
        echo "Unknown option: $1"
        usage
        exit 2
        ;;
    esac
  done

  if [[ -z "$GITHUB_TOKEN" ]]
  then
    echo "Missing GitHub token (--token TOKEN)" >&2
    exit 5
  fi

  case "$ACTION" in
    sync)
      sync_starred
      ;;
    delete)
      sync_deletions
      ;;
    *)
      echo "Unknown action: $ACTION" >&2
      exit 4
      ;;
  esac
fi

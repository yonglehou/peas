#!/bin/bash
set -e
exec 2>&1 # Redirect STDERR and STDOUT to STDOUT

function finish {
  echo "EXIT FROM CI-SERVER"
}
trap finish EXIT

# Don't forget to setup the Peas repo with:
# git config --add remote.origin.fetch '+refs/pull/*/head:refs/pull/origin/*'
# It brings down pull requests.
# And installs tombh/peas, bundler and mongodb.
# And gives the ci user the docker group: `gpasswd -a ci docker`

SCRIPTPATH=$( cd $(dirname $0) ; pwd -P )/ci-server.sh
PEAS_ROOT="$HOME"/repo

# Because the integration spec_helper bind mounts the live code onto the container we need to make
# sure that no gems are mounted in the process, like through vendor/bundle. So we install gems
# outside the project' path.
export GEM_HOME="$HOME"/.gem

# Handle an incoming request from Travis to run the integration tests
if [ "$1" == "--run-tests" ]; then
  echo "Request to run integration tests accepted..."
  count=0
  while docker ps | grep -q Up; do
    [ $count == 0 ] && echo "Waiting for existing integration test to finish..."
    sleep 1
    count=$(($count + 1))
    if [ $count -gt 900 ]; then
      echo "Waited more than 15 mins, aborting..."
      exit 1
    fi
  done
  read -r sha # read the first line to STDIN
  cleaned_ref=$(echo "$sha" | sed -r 's/[^[:alnum:]]//g') # sanitise for security
  if [ -z "$cleaned_ref" ]; then
    echo "No commit to test"
    exit 1
  fi
  cd $PEAS_ROOT
  # Checkout the commit triggered by Travis CI
  git fetch -a
  if echo $cleaned_ref | grep -q "pullrequest"; then
    # Need to do the special Github trick to checkout PRs
    pr_num=${cleaned_ref#pullrequest} # Strip 'pullrequest' from beginning of string
    echo "Checkout Pull Request $pr_num..."
    git checkout "pull/origin/$pr_num"
  else
    # If there's no Pull Request just checkout the SHA hash
    echo "Checking out $cleaned_ref ..."
    git checkout $cleaned_ref
  fi
  # Rebuild the Dockerfile in case the commit includes any unbuilt changes to the Dockerfile
  echo "Rebuilding Dockerfile..."
  docker build --no-cache -t tombh/peas . > /dev/null
  echo "Deleting untagged Docker images..."
  docker ps -a | grep -v peas-data-test | grep 'Exited' | awk '{print $1}' | xargs --no-run-if-empty docker rm
  docker rmi $(docker images | grep "^<none>" | tr -s ' ' | cut -d ' ' -f 3)
  # Install dependencies for the CLI client (needed to run the integration tests)
  cd $PEAS_ROOT/cli
  echo "Installing CLI dependencies..."
  # Main application tests
  cd $PEAS_ROOT
  echo "Installing API dependencies..."
  bundle install
  echo "Running main application tests..."
  CODECLIMATE_REPO_TOKEN=6ff1de0d4310127c6f8e34ea13d71c9b335ca58f24656265ed93d6a01726a5b2 bundle exec rspec
  echo "Running integration tests..."
  bundle exec rspec spec/integration --tag integration --tag service

# Run the CI server
elif [ "$1" == "--server" ]; then
  # Yes, the ncat server and the code it runs for each connection is all here in the same file -
  # just keeps things simple and together in one place.
  echo "Starting Ncat CI server..."
  ncat -vvv --listen --keep-open --max-conns 6 --source-port 7000 --sh-exec "$SCRIPTPATH --run-tests"
fi

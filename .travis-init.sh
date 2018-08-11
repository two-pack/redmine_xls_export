#/bin/bash

if [[ ! "$WORKSPACE" = /* ]] ||
   [[ ! "$PATH_TO_PLUGIN" = /* ]] ||
   [[ ! "$PATH_TO_REDMINE" = /* ]];
then
  echo "You should set"\
       " WORKSPACE, PATH_TO_PLUGIN, PATH_TO_REDMINE"\
       " environment variables"
  echo "You set:"\
       "$WORKSPACE"\
       "$PATH_TO_PLUGIN"\
       "$PATH_TO_REDMINE"
  exit 1;
fi

case $REDMINE_VERSION in
  1.4.*)  export PATH_TO_PLUGINS=./vendor/plugins # for redmine < 2.0
          export GENERATE_SECRET=generate_session_store
          export REDMINE_TARBALL=https://github.com/redmine/redmine/archive/$REDMINE_VERSION.tar.gz
          ;;
  2.* | 3.*)  export PATH_TO_PLUGINS=./plugins # for redmine 2.x and 3.x
          export GENERATE_SECRET=generate_secret_token
          export REDMINE_TARBALL=https://github.com/redmine/redmine/archive/$REDMINE_VERSION.tar.gz
          ;;
  master) export PATH_TO_PLUGINS=./plugins
          export GENERATE_SECRET=generate_secret_token
          export REDMINE_GIT_REPO=https://github.com/redmine/redmine.git
          export REDMINE_GIT_TAG=master
          ;;
  *)      echo "Unsupported platform $REDMINE_VERSION"
          exit 1
          ;;
esac

export BUNDLE_GEMFILE=$PATH_TO_REDMINE/Gemfile

clone_redmine() {
  set -e # exit if clone fails
  rm -rf $PATH_TO_REDMINE
  if [ ! "$VERBOSE" = "yes" ]; then
    QUIET=--quiet
  fi
  if [ -n "${REDMINE_GIT_TAG}" ]; then
    git clone -b $REDMINE_GIT_TAG --depth=100 $QUIET $REDMINE_GIT_REPO $PATH_TO_REDMINE
    cd $PATH_TO_REDMINE
    git checkout $REDMINE_GIT_TAG
  else
    mkdir -p $PATH_TO_REDMINE
    wget $REDMINE_TARBALL -O- | tar -C $PATH_TO_REDMINE -xz --strip=1 --show-transformed -f -
  fi
}

run_tests() {
  # exit if tests fail
  set -e

  cd $PATH_TO_REDMINE

  if [ "$VERBOSE" = "yes" ]; then
    TRACE=--trace
  fi

  script -e -c "bundle exec rake redmine:plugins:test NAME="$PLUGIN $VERBOSE
}

run_install() {
  # exit if install fails
  set -e

  # cd to redmine folder
  cd $PATH_TO_REDMINE

  # create a link to the plugin, but avoid recursive link.
  if [ -L "$PATH_TO_PLUGINS/$PLUGIN" ]; then rm "$PATH_TO_PLUGINS/$PLUGIN"; fi
  ln -s "$PATH_TO_PLUGIN" "$PATH_TO_PLUGINS/$PLUGIN"

  if [ "$VERBOSE" = "yes" ]; then
    export TRACE=--trace
  fi

  cp $PATH_TO_PLUGINS/$PLUGIN/.travis-database.yml config/database.yml

  # install gems
  mkdir -p vendor/bundle
  RETRYCOUNT=0
  STATUS=1
  until [ ${RETRYCOUNT} -ge 5 ]
  do
    bundle install --path vendor/bundle && STATUS=0 && break
    echo 'Try bundle again ...'
    RETRYCOUNT=$[${RETRYCOUNT}+1]
    sleep 1
  done
  if [ ${STATUS} -eq 1 ]; then
    echo 'bundle install errors are happened 5 times...'
    exit 1;
  fi

  bundle exec rake db:migrate $TRACE
  bundle exec rake redmine:load_default_data REDMINE_LANG=en $TRACE
  bundle exec rake $GENERATE_SECRET $TRACE
}

while getopts :irtu opt
do case "$opt" in
  r)  clone_redmine; exit 0;;
  i)  run_install;  exit 0;;
  t)  run_tests $2;  exit 0;;
  [?]) echo "i: install; r: clone redmine; t: run tests";;
  esac
done
#!/bin/bash

#=================================================
# COMMON VARIABLES
#=================================================

# dependencies used by the app
pkg_dependencies="imagemagick ffmpeg libpq-dev libxml2-dev libxslt1-dev file git-core g++ libprotobuf-dev protobuf-compiler pkg-config gcc autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm3|libgdbm6 libgdbm-dev redis-server redis-tools postgresql postgresql-contrib libidn11-dev libicu-dev libjemalloc-dev curl apt-transport-https"

MEMORY_NEEDED="2560"

RUBY_VERSION="3.0.3"

NODEJS_VERSION="12"

# Workaround for Mastodon on Bullseye
# See https://github.com/mastodon/mastodon/issues/15751#issuecomment-873594463
if [ "$(lsb_release --codename --short)" = "bullseye" ]; then
    case $YNH_ARCH in
        amd64)
            arch="x86_64"
            ;;
        arm64)
            arch="aarch64"
            ;;
        armel|armhf)
            arch="arm"
            ;;
        i386)
            arch="i386"
            ;;
    esac
    ld_preload="LD_PRELOAD=/usr/lib/$arch-linux-gnu/libjemalloc.so"
else
    ld_preload=""
fi

#=================================================
# PERSONAL HELPERS
#=================================================

#=================================================
# EXPERIMENTAL HELPERS
#=================================================

# Add swap
#
# usage: ynh_add_swap --size=SWAP in Mb
# | arg: -s, --size= - Amount of SWAP to add in Mb.
ynh_add_swap () {
	# Declare an array to define the options of this helper.
	declare -Ar args_array=( [s]=size= )
	local size
	# Manage arguments with getopts
	ynh_handle_getopts_args "$@"

	local swap_max_size=$(( $size * 1024 ))

	local free_space=$(df --output=avail / | sed 1d)
	# Because we don't want to fill the disk with a swap file, divide by 2 the available space.
	local usable_space=$(( $free_space / 2 ))

 	SD_CARD_CAN_SWAP=${SD_CARD_CAN_SWAP:-0}

	# Swap on SD card only if it's is specified
	if ynh_is_main_device_a_sd_card && [ "$SD_CARD_CAN_SWAP" == "0" ]
	then
		ynh_print_warn --message="The main mountpoint of your system '/' is on an SD card, swap will not be added to prevent some damage of this one, but that can cause troubles for the app $app. If you still want activate the swap, you can relaunch the command preceded by 'SD_CARD_CAN_SWAP=1'"
		return
	fi

	# Compare the available space with the size of the swap.
	# And set a acceptable size from the request
	if [ $usable_space -ge $swap_max_size ]
	then
		local swap_size=$swap_max_size
	elif [ $usable_space -ge $(( $swap_max_size / 2 )) ]
	then
		local swap_size=$(( $swap_max_size / 2 ))
	elif [ $usable_space -ge $(( $swap_max_size / 3 )) ]
	then
		local swap_size=$(( $swap_max_size / 3 ))
	elif [ $usable_space -ge $(( $swap_max_size / 4 )) ]
	then
		local swap_size=$(( $swap_max_size / 4 ))
	else
		echo "Not enough space left for a swap file" >&2
		local swap_size=0
	fi

	# If there's enough space for a swap, and no existing swap here
	if [ $swap_size -ne 0 ] && [ ! -e /swap_$app ]
	then
		# Preallocate space for the swap file, fallocate may sometime not be used, use dd instead in this case
		if ! fallocate -l ${swap_size}K /swap_$app
		then
			dd if=/dev/zero of=/swap_$app bs=1024 count=${swap_size}
		fi
		chmod 0600 /swap_$app
		# Create the swap
		mkswap /swap_$app
		# And activate it
		swapon /swap_$app
		# Then add an entry in fstab to load this swap at each boot.
		echo -e "/swap_$app swap swap defaults 0 0 #Swap added by $app" >> /etc/fstab
	fi
}

ynh_del_swap () {
	# If there a swap at this place
	if [ -e /swap_$app ]
	then
		# Clean the fstab
		sed -i "/#Swap added by $app/d" /etc/fstab
		# Desactive the swap file
		swapoff /swap_$app
		# And remove it
		rm /swap_$app
	fi
}

# Check if the device of the main mountpoint "/" is an SD card
#
# [internal]
#
# return 0 if it's an SD card, else 1
ynh_is_main_device_a_sd_card () {
	local main_device=$(lsblk --output PKNAME --noheadings $(findmnt / --nofsroot --uniq --output source --noheadings --first-only))

	if echo $main_device | grep --quiet "mmc" && [ $(tail -n1 /sys/block/$main_device/queue/rotational) == "0" ]
	then
		return 0
	else
		return 1
	fi
}

#=================================================
# FUTURE OFFICIAL HELPERS
#=================================================

# ynh_install_ruby__2
ynh_ruby_try_bash_extension() {
  if [ -x src/configure ]; then
    src/configure && make -C src || {
      ynh_print_info --message="Optional bash extension failed to build, but things will still work normally."
    }
  fi
}

rbenv_install_dir="/opt/rbenv"
ruby_version_path="$rbenv_install_dir/versions"
# RBENV_ROOT is the directory of rbenv, it needs to be loaded as a environment variable.
export RBENV_ROOT="$rbenv_install_dir"
export rbenv_root="$rbenv_install_dir"

# Load the version of Ruby for an app, and set variables.
#
# ynh_use_ruby has to be used in any app scripts before using Ruby for the first time.
# This helper will provide alias and variables to use in your scripts.
#
# To use gem or Ruby, use the alias `ynh_gem` and `ynh_ruby`
# Those alias will use the correct version installed for the app
# For example: use `ynh_gem install` instead of `gem install`
#
# With `sudo` or `ynh_exec_as`, use instead the fallback variables `$ynh_gem` and `$ynh_ruby`
# And propagate $PATH to sudo with $ynh_ruby_load_path
# Exemple: `ynh_exec_as $app $ynh_ruby_load_path $ynh_gem install`
#
# $PATH contains the path of the requested version of Ruby.
# However, $PATH is duplicated into $ruby_path to outlast any manipulation of $PATH
# You can use the variable `$ynh_ruby_load_path` to quickly load your Ruby version
#  in $PATH for an usage into a separate script.
# Exemple: $ynh_ruby_load_path $final_path/script_that_use_gem.sh`
#
#
# Finally, to start a Ruby service with the correct version, 2 solutions
#  Either the app is dependent of Ruby or gem, but does not called it directly.
#  In such situation, you need to load PATH
#    `Environment="__YNH_RUBY_LOAD_ENV_PATH__"`
#    `ExecStart=__FINALPATH__/my_app`
#     You will replace __YNH_RUBY_LOAD_ENV_PATH__ with $ynh_ruby_load_path
#
#  Or Ruby start the app directly, then you don't need to load the PATH variable
#    `ExecStart=__YNH_RUBY__ my_app run`
#     You will replace __YNH_RUBY__ with $ynh_ruby
#
#
# one other variable is also available
#   - $ruby_path: The absolute path to Ruby binaries for the chosen version.
#
# usage: ynh_use_ruby
#
# Requires YunoHost version 3.2.2 or higher.
ynh_use_ruby () {
    ruby_version=$(ynh_app_setting_get --app=$app --key=ruby_version)

    # Get the absolute path of this version of Ruby
    ruby_path="$ruby_version_path/$YNH_APP_INSTANCE_NAME/bin"

    # Allow alias to be used into bash script
    shopt -s expand_aliases

    # Create an alias for the specific version of Ruby and a variable as fallback
    ynh_ruby="$ruby_path/ruby"
    alias ynh_ruby="$ynh_ruby"
    # And gem
    ynh_gem="$ruby_path/gem"
    alias ynh_gem="$ynh_gem"

    # Load the path of this version of Ruby in $PATH
    if [[ :$PATH: != *":$ruby_path"* ]]; then
        PATH="$ruby_path:$PATH"
    fi
    # Create an alias to easily load the PATH
    ynh_ruby_load_path="PATH=$PATH"

    # Sets the local application-specific Ruby version
    pushd $final_path
        $rbenv_install_dir/bin/rbenv local $ruby_version
    popd
}

# Install a specific version of Ruby
#
# ynh_install_ruby will install the version of Ruby provided as argument by using rbenv.
#
# This helper creates a /etc/profile.d/rbenv.sh that configures PATH environment for rbenv
# for every LOGIN user, hence your user must have a defined shell (as opposed to /usr/sbin/nologin)
#
# Don't forget to execute ruby-dependent command in a login environment
# (e.g. sudo --login option)
# When not possible (e.g. in systemd service definition), please use direct path
# to rbenv shims (e.g. $RBENV_ROOT/shims/bundle)
#
# usage: ynh_install_ruby --ruby_version=ruby_version
# | arg: -v, --ruby_version= - Version of ruby to install.
#
# Requires YunoHost version 3.2.2 or higher.
ynh_install_ruby () {
    # Declare an array to define the options of this helper.
    local legacy_args=v
    local -A args_array=( [v]=ruby_version= )
    local ruby_version
    # Manage arguments with getopts
    ynh_handle_getopts_args "$@"

    # Load rbenv path in PATH
    local CLEAR_PATH="$rbenv_install_dir/bin:$PATH"

    # Remove /usr/local/bin in PATH in case of Ruby prior installation
    PATH=$(echo $CLEAR_PATH | sed 's@/usr/local/bin:@@')

    # Move an existing Ruby binary, to avoid to block rbenv
    test -x /usr/bin/ruby && mv /usr/bin/ruby /usr/bin/ruby_rbenv

    # Install or update rbenv
    rbenv="$(command -v rbenv $rbenv_install_dir/bin/rbenv | grep "$rbenv_install_dir/bin/rbenv" | head -1)"
    if [ -n "$rbenv" ]; then
        ynh_print_info --message="rbenv already seems installed in \`$rbenv'."
        pushd "${rbenv%/*/*}"
            if git remote -v 2>/dev/null | grep "https://github.com/rbenv/rbenv.git"; then
                ynh_print_info --message="Trying to update with git..."
                git pull -q --tags origin master
                ynh_ruby_try_bash_extension
            else
                ynh_print_info --message="Reinstalling rbenv with git..."
                cd ..
                ynh_secure_remove --file=$rbenv_install_dir
                mkdir -p $rbenv_install_dir
                cd $rbenv_install_dir
                git init -q
                git remote add -f -t master origin https://github.com/rbenv/rbenv.git > /dev/null 2>&1
                git checkout -q -b master origin/master
                ynh_ruby_try_bash_extension
                rbenv=$rbenv_install_dir/bin/rbenv
            fi
        popd
    else
        ynh_print_info --message="Installing rbenv with git..."
        mkdir -p $rbenv_install_dir
        pushd $rbenv_install_dir
            git init -q
            git remote add -f -t master origin https://github.com/rbenv/rbenv.git > /dev/null 2>&1
            git checkout -q -b master origin/master
            ynh_ruby_try_bash_extension
            rbenv=$rbenv_install_dir/bin/rbenv
        popd
    fi

    ruby_build="$(command -v "$rbenv_install_dir"/plugins/*/bin/rbenv-install rbenv-install | head -1)"
    if [ -n "$ruby_build" ]; then
        ynh_print_info --message="\`rbenv install' command already available in \`$ruby_build'."
        pushd "${ruby_build%/*/*}"
            if git remote -v 2>/dev/null | grep "https://github.com/rbenv/ruby-build.git"; then
                ynh_print_info --message="Trying to update rbenv with git..."
                git pull -q origin master
            fi
        popd
    else
        ynh_print_info --message="Installing ruby-build with git..."
        mkdir -p "${rbenv_install_dir}/plugins"
        git clone -q https://github.com/rbenv/ruby-build.git "${rbenv_install_dir}/plugins/ruby-build"
    fi

    rbenv_alias="$(command -v "$rbenv_install_dir"/plugins/*/bin/rbenv-alias rbenv-alias | head -1)"
    if [ -n "$rbenv_alias" ]; then
        ynh_print_info --message="\`rbenv alias' command already available in \`$rbenv_alias'."
        pushd "${rbenv_alias%/*/*}"
            if git remote -v 2>/dev/null | grep "https://github.com/tpope/rbenv-aliases.git"; then
                ynh_print_info --message="Trying to update rbenv-aliases with git..."
                git pull -q origin master
            fi
        popd
    else
        ynh_print_info --message="Installing rbenv-aliases with git..."
        mkdir -p "${rbenv_install_dir}/plugins"
        git clone -q https://github.com/tpope/rbenv-aliases.git "${rbenv_install_dir}/plugins/rbenv-aliase"
    fi

    rbenv_latest="$(command -v "$rbenv_install_dir"/plugins/*/bin/rbenv-latest rbenv-latest | head -1)"
    if [ -n "$rbenv_latest" ]; then
        ynh_print_info --message="\`rbenv latest' command already available in \`$rbenv_latest'."
        pushd "${rbenv_latest%/*/*}"
            if git remote -v 2>/dev/null | grep "https://github.com/momo-lab/xxenv-latest.git"; then
                ynh_print_info --message="Trying to update xxenv-latest with git..."
                git pull -q origin master
            fi
        popd
    else
        ynh_print_info --message="Installing xxenv-latest with git..."
        mkdir -p "${rbenv_install_dir}/plugins"
        git clone -q https://github.com/momo-lab/xxenv-latest.git "${rbenv_install_dir}/plugins/xxenv-latest"
    fi

    # Enable caching
    mkdir -p "${rbenv_install_dir}/cache"

    # Create shims directory if needed
    mkdir -p "${rbenv_install_dir}/shims"

    # Restore /usr/local/bin in PATH
    PATH=$CLEAR_PATH

    # And replace the old Ruby binary
    test -x /usr/bin/ruby_rbenv && mv /usr/bin/ruby_rbenv /usr/bin/ruby

    # Install the requested version of Ruby
    local final_ruby_version=$(rbenv latest --print $ruby_version)
    if ! [ -n "$final_ruby_version" ]; then
        final_ruby_version=$ruby_version
    fi
    ynh_print_info --message="Installing Ruby-$final_ruby_version"
    CONFIGURE_OPTS="--disable-install-doc --with-jemalloc" MAKE_OPTS="-j2" rbenv install --skip-existing $final_ruby_version > /dev/null 2>&1

    # Store ruby_version into the config of this app
    ynh_app_setting_set --app=$YNH_APP_INSTANCE_NAME --key=ruby_version --value=$final_ruby_version

    # Remove app virtualenv
    if  `rbenv alias --list | grep --quiet "$YNH_APP_INSTANCE_NAME " 1>/dev/null 2>&1`
    then
        rbenv alias $YNH_APP_INSTANCE_NAME --remove
    fi

    # Create app virtualenv
    rbenv alias $YNH_APP_INSTANCE_NAME $final_ruby_version

    # Cleanup Ruby versions
    ynh_cleanup_ruby

    # Set environment for Ruby users
    echo  "#rbenv
export RBENV_ROOT=$rbenv_install_dir
export PATH=\"$rbenv_install_dir/bin:$PATH\"
eval \"\$(rbenv init -)\"
#rbenv" > /etc/profile.d/rbenv.sh

    # Load the environment
    eval "$(rbenv init -)"
}

# Remove the version of Ruby used by the app.
#
# This helper will also cleanup Ruby versions
#
# usage: ynh_remove_ruby
ynh_remove_ruby () {
    local ruby_version=$(ynh_app_setting_get --app=$YNH_APP_INSTANCE_NAME --key=ruby_version)

    # Load rbenv path in PATH
    local CLEAR_PATH="$rbenv_install_dir/bin:$PATH"

    # Remove /usr/local/bin in PATH in case of Ruby prior installation
    PATH=$(echo $CLEAR_PATH | sed 's@/usr/local/bin:@@')

    rbenv alias $YNH_APP_INSTANCE_NAME --remove

    # Remove the line for this app
    ynh_app_setting_delete --app=$YNH_APP_INSTANCE_NAME --key=ruby_version

    # Cleanup Ruby versions
    ynh_cleanup_ruby
}

# Remove no more needed versions of Ruby used by the app.
#
# This helper will check what Ruby version are no more required,
# and uninstall them
# If no app uses Ruby, rbenv will be also removed.
#
# usage: ynh_cleanup_ruby
ynh_cleanup_ruby () {

    # List required Ruby versions
    local installed_apps=$(yunohost app list | grep -oP 'id: \K.*$')
    local required_ruby_versions=""
    for installed_app in $installed_apps
    do
        local installed_app_ruby_version=$(ynh_app_setting_get --app=$installed_app --key="ruby_version")
        if [[ $installed_app_ruby_version ]]
        then
            required_ruby_versions="${installed_app_ruby_version}\n${required_ruby_versions}"
        fi
    done
    
    # Remove no more needed Ruby versions
    local installed_ruby_versions=$(rbenv versions --bare --skip-aliases | grep -Ev '/')
    for installed_ruby_version in $installed_ruby_versions
    do
        if ! `echo ${required_ruby_versions} | grep "${installed_ruby_version}" 1>/dev/null 2>&1`
        then
            ynh_print_info --message="Removing of Ruby-$installed_ruby_version"
            $rbenv_install_dir/bin/rbenv uninstall --force $installed_ruby_version
        fi
    done

    # If none Ruby version is required
    if [[ ! $required_ruby_versions ]]
    then
        # Remove rbenv environment configuration
        ynh_print_info --message="Removing of rbenv-$rbenv_version"
        ynh_secure_remove --file="$rbenv_install_dir"
        ynh_secure_remove --file="/etc/profile.d/rbenv.sh"
    fi
}



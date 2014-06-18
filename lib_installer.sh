

ALTERNC_VERSION="Alternc 3.2"
DEBIAN_VERSION="Wheezy Debian"
DEBIAN_VERSION_NUMBER="7"

# translations
# @see http://mywiki.wooledge.org/BashFAQ/098
export TEXTDOMAIN=alternc-easy-install
export TEXTDOMAINDIR=$(pwd)/translations

COL_GRAY="\x1b[30;01m"
COL_RED="\x1b[31;01m"
COL_GREEN="\x1b[32;01m"
COL_YELLOW="\x1b[33;01m"
COL_BLUE="\x1b[34;01m"
COL_PURPLE="\x1b[35;01m"
COL_CYAN="\x1b[36;01m"
COL_WHITE="\x1b[37;01m"
COL_RESET="\x1b[39;49;00m"

E_CDERROR=65

#Alternc variables
ALTERNC_ACLUNINSTALLED=""
ALTERNC_ALTERNC_HTML=/var/alternc/html
ALTERNC_ALTERNC_LOCATION=/var/alternc
ALTERNC_ALTERNC_LOGS=/var/log/alternc/sites/
ALTERNC_ALTERNC_MAIL=/var/alternc/mail
ALTERNC_DEFAULT_MX2=""
ALTERNC_DEFAULT_MX=""
ALTERNC_DESKTOPNAME=""
ALTERNC_HOSTINGNAME=Alternc
ALTERNC_INTERNAL_IP=""
ALTERNC_MONITOR_IP=""
ALTERNC_MYSQL_ALTERNC_MAIL_PASSWORD=""
ALTERNC_MYSQL_ALTERNC_MAIL_USER=""
ALTERNC_MYSQL_CLIENT=localhost
ALTERNC_MYSQL_DB=alternc
ALTERNC_MYSQL_HOST="127.0.0.1"
ALTERNC_MYSQL_PASSWORD=""
ALTERNC_MYSQL_REMOTE_PASSWORD=""
ALTERNC_MYSQL_REMOTE_USER=""
ALTERNC_MYSQL_USER=sysusr
ALTERNC_NS1=""
ALTERNC_NS2=""
ALTERNC_POP_BEFORE_SMTP_WARNING=""
ALTERNC_POSTRM_REMOVE_BIND=""
ALTERNC_POSTRM_REMOVE_DATABASES=""
ALTERNC_POSTRM_REMOVE_DATAFILES=""
ALTERNC_POSTRM_REMOVE_MAILBOXES=""
ALTERNC_PUBLIC_IP=""
ALTERNC_QUOTAUNINSTALLED=false
ALTERNC_REMOTE_MYSQL_ERROR=""
ALTERNC_SLAVES=""
ALTERNC_SQL_BACKUP_OVERWRITE=no
ALTERNC_SQL_BACKUP_TYPE=rotate
ALTERNC_USE_LOCAL_MYSQL=true
ALTERNC_USE_PRIVATE_IP=""
ALTERNC_USE_REMOTE_MYSQL=""
ALTERNC_WELCOMECONFIRM=true


# Some variables defined per design for the user
ALTERNC_PHPMYADMIN_WEBSERVER="apache2"
ALTERNC_PHPMYADMIN_DBCONFIG="true"
ALTERNC_POSTFIX_MAILERTYPE="Internet Site"
ALTERNC_PROFTPD_STANDALONE="standalone"
ALTERNC_MAILMAN_SITE_LANGUAGES="fr, en"
ALTERNC_MAILMAN_DEFAULT_SERVER_LANGUAGE="fr"
ALTERNC_MAILMAN_USED_LANGUAGES="fr en"
ALTERNC_MAILMAN_CREATE_SITE_LIST=""
ALTERNC_MAILMAN_PATCH_MAILMAN="true"


ADDITIONAL_PACKAGES=""
VAR_SKIP=0
VAR_TEST_IP=91.194.60.1
VAR_HAS_NET=0


# Output utilities

debug() {

	echo -e $COL_PURPLE;
	local format=$1
	printf "$(gettext -d $TEXTDOMAIN -s "$format")" "$@" >&1
	echo -e $COL_RESET;
}

misc() {
	
	echo -e $COL_GRAY;
	local format=$1
	printf "$(gettext -d $TEXTDOMAIN -s "$format")" "$@" >&1
	echo -e $COL_RESET;

}
ask() {
	echo -e $COL_WHITE;
	local format="$1"
	printf "$(gettext -d $TEXTDOMAIN -s "$format")" "$@" >&1
	echo -e $COL_RESET;

}
spacer() {
	
	echo -e $COL_GRAY;
	echo -e " - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	echo -e $COL_RESET;

}

info() {
	
	echo -e $COL_GREEN;
	local format=$@
	printf "$(gettext -d $TEXTDOMAIN -s "$format")" "$@"
	echo -e $COL_RESET;

}

warn() {

	echo -e $COL_RED;
	local format=$1
	shift
	printf "$(gettext -d $TEXTDOMAIN -s "$format")" "$@" >&1
	echo -e $COL_RESET;

}

alert() {

	echo -e $COL_RED;
	local format=$1
	shift
	printf "\nA critical error occured: " >&2
	printf "$(gettext -d $TEXTDOMAIN -s "$format")" "$@" >&2
	printf "\nExiting. " >&2
	echo -e $COL_RESET;
	exit $E_CDERROR

}

try_exit() {
	if [ -z $1 ] ; then
		ask "Do you want to exit the installer? (y/N) "
	else
		ask $1;
	fi;
	read VAR_SKIP;
	if [[ "y" == ${VAR_SKIP,,} || "o" == ${VAR_SKIP,,} ]] ; 
		then echo "Exiting";
		exit 1;
	fi;
}

### Various utilities

## wraps apt-get
apt_get() {
	local str=""
	while (( "$#" )); do
		str="$str $1"
		shift
	done
	local cmd="apt-get install -y$str"
	if [[ $DRY_RUN = 1 ]] ; then
		debug "System should execute $cmd"
	else
		if [[ $DEBUG = 1 ]] ; then 
			debug "$cmd"
		fi;	
		$cmd
	fi;
}

test_ns() {
	local NS=$1
	if [[ -z "$NS" ]] ; then
		warn "missing domain name"
		return 1
	fi;
	local cmd="$(dig +short A $NS)"
	if [[ $cmd = "" ]] ; then
		warn "$NS is not a valid domain name"
	else 
		info "$NS is a valid domain name"
	fi;
}

test_local_ip() {
	local IP="$1"
	local VALID=0
	for ip in  $(ip addr show scope global | grep inet | cut -d' ' -f6 | cut -d/ -f1|tr '\n' ' '  ) ; do
		if [[ "$IP" = "$ip" ]]; then
			VALID=1
		fi;
	done;
	if [ $VALID = 0 ] ; then 
		warn "$IP doesn't seem to be a valid local ip"
	fi;
}
# Sets a debconf variable
# @param 1 var
# @param 2 type
# @param 3 value
# @param 4 database default=alternc
debconf() {
	local database;
	if [ -z $4 ] ; then
		database="alternc"
	else 
		database="$4"	
	fi;
	if [[ $DRY_RUN == 1 ]] ; then
		debug "# debconf $database $1 $2 $3"
	else
		if [[ $DEBUG == 1 ]] ; then 
			debug "debconf $database $1 $2 $3"
		fi;	
		# sets the selection
		echo "$database $1 $2 $3" | debconf-set-selections
		# marks the selection as read
		echo "$database $1 seen true" | debconf-set-selections
	fi;
}


# gatepoint for all 'y,o' user inputs management
validate() {
	local VAR=$1
	if [[ "y" == ${VAR,,} || "o" == ${VAR,,} ]] ; then
		return 1;
	fi;
	return 0;
}

# @todo : request a subdomain
alternc_net_get_domain(){
	echo "todo"
}

# Encapsulates cp 
copy(){
	if [[ $DRY_RUN = 1 ]] ; then
		debug "System copies $1 as $2"
	else
		if [[ $DEBUG = 1 ]] ; then 
			debug "cp $1 $2"
		fi;	
		cp $1 $2
	fi;
}

# Encapsulates echo $1 > $2
write() {
	
	if [[ $DRY_RUN == 1 ]] ; then
		debug "System writes '$1' \nin $2"
	else
		if [[ $DEBUG == 1 ]] ; then 
			debug "# writing '$1' \nin $2"
		fi;	
		# backups file if exists
		backup_file "$2"
		# touch file
		touch "$2"
		# echo each text line
		for line in $(echo "$1"); do
			echo $line >> $2
		done;
	fi;
	
}

# inserts a line in file at line number
# @param 1 file path
# @param 2 line #
# @param 3 line
insert(){
	if [[ $DRY_RUN == 1 ]] ; then
		debug "Systems inserts '$3' in $1 at line #$2"
		return 1
	fi;
	sed -i "$2 i\
$3"	 $1
	return 1
	
}

# backups file if exists
# @param 1 file path
backup_file(){
	if [[ $DRY_RUN == 1 ]] ; then
		debug "Systems makes a backup of $1"
		return 1
	fi;
	if [ -f "$1" ] ; then
		local backed=0
		local num=1
		while [[ $backed != 1 ]] ; do 
			if [ -f "$1.$num" ] ; then
				num=$(( $num + 1 ))
			else
				cp "$1" "$1.$num"
				touch "$1"
				backed=1
			fi;
		done;
		if [[ $DEBUG == 1 ]] ; then 
			debug "File ${1} backed as $1.$num"
		fi;
		return 1
	fi;
	return 0
}

# Attempts to check if a service is currently running 
# @param 1 	the service name ex: mysqld
#			This must be an /etc/init.d script name
check_service() {
	if [ -z $1 ] ; then
		alert "Missing service name $@"
	fi;
	local service=$1
	if [ $(pgrep $1 | wc -l) -eq 0 ] ; then
		warn "Service $service is not running"
	else
		info "Service $service is running OK"
	fi;	
}

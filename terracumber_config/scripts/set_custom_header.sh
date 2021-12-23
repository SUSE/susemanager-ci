ENV="1"
FILE="/usr/share/rhn/config-defaults/rhn_java.conf"
HOURS=24;
EMAIL="a@b.com"
DEADLINE_TIME=$(date -d "$(date) + 24 hours")

usage() {
  echo "Usage: $0 -m email -h hours -f file -e environment"
  echo "Example: $0 -m a@b.com -h 24 -h server.kvm.lan -f /usr/share/rhn/config-defaults/rhn_java.conf -e 1"
  echo "Parameters are option. If not specified, you will get the defaults from the example"
  exit -1
}

while [[ $# -gt 0 ]];do
    key=$1
    case $key in
        -m|--mail)
            EMAIL=$2
            shift
            shift
            ;;
        -t|--time)
            HOURS=$2
	    DEADLINE_TIME=$(date -d "$(date) + $HOURS hours")
            shift
            shift
            ;;
        -f|--file)
            FILE=$2
            shift
            shift
            ;;
        -e|--environment)
             ENV=$2
             shift
             shift
             ;;    
        -h|--help)
            usage
            shift
            ;;
    esac
done

sed -e "s%java.custom_header =.*%java.custom_header = \
     In case of FAILURE, you can access this server until ${DEADLINE_TIME}. \
     Otherwise, this server will be removed at the end of the pipeline. \
     Test environment for ${EMAIL}. \
     Run on environment ${ENV}. \
    %g" -i ${FILE}
spacewalk-service restart

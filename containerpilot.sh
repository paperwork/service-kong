#!/bin/bash

export PATH=/usr/local/bin:$PATH
export KONG_NGINX_DAEMON="off"
export KONG_PREFIX="/usr/local/kong"

consul() {
    export CONSUL_AGENT_BIND_ADDR=$(ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
    echo "Exported CONSOUL_AGENT_BIND_ADDR to $CONSUL_AGENT_BIND_ADDR ..."

    wait-for-http.sh http://$CONSUL_SERVER:8500
    run-consul-agent.sh $CONSUL_AGENT_BIND_ADDR $CONSUL_SERVER
}

onStart() {
    logDebug "onStart"

    until nc -q 5 "$KONG_CASSANDRA_CONTACT_POINTS" 9042; do
      >&2 echo "$KONG_CASSANDRA_CONTACT_POINTS is unavailable - sleeping"
      sleep 1
    done

    logDebug "Preparing /usr/local/kong ..."
    kong prepare -p "/usr/local/kong"

    logDebug "Running migrations ..."
    kong migrations up
}

health() {
    logDebug "health"

    case $1 in
        8000)
            /usr/bin/curl -o /dev/null --fail -s http://127.0.0.1:8000/
            if [[ $? -ne 0 && $? -ne 22 ]]; then
                echo "Service monitor endpoint :8000 failed"
                exit 1
            fi
            ;;
        8443)
            /usr/bin/curl -o /dev/null --fail -s https://localhost:8443/ --insecure
            if [[ $? -ne 0 && $? -ne 22 ]]; then
                echo "Service monitor endpoint :8443 failed"
                exit 1
            fi
            ;;
        8001)
            /usr/bin/curl -o /dev/null --fail -s http://localhost:8001/status
            if [[ $? -ne 0 ]]; then
                echo "Service monitor endpoint :8001 failed"
                exit 1
            fi
            ;;
        8444)
            /usr/bin/curl -o /dev/null --fail -s https://localhost:8444/ --insecure
            if [[ $? -ne 0 ]]; then
                echo "Service monitor endpoint :8444 failed"
                exit 1
            fi
            ;;
    esac
}

logDebug() {
    if [[ "${LOG_LEVEL}" == "DEBUG" ]]; then
        echo "containerpilot.sh: $*"
    fi
}

until
    cmd=$1
    if [[ -z "$cmd" ]]; then
        help
    fi
    shift 1
    $cmd "$@"
    [ "$?" -ne 127 ]
do
    help
    exit
done

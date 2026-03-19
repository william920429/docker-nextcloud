# bashrc
if [ -f "/tmp/passwd" ] && [ -f "/tmp/group" ]; then
    LD_PRELOAD="/usr/lib/x86_64-linux-gnu/libnss_wrapper.so"
    NSS_WRAPPER_PASSWD="/tmp/passwd"
    NSS_WRAPPER_GROUP="/tmp/group"
    export LD_PRELOAD NSS_WRAPPER_PASSWD NSS_WRAPPER_GROUP
fi

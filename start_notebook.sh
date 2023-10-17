#!/bin/bash

# This is only a convenience script for Mosè to start the Pluto server on some
# remote machines, you can ignore it.

set -euo pipefail

PORT=${1-1472}

# This is needed only on eX3, where we need to create a reverse tunnel from the
# IPU node to the login node.
if [[ "${HOSTNAME}" == "ipu-pod64-server1" ]]; then
    function cleanup() {
        echo "Killing process with ID ${PROXY_PID}..."
        kill "${PROXY_PID}"
    }

   REMOTE=srl-login1

   # Forward the port back to the login node.
   ssh -N -R "${PORT}:localhost:${PORT}" "${REMOTE}" &
   # Remember the PID
   PROXY_PID=$!
   # At the end of this script, terminate the SSH forwarding.
   trap cleanup EXIT
fi

if [[ "${HOSTNAME}" == "ipu-pod64-server1" ]]; then
    SERVER="dnat.simula.no"
elif [[ "${HOSTNAME}" == "mandelbrot.rc.ucl.ac.uk" ]]; then
    SERVER="${HOSTNAME}"
fi

echo "On your local machine run
    ssh -f -N ${SERVER} -L ${PORT}:localhost:${PORT}
"

julia --project=. -e "
import Pkg
Pkg.instantiate()
import Pluto
Pluto.run(; launch_browser=false, port=${PORT}, auto_reload_from_file=true)
"

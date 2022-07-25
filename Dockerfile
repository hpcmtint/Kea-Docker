FROM debian:bullseye-slim

# Load all the build args, and then set KEA_EXECUTABLE as an ENV to be used
# during runtime.
ARG DEBIAN_FRONTEND=noninteractive KEA_VERSION KEA_DL_BASE_URL KEA_EXECUTABLE
ENV KEA_EXECUTABLE=$KEA_EXECUTABLE

# Install some libraries needed during install.
RUN set -e && apt-get update && apt-get install -y \
        apt-transport-https \
        gnupg2 \
        curl \
    && \
# Download the signing key.
    curl -1sLf "${KEA_DL_BASE_URL}/gpg.32D53EC4807EC10E.key" | gpg --dearmor > /usr/share/keyrings/isc-kea.gpg && \
# Source information about the current OS, and then add the correct repository.
    . /etc/os-release && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/isc-kea.gpg] ${KEA_DL_BASE_URL}/deb/debian ${VERSION_CODENAME} main" > /etc/apt/sources.list.d/isc-kea.list && \
    echo "deb-src [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/isc-kea.gpg] ${KEA_DL_BASE_URL}/deb/debian ${VERSION_CODENAME} main" >> /etc/apt/sources.list.d/isc-kea.list && \
    apt-get update && \
# Install the correct components depending on which executable we are targeting.
# More information about the packages: https://kb.isc.org/docs/isc-kea-packages
    if [ "${KEA_EXECUTABLE}" = "ctrl-agent" ]; then \
        apt-get install -y \
            isc-kea-common="${KEA_VERSION}"* \
            python3-isc-kea-connector="${KEA_VERSION}"* \
            isc-kea-"${KEA_EXECUTABLE}"="${KEA_VERSION}"* ; \
    elif [ "${KEA_EXECUTABLE}" = "dhcp4" -o "${KEA_EXECUTABLE}" = "dhcp6" ]; then \
        apt-get install -y \
            isc-kea-common="${KEA_VERSION}"* \
            isc-kea-"${KEA_EXECUTABLE}"-server="${KEA_VERSION}"* ; \
    else \
        echo "Unknown or unsupported Kea executable: ${KEA_EXECUTABLE}"; exit 1; \
    fi && \
# Remove everything that is no longer necessary.
    apt-get remove --purge -y \
        apt-transport-https \
        gnupg2 \
        curl \
    && \
    apt-get autoremove -y && apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
# Create expected directories.
    mkdir /entrypoint.d \
          /kea \
          /kea/config \
          /kea/leases \
          /kea/socket \
          /kea/log

# Copy the entrypoint script and just set "-V" as the command so the users must
# define the path to their own config.
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "-V" ]
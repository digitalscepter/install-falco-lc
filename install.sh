#!/usr/bin/env bash
set -euo pipefail

########################################
# Falco-LC Puppet Agent Bootstrap
#
# Usage (local file):
#   sudo ./install.sh <controller_hostname> [environment]
#
# Usage (curl | bash):
#   curl -sSL https://raw.githubusercontent.com/digitalscepter/falco-lc-installer/refs/heads/main/install.sh \
#     | sudo bash -s -- <controller_hostname> [environment]
#
# Example:
#   curl -sSL https://raw.githubusercontent.com/digitalscepter/falco-lc-installer/refs/heads/main/install.sh \
#     | sudo bash -s -- falco-lc-controller production
########################################

if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root (use sudo)." >&2
  exit 1
fi

CONTROLLER_HOST="${1:-}"
PUPPET_ENVIRONMENT="${2:-production}"

if [ -z "$CONTROLLER_HOST" ]; then
  echo "Usage: $0 <controller_hostname> [environment]" >&2
  echo "Example (local): $0 falco-lc-controller production" >&2
  echo "Example (curl): curl -sSL https://raw.githubusercontent.com/digitalscepter/falco-lc-installer/refs/heads/main/install.sh | sudo bash -s -- falco-lc-controller production" >&2
  exit 1
fi

echo "=== Falco-LC Puppet Agent Bootstrap ==="
echo "Controller:   ${CONTROLLER_HOST}"
echo "Environment:  ${PUPPET_ENVIRONMENT}"
echo

########################################
# Detect Debian/Ubuntu
########################################

if [ ! -f /etc/os-release ]; then
  echo "Cannot detect OS (missing /etc/os-release). This script currently supports Debian/Ubuntu-like systems." >&2
  exit 1
fi

. /etc/os-release

if [[ "${ID_LIKE:-}" != *debian* && "${ID:-}" != "debian" && "${ID:-}" != "ubuntu" ]]; then
  echo "Unsupported OS: ${PRETTY_NAME:-unknown}. This bootstrap currently supports Debian/Ubuntu only." >&2
  exit 1
fi

########################################
# Install dependencies
########################################

echo ">>> Installing dependencies (curl, ca-certificates, lsb-release)…"
apt-get update -y
apt-get install -y curl ca-certificates lsb-release

DISTRO_CODENAME="$(lsb_release -cs)"

########################################
# Install Puppet agent from Puppetlabs APT repo (Puppet 8)
########################################

echo ">>> Installing Puppet agent from Puppetlabs APT repository (Puppet 8)…"

PUPPET_RELEASE_PKG="/tmp/puppet8-release-${DISTRO_CODENAME}.deb"

curl -sSL "https://apt.puppet.com/puppet8-release-${DISTRO_CODENAME}.deb" -o "${PUPPET_RELEASE_PKG}"
apt-get install -y "${PUPPET_RELEASE_PKG}"
rm -f "${PUPPET_RELEASE_PKG}"

apt-get update -y
apt-get install -y puppet-agent

PUPPET_BIN="/opt/puppetlabs/bin/puppet"

if [ ! -x "${PUPPET_BIN}" ]; then
  echo "Puppet binary not found at ${PUPPET_BIN} after installation." >&2
  exit 1
fi

########################################
# Add Puppet AIO bin path for human use
########################################

# Ensure PATH includes Puppet agent binaries for interactive shells
cat >/etc/profile.d/puppet-agent-path.sh <<'EOF'
export PATH="/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin:$PATH"
EOF
chmod 644 /etc/profile.d/puppet-agent-path.sh

# Ensure sudo secure_path includes Puppet binaries
cat >/etc/sudoers.d/puppet-agent-path <<'EOF'
Defaults secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin"
EOF
chmod 440 /etc/sudoers.d/puppet-agent-path

########################################
# Configure puppet.conf
########################################

echo ">>> Configuring puppet.conf…"

"${PUPPET_BIN}" config set server "${CONTROLLER_HOST}" --section main
"${PUPPET_BIN}" config set environment "${PUPPET_ENVIRONMENT}" --section main

# Optional: you can explicitly set certname here if you want deterministic node names
# CERTNAME="$(hostname -f)"
# "${PUPPET_BIN}" config set certname "${CERTNAME}" --section main

echo "Current puppet.conf settings:"
"${PUPPET_BIN}" config print server environment certname

########################################
# Trigger initial Puppet run (CSR submission)
########################################

echo
echo ">>> Triggering initial Puppet run to submit certificate request…"
set +e
"${PUPPET_BIN}" agent -t
PUPPET_EXIT=$?
set -e

if [ ${PUPPET_EXIT} -eq 0 ]; then
  echo
  echo "Puppet agent run completed successfully (certificate may already be signed)."
else
  echo
  echo "Puppet agent returned exit code ${PUPPET_EXIT}."
  echo "This is normal if the certificate has not yet been signed by the controller."
fi

########################################
# Summary + manual approval instructions
########################################

CERTNAME="$("${PUPPET_BIN}" config print certname)"

cat <<EOF

=== Next Steps (Manual Approval) ===

1. On the Puppet controller (${CONTROLLER_HOST}), list pending certificate requests:

   sudo puppetserver ca list

   Look for a certname matching:
     ${CERTNAME}

2. Approve the certificate on the controller:

   sudo puppetserver ca sign --certname ${CERTNAME}

3. Back on this node, run Puppet again to fetch and apply its catalog:

   sudo ${PUPPET_BIN} agent -t

After that, this node will be managed by the Falco-LC controller under:
  Environment: ${PUPPET_ENVIRONMENT}
  Certname:    ${CERTNAME}

EOF

echo "Bootstrap completed. Waiting on controller approval."
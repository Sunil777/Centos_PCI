# PCI  (Ansible Project)


## Description

This Project provides numerous security-related configurations, providing all-round base protection.  It is intended to be compliant with the [DevSec Linux Baseline].

It configures:

 * Configures package management e.g. allows only signed packages
 * Remove packages with known issues
 * Configures `pam` and `pam_limits` module
 * Configures system path permissions
 * Restrict Root Logins to System Console
 * Configures kernel parameters via sysctl
 * Install ossec client and sysmentic client
 * configure sshd harding
 * Start infra Acc. to PCI requirements

It will not:

 * Update system packages
 * Install security patches

## Requirements

* Ansible 2.2.1
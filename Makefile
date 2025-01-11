all: check

SHELL := /bin/bash

.PHONY: \
	all \
	check \
	check_os_version \
	check_package_versions

check_package_versions:
	nvim --version | grep "NVIM v0.9"

check_os_version:
	cat /etc/os-release | grep "22.04"
	cat /etc/os-release | grep "Jammy Jellyfish"
	cat /etc/os-release | grep "LTS"

check: \
		check_package_versions \
		check_os_version

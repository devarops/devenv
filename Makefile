all: check

SHELL := /bin/bash

.PHONY: \
	all \
	check \
	check_os_version \
	check_package_versions

check_package_versions:
	exa --version      | grep "^v0\."
	neofetch --version | grep "^Neofetch 7\."
	nvim --version     | grep "^NVIM v0.10\."
	rich --version     | grep "^1\."

check_os_version:
	cat /etc/os-release | grep "24.04"
	cat /etc/os-release | grep "Noble Numbat"
	cat /etc/os-release | grep "LTS"

check: \
		check_package_versions \
		check_os_version

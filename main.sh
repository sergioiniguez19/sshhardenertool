#!/bin/bash

# ==============================================================
#                    SSH HARDENER
# ==============================================================


# COLORS
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
CYAN="\e[36m"
WHITE="\e[97m"
BOLD="\e[1m"
DIM="\e[2m"
ENDCOLOR="\e[0m"


# SYMBOLS
CHECK="${GREEN}[✔]${ENDCOLOR}"
CROSS="${RED}[✘]${ENDCOLOR}"
INFO="${CYAN}[➜]${ENDCOLOR}"
WARN="${YELLOW}[!]${ENDCOLOR}"
ARROW="${MAGENTA}[>]${ENDCOLOR}"

# VARIABLES
PORT=22
FILENAME="sshd_config"
BACKUP_FILE=00.previous_config

# VISUAL FUNCTIONS
function print_line(){
	printf '%*s\n' "${1:-70}" '' | tr ' ' '='
}

function print_separator(){
	echo -e "${DIM}----------------------------------------------------------------------${ENDCOLOR}"
}

function print_title(){
	clear
	echo ""
	echo -e "${CYAN}${BOLD}======================================================================${ENDCOLOR}"
	echo -e "${CYAN}${BOLD}                         SSH HARDENER${ENDCOLOR}"
	echo -e "${CYAN}${BOLD}======================================================================${ENDCOLOR}"
	echo -e "${DIM}             Secure SSH configuration deployment tool${ENDCOLOR}"
	echo ""
}

function print_section(){
	echo ""
	echo -e "${BLUE}${BOLD}[*] $1${ENDCOLOR}"
	print_separator
}

function print_success(){
	echo -e "${CHECK} ${GREEN}$1${ENDCOLOR}"
}

function print_error(){
	echo -e "${CROSS} ${RED}$1${ENDCOLOR}"
}

function print_info(){
	echo -e "${INFO} ${CYAN}$1${ENDCOLOR}"
}

function print_warning(){
	echo -e "${WARN} ${YELLOW}$1${ENDCOLOR}"
}

function print_change(){
	echo -e "    ${ARROW} ${WHITE}$1${ENDCOLOR}"
}


# ROOT CHECK
function check_root(){
	root=$(whoami)
	if [ "$root" != "root" ]; then
		print_error "This script should be run as root"
		echo ""
		exit 1
	fi
	print_success "Running with root privileges"
}


# DEPENDENCY CHECK

function check_dependencies(){
	print_section "Checking SSH installation"
	echo -e "${INFO} ${WHITE}Checking if SSH is installed...${ENDCOLOR}"
	if which sshd &>/dev/null; then
		print_success "SSH installed."
	else
		print_warning "SSH not installed."
		if [ -f /etc/os-release ]; then
			ID=$(cat /etc/os-release | grep -E "^ID=" | cut -d'=' -f2)
			print_info "Distro detected: $ID"
			print_info "Installing SSH on $ID"
			case "$ID" in
				ubuntu|debian)
					export DEBIAN_FRONTEND=noninteractive
					apt-get update -qq && apt-get install -y openssh-server &>/dev/null
				;;
				fedora|rhel|centos)
					dnf install -y openssh-server &>/dev/null
				;;
				arch)
					pacman -Sy --noconfirm openssh &>/dev/null
				;;
				*)
					print_warning "Distro not supported."
					;;
			esac
		fi
	fi
}


# HELP

function show_help(){
	echo ""
	echo -e "${CYAN}${BOLD}SSH HARDENER - HELP${ENDCOLOR}"
	print_separator
	echo -e "${WHITE}Usage:${ENDCOLOR} sshhardener.sh [OPTION]"
	echo ""
	echo -e " ${YELLOW}-h${ENDCOLOR}    Show help"
	echo -e " ${YELLOW}-p${ENDCOLOR}    Choose the port you want for SSH"
	echo ""
}


# ROLLBACK

function rollback(){
	if ! sshd -t &>/dev/null; then
		echo ""
		print_error "SSH configuration is incorrect!"
		print_warning "Restoring previous configuration..."
		echo ""
		if cp /etc/ssh/sshd_config.d/$BACKUP_FILE /etc/ssh/sshd_config; then
			print_success "Previous SSH configuration restored."
		else
			print_error "Failed to restore the previous SSH configuration."
		fi
		return 1
	else
		print_success "SSH configuration syntax validated successfully."
		return 0
	fi
}


# RESTART SSH SERVICE

function restart_ssh_service(){
	print_info "Restarting the SSH service..."
	if command -v systemctl &>/dev/null; then
		if systemctl restart sshd; then
			print_success "SSH service restarted successfully (sshd)."
			return 0
		elif systemctl restart ssh; then
			print_success "SSH service restarted successfully (ssh)."
			return 0
		fi
	fi

	if command -v service &>/dev/null; then
		if service sshd restart; then
			print_success "SSH service restarted successfully (sshd)."
			return 0
		elif service ssh restart; then
			print_success "SSH service restarted successfully (ssh)."
			return 0
		fi
	fi

	print_error "Could not restart the SSH service."
	return 1
}



# BACKUP

function backup(){
	print_section "Creating SSH configuration backup"
	echo -e "${INFO} ${WHITE}Backing up your current configuration...${ENDCOLOR}"
	cp /etc/ssh/sshd_config /etc/ssh/sshd_config.d/$BACKUP_FILE
	print_success "Backup created successfully."
	print_info "Backup file: /etc/ssh/sshd_config.d/$BACKUP_FILE"
}


# NUMBER VALIDATION

function isnumber(){
	if [[ "$1" =~ ^[0-9]+$ ]] && [ "$1" -gt 0 ] && [ "$1" -lt 65535 ]; then
		PORT=$1
		print_success "SSH port selected: $PORT"
	else
		print_error "Port is not a valid number"
		exit 1
	fi
}


# ALREADY HARDENED CHECK

function already_hardened(){
	local sshd_dump
    	sshd_dump=$(sshd -T 2>/dev/null)
	local -a checks=(
        "port ${PORT}"
        "ciphers aes256-ctr,aes192-ctr,aes128-ctr"
        "logingracetime 30"
        "permitrootlogin no"
        "maxauthtries 3"
        "pubkeyauthentication yes"
        "authorizedkeysfile .ssh/authorized_keys"
        "passwordauthentication no"
        "permitemptypasswords no"
        "kbdinteractiveauthentication no"
        "allowagentforwarding no"
        "allowtcpforwarding no"
        "x11forwarding no"
        "clientaliveinterval 300"
        "clientalivecountmax 0"
    	)

	local param
    	for param in "${checks[@]}"; do
        	if ! echo "$sshd_dump" | grep -qi "^${param}$"; then
            		echo "[!] Directiva no ajustada o diferente: $param"
            		return 1
        	fi
    	done
	return 0
	
}


# SHOW SSH CHANGES

function show_changes(){
	echo ""
	echo -e "${MAGENTA}${BOLD}======================================================================${ENDCOLOR}"
	echo -e "${MAGENTA}${BOLD}                 SSH SECURITY CONFIGURATION${ENDCOLOR}"
	echo -e "${MAGENTA}${BOLD}======================================================================${ENDCOLOR}"
	echo ""
	echo -e "${WHITE}${BOLD}The following SSH security parameters have been applied:${ENDCOLOR}"
	echo ""

	print_change "Port ${PORT}"
	print_change "Ciphers aes256-ctr,aes192-ctr,aes128-ctr"
	print_change "LoginGraceTime 30"
	print_change "PermitRootLogin no"
	print_change "MaxAuthTries 3"
	print_change "PubkeyAuthentication yes"
	print_change "AuthorizedKeysFile .ssh/authorized_keys"
	print_change "PasswordAuthentication no"
	print_change "PermitEmptyPasswords no"
	print_change "KbdInteractiveAuthentication no"
	print_change "AllowAgentForwarding no"
	print_change "AllowTcpForwarding no"
	print_change "X11Forwarding no"
	print_change "ClientAliveInterval 300"
	print_change "ClientAliveCountMax 0"
	print_change "Subsystem sftp internal-sftp"

	echo ""
	print_separator

	echo -e "${GREEN}${BOLD}SSH HARDENING SUMMARY${ENDCOLOR}"
	echo ""
	echo -e " ${CHECK} Password authentication disabled"
	echo -e " ${CHECK} Root login disabled"
	echo -e " ${CHECK} Empty passwords disabled"
	echo -e " ${CHECK} Maximum authentication attempts reduced"
	echo -e " ${CHECK} Public key authentication enabled"
	echo -e " ${CHECK} Agent forwarding disabled"
	echo -e " ${CHECK} TCP forwarding disabled"
	echo -e " ${CHECK} X11 forwarding disabled"
	echo -e " ${CHECK} SSH idle session monitoring configured"
	echo -e " ${CHECK} Strong CTR ciphers configured"
	echo ""

}


# HARDEN SSH

function harden_ssh(){
	print_title
	check_dependencies
	if already_hardened $PORT; then
		print_success "SSH Configuration already hardened"
		exit 0
	fi
	backup
	print_section "Preparing hardened SSH configuration"

	if [ -n "$1" ]; then
		print_info "Updating SSH port in configuration file..."
		sed -i -E "s/^\s*Port\s+[0-9]+/Port $1/" "./conf/$FILENAME"
		print_success "SSH port configured to: $1"
	fi

	echo ""
	print_info "Adding configuration file to the SSH folder..."
	if cp ./conf/$FILENAME /etc/ssh; then
		print_success "SSH configuration added correctly!"
		echo ""
		print_info "Applying SSH security hardening..."
		sleep 1
		show_changes
		echo ""
		print_section "Validating SSH configuration"
		if ! rollback; then
			print_error "SSH hardening aborted because configuration validation failed."
			exit 1
		fi
		if ! restart_ssh_service; then
			print_error "SSH configuration is valid, but the service was not restarted."
			exit 1
		fi
		echo ""
		echo -e "${GREEN}${BOLD}======================================================================${ENDCOLOR}"
		echo -e "${GREEN}${BOLD}                   SSH HARDENING COMPLETE${ENDCOLOR}"
		echo -e "${GREEN}${BOLD}======================================================================${ENDCOLOR}"
		echo ""
		print_success "SSH hardening process completed."
		print_info "Configuration file: /etc/ssh/$FILENAME"
		print_info "Backup file: /etc/ssh/sshd_config.d/$BACKUP_FILE"
		echo ""

	else

		print_error "Something failed during installation. Exiting..."
		exit 1

	fi

}


# MAIN

check_root

if [ "$#" -eq 0 ]; then
	harden_ssh
fi

while getopts "hp:" opt; do
	case $opt in
		h)
			show_help
		;;

		p)
			isnumber "$OPTARG"
			harden_ssh "$PORT"
		;;

		*)
			print_error "Parameters incorrect. Exiting..."
			exit 1
		;;
	esac
done

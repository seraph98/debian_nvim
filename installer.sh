#!/bin/bash
a=`uname  -a`

if [[ ! -e dnvim ]] || [[ ! -e installer.sh ]]; then
	echo "please run installer in debian_nvim root dir"
	exit 0
fi


public_string="Linux"

D="Darwin"
C="CentOS"
U="Ubuntu"
De="Debian"

function install_in_centos {
	yum install -y yum-utils

	yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

	yum install docker-ce docker-ce-cli containerd.io

	systemctl start docker
}

function install_in_debian {
	apt-get update

	apt-get install \
	ca-certificates \
	curl \
	gnupg \
	lsb-release

	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

	echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

	apt-get update
	apt-get install docker-ce docker-ce-cli containerd.io
}


function install_in_ubuntu {
	apt-get update

	apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

	echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

	apt-get update

	apt-get install docker-ce docker-ce-cli containerd.io
}



function validate_or_install_docker {
	if [ -e $(which docker) ]; then
		#centos os check
		FILE_EXE=/etc/redhat-release
		if [ -f "$FILE_EXE" ];then
			if [[ `cat /etc/redhat-release` =~ $C ]];then
				install_in_centos
				exit
			fi
		fi
		
		if [[ $a =~ $D ]];then
			brew install --cask docker
		elif [[ $a =~ $C ]];then
			install_in_centos
		elif [[ $a =~ $U ]];then
			install_in_ubuntu
		elif [[ $a =~ $De  ]];then
			install_in_debian
		else
		    echo "do not support auto insall docker for system: $a, please install docker at first"
			exit 1
		fi
	fi
}

function check_dockerd {
	if [[ $a =~ $D ]]; then
		if [[ -z $(launchctl list | grep com.docker.docker) ]]; then
			# need to start docker in mac
			open /Applications/Docker.app
			echo "wating for starting docker"
			sleep 10
		fi
	else
		if [ -z $(pidof dockerd) ]; then
			# need to start docker deamon in other nix sys
			dockerd	
			echo "wating for starting docker"
			sleep 10
		fi
	fi
}

if validate_or_install_docker; then
	check_dockerd
 	docker run -it --security-opt=seccomp:unconfined --name debian_nvim --hostname dnvim seraph98/debian_nvim /usr/bin/zsh
	cp ./dnvim /usr/local/bin
fi

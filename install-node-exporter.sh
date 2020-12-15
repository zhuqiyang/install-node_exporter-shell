#!/bin/bash
#######################################
#                                     #
#        install node_exporter        # 
#                                     #
#######################################


export HOST_IP=$1
export PACKAGE_NAME=$2

if [ -z "$1" ] || [ -z "$2" ]; then
cat <<EOF

	bash $0 HOST_IP PACKAGE_NAME

EOF
exit
fi

# check ssh without password
ssh -o PreferredAuthentications=publickey -o StrictHostKeyChecking=no $HOST_IP 'date'
if [ $? -ne 0 ]; then
	echo 'Unable to log in without password'
	exit
fi

# check 9100 port exists
export PORT_EXISTS=$(ssh $HOST_IP  'lsof -i:9100 > /dev/null' && echo $?)
if [ "$PORT_EXISTS" = "0" ]; then
	echo "9100 port exists"
	exit
fi

#  check OS version
temp=`ssh $HOST_IP "uname -r"`
export OS_RELEASE=${temp:(-10):3}



scp_file(){
	ssh $HOST_IP 'hostname'
	scp $PACKAGE_NAME ${HOST_IP}:/tmp/
	ssh $HOST_IP "tar -xf /tmp/$PACKAGE_NAME -C /usr/local/ && cd /usr/local/ && ln -sv node_exporter-1.0.1.linux-amd64/ node_exporter"
}

if [ "$OS_RELEASE" = "el7" ]; then
	scp_file
	scp ./node_exporter.service ${HOST_IP}:/usr/lib/systemd/system/
	ssh $HOST_IP 'systemctl start node_exporter.service'
	ssh $HOST_IP 'systemctl enable node_exporter.service'
	ssh $HOST_IP 'rm /tmp/node_exporter-1.0.1.linux-amd64.tar.gz'

elif [ "$OS_RELEASE" = "el6" ]; then
	scp_file
	scp node_exporter ${HOST_IP}:/etc/init.d/
	ssh $HOST_IP 'chmod +x /etc/init.d/node_exporter'
	ssh $HOST_IP 'service node_exporter start'
	ssh $HOST_IP 'rm /tmp/node_exporter-1.0.1.linux-amd64.tar.gz'
fi

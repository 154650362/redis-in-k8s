#!/bin/sh

me=$(hostname -i)

systemctl stop firewalld
systemctl disable firewalld

echo "Installing softwares..."
yum install -y docker flannel etcd kubernetes *rhsm* 

echo "Initing etcd...."
cp ./etcd.conf ./etcd.conft
sed -i "s/%master%/$me/" ./etcd.conft
mv /etc/etcd/etcd.conf /etc/etcd/etcd.conf.bak
mv ./etcd.conft /etc/etcd/etcd.conf

mkdir -p /var/lib/etcd/
chown etcd:etcd /var/lib/etcd/

systemctl daemon-reload
systemctl restart etcd
systemctl enable etcd

etcdctl mk /coreos.com/network/config '{"Network":"172.17.0.0/16"}'

echo "Initing k8s..."
cp ./apiserver ./apiservert
cp ./config ./configt
sed -i "s/%master%/$me/" ./apiservert
sed -i "s/%master%/$me/" ./configt

mv /etc/kubernetes/apiserver /etc/kubernetes/apiserver.bak
mv ./apiservert /etc/kubernetes/apiserver
mv /etc/kubernetes/config /etc/kubernetes/config.bak
mv ./configt /etc/kubernetes/config

echo "Initing flannel & docker ..."

cp ./flanneld ./flanneldt
set -i "s/%master%/$me/" ./flanneldt
mv /etc/sysconfig/flanneld /etc/sysconfig/flanneld.bak
mv ./flanneldt /etc/sysconfig/flanneld


echo "Starting combining ..."

systemctl daemon-reload

for s in etcd kube-apiserver kube-scheduler kube-controller-manager kubelet kube-proxy flanneld docker ; do
        systemctl restart $s
        systemctl enable $s
        systemctl status $s | grep Active
done

#EJECUTA ESTE SCRIPT CON SUDO SU / RUN THIS WITH SUDO SU#
#----------Wazuh indexer-----------#
apt update
curl -sO https://packages.wazuh.com/4.7/wazuh-certs-tool.sh
curl -sO https://packages.wazuh.com/4.7/config.yml
sed -i 's/node-1/wazuh-index/g' config.yml
sed -i 's/<indexer-node-ip>/192.168.1.221/g' config.yml #Change the ip#
sed -i 's/wazuh-1/wazuh-server/g' config.yml
sed -i 's/<wazuh-manager-ip>/192.168.1.221/g' config.yml #Change the ip#
sed -i 's/- name: dashboard/- name: wazuh-dash/g' config.yml
sed -i 's/<dashboard-node-ip>/192.168.1.221/g' config.yml #Change the ip#
bash ./wazuh-certs-tool.sh -A
tar -cvf ./wazuh-certificates.tar -C ./wazuh-certificates/ .
cp wazuh-certificates.tar wazuh-certificates-cp.tar
rm -rf ./wazuh-certificates
apt-get install debconf adduser procps
apt-get install gnupg apt-transport-https
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list
apt-get update
apt-get -y install wazuh-indexer
sed -i 's/0.0.0.0/192.168.1.221/g' /etc/wazuh-indexer/opensearch.yml #Change the ip#
sed -i 's/node-1/wazuh-index/g' /etc/wazuh-indexer/opensearch.yml
NODE_NAME=wazuh-index
mkdir /etc/wazuh-indexer/certs
tar -xf ./wazuh-certificates.tar -C /etc/wazuh-indexer/certs/ ./$NODE_NAME.pem ./$NODE_NAME-key.pem ./admin.pem ./admin-key.pem ./root-ca.pem
mv -n /etc/wazuh-indexer/certs/$NODE_NAME.pem /etc/wazuh-indexer/certs/indexer.pem
mv -n /etc/wazuh-indexer/certs/$NODE_NAME-key.pem /etc/wazuh-indexer/certs/indexer-key.pem
chmod 500 /etc/wazuh-indexer/certs
chmod 400 /etc/wazuh-indexer/certs/*
chown -R wazuh-indexer:wazuh-indexer /etc/wazuh-indexer/certs
systemctl daemon-reload
systemctl enable wazuh-indexer
systemctl start wazuh-indexer
/usr/share/wazuh-indexer/bin/indexer-security-init.sh
#----------Wazuh server-----------#
apt-get -y install wazuh-manager
systemctl daemon-reload
systemctl enable wazuh-manager
systemctl start wazuh-manager
apt-get -y install filebeat
curl -so /etc/filebeat/filebeat.yml https://packages.wazuh.com/4.7/tpl/wazuh/filebeat/filebeat.yml
sed -i 's/127.0.0.1/192.168.1.221/g' /etc/filebeat/filebeat.yml #Change the ip#
filebeat keystore create
echo admin | filebeat keystore add username --stdin --force
echo admin | filebeat keystore add password --stdin --force
curl -so /etc/filebeat/wazuh-template.json https://raw.githubusercontent.com/wazuh/wazuh/v4.7.2/extensions/elasticsearch/7.x/wazuh-template.json
chmod go+r /etc/filebeat/wazuh-template.json
curl -s https://packages.wazuh.com/4.x/filebeat/wazuh-filebeat-0.3.tar.gz | tar -xvz -C /usr/share/filebeat/module
NODE_NAME=wazuh-server
mkdir /etc/filebeat/certs
tar -xf ./wazuh-certificates.tar -C /etc/filebeat/certs/ ./$NODE_NAME.pem ./$NODE_NAME-key.pem ./root-ca.pem
mv -n /etc/filebeat/certs/$NODE_NAME.pem /etc/filebeat/certs/filebeat.pem
mv -n /etc/filebeat/certs/$NODE_NAME-key.pem /etc/filebeat/certs/filebeat-key.pem
chmod 500 /etc/filebeat/certs
chmod 400 /etc/filebeat/certs/*
chown -R root:root /etc/filebeat/certs
systemctl daemon-reload
systemctl enable filebeat
systemctl start filebeat
#----------Wazuh dashboard-----------#
apt-get install debhelper tar curl libcap2-bin #debhelper version 9 or later
apt-get -y install wazuh-dashboard
sed -i 's/0.0.0.0/192.168.1.221/g' /etc/wazuh-dashboard/opensearch_dashboards.yml #Change the ip#
sed -i 's/localhost/192.168.1.221/g' /etc/wazuh-dashboard/opensearch_dashboards.yml #Change the ip#
NODE_NAME=wazuh-dash
mkdir /etc/wazuh-dashboard/certs
tar -xf ./wazuh-certificates.tar -C /etc/wazuh-dashboard/certs/ ./$NODE_NAME.pem ./$NODE_NAME-key.pem ./root-ca.pem
mv -n /etc/wazuh-dashboard/certs/$NODE_NAME.pem /etc/wazuh-dashboard/certs/dashboard.pem
mv -n /etc/wazuh-dashboard/certs/$NODE_NAME-key.pem /etc/wazuh-dashboard/certs/dashboard-key.pem
chmod 500 /etc/wazuh-dashboard/certs
chmod 400 /etc/wazuh-dashboard/certs/*
chown -R wazuh-dashboard:wazuh-dashboard /etc/wazuh-dashboard/certs
systemctl daemon-reload
systemctl enable wazuh-dashboard
systemctl start wazuh-dashboard

#En el navegador / In the browser: https://192.168.1.221#

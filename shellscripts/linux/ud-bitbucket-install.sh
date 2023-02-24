#!/usr/bin/env bash
set \
  -o nounset \
  -o pipefail \
  -o errexit

echo "===== Downloading BitBucket ====="
wget -O ~/bitbucket.bin ${bitbucket_dl_url}

cat <<\EOF >> ~/bitbucket.varfile
app.confHome=/var/atlassian/application-data/bitbucket
app.install.service$Boolean=true
existingInstallationDir=/usr/local/BitBucket
launch.application$Boolean=false
portChoice=default
sys.adminRights$Boolean=true
sys.confirmedUpdateInstallationString=false
sys.installationDir=/opt/atlassian/bitbucket
sys.languageId=en
EOF

# Modify BitBucket Permissions
chmod +x ~/bitbucket.bin

# Start BitBucket Install
~/bitbucket.bin -q -varfile ~/bitbucket.varfile

#Creating BitBucket Service 
tee -a /lib/systemd/system/bitbucket.service << EOF
[Unit] 
Description=Atlassian BitBucket
After=network.target
[Service] 
Type=forking
User=atlbitbucket
LimitNOFILE=20000
ExecStart=/opt/atlassian/bitbucket/${bitbucket_version}/bin/start-bitbucket.sh --no-search  
ExecStop=/opt/atlassian/bitbucket/${bitbucket_version}/bin/stop-bitbucket.sh
[Install] 
WantedBy=multi-user.target 
EOF

# Change BitBucket Service File Permission
chmod 644 /lib/systemd/system/bitbucket.service

# Setting TLS Certs
aws secretsmanager get-secret-value --secret-id "/production/mgmt/ca/rootca/bitbucket_cert" --region ${aws_region} | jq -r '.SecretString' > certificates.pem
aws secretsmanager get-secret-value --secret-id "/production/mgmt/ca/rootca/bitbucket_cert_key" --region ${aws_region} | jq -r '.SecretString' > private-key.pem
aws secretsmanager get-secret-value --secret-id "/production/mgmt/ca/rootca/root_ca_pub.pem" --region ${aws_region} | jq -r '.SecretString' > rootCA.crt
#Uncomment if using other Atlassian Tools
# aws secretsmanager get-secret-value --secret-id "/production/mgmt/ca/rootca/jira1_cert" --region ${aws_region} | jq -r '.SecretString' > jira-certificates.pem
# aws secretsmanager get-secret-value --secret-id "/production/mgmt/ca/rootca/confluence_cert" --region ${aws_region} | jq -r '.SecretString' > confluence-certificates.pem
# aws secretsmanager get-secret-value --secret-id "/production/mgmt/ca/rootca/bamboo_cert" --region ${aws_region} | jq -r '.SecretString' > bamboo-certificates.pem


openssl pkcs12 -export -name bitbucket -in certificates.pem -inkey private-key.pem -out keystore.p12 -password pass:changeit
/opt/atlassian/bitbucket/${bitbucket_version}/jre/bin/keytool -importkeystore -destkeystore bitbucket.jks -srckeystore keystore.p12 -srcstoretype pkcs12 -alias bitbucket -srcstorepass changeit -deststorepass changeit

#Uncomment if using other Atlassian Tools
# /opt/atlassian/bitbucket/${bitbucket_version}/jre/bin/keytool -import -alias jiraCA -file jira-certificates.pem -keystore bitbucket.jks -srcstorepass changeit -deststorepass changeit -noprompt
# /opt/atlassian/bitbucket/${bitbucket_version}/jre/bin/keytool -import -alias confluenceCA -file confluence-certificates.pem -keystore bitbucket.jks -srcstorepass changeit -deststorepass changeit -noprompt
# /opt/atlassian/bitbucket/${bitbucket_version}/jre/bin/keytool -import -alias bambooCA -file bamboo-certificates.pem -keystore bitbucket.jks -srcstorepass changeit -deststorepass changeit -noprompt
/opt/atlassian/bitbucket/${bitbucket_version}/jre/bin/keytool -import -alias rootCA -keystore bitbucket.jks -file rootCA.crt -srcstorepass changeit -deststorepass changeit -noprompt

mv bitbucket.jks /opt/atlassian/bitbucket/${bitbucket_version}/
chown root:root /opt/atlassian/bitbucket/${bitbucket_version}/bitbucket.jks
chmod 644 /opt/atlassian/bitbucket/${bitbucket_version}/bitbucket.jks

/opt/atlassian/bitbucket/${bitbucket_version}/jre/bin/keytool -import -alias rootCA -keystore /opt/atlassian/bitbucket/${bitbucket_version}/jre/lib/security/cacerts -file rootCA.crt -srcstorepass changeit -deststorepass changeit -noprompt

# Creating BitBucket Properties File
cat <<\EOF >> /var/atlassian/application-data/bitbucket/shared/bitbucket.properties
setup.displayName=BitBucket
setup.baseUrl=https://bitbucket.${domain_name}:8443
setup.sysadmin.username=${username}
setup.sysadmin.password=${password}
setup.sysadmin.emailAddress=bitbucketadmin@imatchinternal.org
jdbc.driver=org.postgresql.Driver
jdbc.url=jdbc:postgresql://${db_endpoint}/bitbucket?ssl=require&targetServerType=master
jdbc.user=${db_username}
jdbc.password=${db_password}
server.port=8443
server.ssl.enabled=true
server.ssl.key-store=/opt/atlassian/bitbucket/${bitbucket_version}/bitbucket.jks
server.ssl.key-store-password=changeit
server.ssl.key-password=changeit
server.ssl.protocol=TLSv1.2
server.scheme=https
server.ssl.key-alias=bitbucket
plugin.search.config.aws.region=${aws_region}
plugin.search.config.baseurl=${opensearch_url}
plugin.search.config.password=${opensearch_password}
plugin.search.config.username=${opensearch_username}
auth.remember-me.enabled=never
EOF

# Cleaning up BitBucket Files
rm -f ~/bitbucket.bin
rm -f ~/bitbucket.varfile
rm -f ~/certificates.pem
rm -f ~/private-key.pem
rm -f ~/keystore.p12
rm -f ~/rootCA.crt
rm -f ~/bitbucket.jks

#Chown bitbucket user
chown -R atlbitbucket:atlbitbucket /opt/atlassian/
chown -R atlbitbucket:atlbitbucket /var/atlassian/

# Enable and Start BitBucket Service
systemctl daemon-reload
systemctl enable bitbucket.service
systemctl start bitbucket.service

#Reboot
reboot

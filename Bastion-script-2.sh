#!/bin/bash
yum update -y
yum install httpd -y
systemctl start httpd
systemctl enable httpd 
echo "<html>
<head>
<title>WARNING</title>
</head>
<body>
<h1>*******WARNING**********</h1>
<p>This computer system is the property of ProCore Plus. It is for authorized use only. By using this system, all users acknowledge notice of, and agree to comply with, the Acceptable Use of Information Technology Resources Policy (“AUP”). Unauthorized or improper use of this system may result in administrative disciplinary action, civil charges/criminal penalties, and/or other sanctions as set forth in the AUP. By continuing to use this system you indicate your awareness of and consent to these terms and conditions of use. LOG OFF IMMEDIATELY if you do not agree to the conditions stated in this warning.</p>
<h2>*********************************************************** </h2>
<img src=https://bastion-host-banner.s3.amazonaws.com/Bastion+Architecture-Page-2+(4).jpg alt="Warning Image" />
</body>
</html>" | sudo tee /var/www/html/index.html
systemctl restart httpd
yum install amazon-linux-extras -y
cd /
mkdir /home-directories
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport fs-0fc48c2aee4c6b302.efs.us-east-1.amazonaws.com:/ /home-directories
mv /home-directories /home
amazon-linux-extras install lynis -y
yum install lynis -y
ln -s /opt/lynis/lynis /usr/local/bin/lynis
mkdir -p /home/Audit_Reports
lynis audit system
mv /var/log/lynis.log /home/Audit_Reports/system-audit
Name:		minecraft-forge-installer
Release:	1
Summary:	Sets up Minecraft and Forge for you
License:	Mixed
Version:	1.0
Vendor:		Jeff Reeves
Group:		Amusements/Games

%description
Installs two scripts that assist with installing Oracle Java, Minecraft Server, and Forge.
The EULA.txt for Minecraft is automatically accepted.

%clean
echo "Not cleaning up because more building is going to happen."

%files
/usr/bin/oracle-java.sh
/usr/bin/minecraft-forge.sh
%config /etc/oracle-java.conf
%config /etc/minecraft-forge.conf
%doc %name-%version/README


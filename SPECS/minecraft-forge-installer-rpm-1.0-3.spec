Name:		minecraft-forge-installer
Release:	3
Summary:	Sets up Minecraft and Forge for you
License:	Mixed
Version:	1.0
Vendor:		Jeff Reeves
Group:		Amusements/Games

%description
Installs two scripts that assist with installing Oracle Java, Minecraft Server, and Forge:

oracle-java.sh
minecraft-forge.sh

Note: The EULA.txt for Minecraft is automatically accepted during install.

%clean
echo "Not cleaning up because more building is going to happen."

%files
%defattr(0755,root,root)
/usr/bin/oracle-java.sh
/usr/bin/minecraft-forge.sh
%attr(0655,root,root) %config /etc/oracle-java.conf
%attr(0655,root,root) %config /etc/minecraft-forge.conf
%attr(0644,root,root) %doc %name-%version/README


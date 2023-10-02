#!/bin/bash

# Esse script funcionará apenas com disco LVM, chamado de /compartilhamento. Caso não tenha um disco específico, será necessário apenas mudar o caminho dos arquivos.
# Criado por: Jacqueline Rodrigues

# validar se o pacote samba existe para realizar a configuração do samba
if dpkg -l | grep samba >/dev/null
then
	echo
	echo O pacote samba já está inslado. Vamos prosseguir.
	echo
else
	echo
	echo O pacote samba não está instalado. Vamos instá-lo e você conseguirá prosseguir com as atividades.
	apt install samba -y
	echo
fi

while true;
do
	echo +++++++++++++++++++++++ Configurações do Samba +++++++++++++++++++++++++
	echo ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	echo
	echo O que deseja fazer?
	echo '1- criar um novo usuário'
	echo '2- adicionar usuário a um grupo'
	echo '3- criar um novo grupo'
	echo '4- remover usuário'
	echo '5- remover grupos'
	echo '0- sair'
	read -p 'Informe sua escolha (0-7): ' ESCOLHA
	case $ESCOLHA in
		1)
			read -p 'Informe o nome do novo usuário: ' ADD_USER
			useradd -M $ADD_USER
			#read -s -p 'Informe a senha desse novo usuário: ' ADD_SENHA
			smbpasswd -a $ADD_USER
			echo Usuário adicionado com sucesso.
			;;
		2)
			echo
			read -p 'Informe o nome do grupo: ' ADD_GRUPO
			read -p 'Informe o nome do usuário: ' USER
			if getent group $ADD_GRUPO >/dev/null
			then
				usermod -a -G $ADD_GRUPO $USER
				systemctl start smbd
				echo Usuário adicionado ao grupo com sucesso
			else
				echo O grupo informado não existe. Procure a opção de criá-lo.
			fi
			;;
		3)
			read -p 'Informe o nome do novo grupo: ' NOVO_GRUPO
			if getent group $NOVO_GRUPO >/dev/null
			then
				echo O grupo $NOVO_GRUPO já existe!
			else
				addgroup $NOVO_GRUPO
				mkdir /compartilhamento/samba/$NOVO_GRUPO
				chmod -R 770 /compartilhamento/samba/$NOVO_GRUPO
				chown -R root:$NOVO_GRUPO /compartilhamento/samba/$NOVO_GRUPO
				echo >> /etc/samba/smb.conf
				echo [$NOVO_GRUPO] >> /etc/samba/smb.conf
				echo "path = /compartilhamento/samba/$NOVO_GRUPO" >> /etc/samba/smb.conf
				echo "writeable = yes" >> /etc/samba/smb.conf
				echo "available = yes" >> /etc/samba/smb.conf
				echo "force group = $NOVO_GRUPO" >> /etc/samba/smb.conf
				echo "create mask = 0770" >> /etc/samba/smb.conf
				echo "directory mask = 0770" >> /etc/samba/smb.conf
				echo "valid users = @$NOVO_GRUPO" >> /etc/samba/smb.conf
				systemctl restart smbd
				echo O grupo $NOVO_GRUPO foi criado com sucesso.
			fi
			;;
		4)
			read -p 'Informe o nome do usuário a ser removido: ' REMOVE_USER
			if getent passwd $REMOVE_USER >/dev/null
			then
				userdel $REMOVE_USER
				echo Usuário $REMOVE_USER removido com sucesso.
				systemctl restart smbd
			else
				echo O usuário $REMOVE_USER não existe, por favor, averiguar
			fi
			;;
		5)
			read -p 'Informe o nome do grupo a ser removido: ' REMOVE_GRUPO
			if getent group $REMOVE_GRUPO >/dev/null
			then
				groupdel $REMOVE_GRUPO
				rm -rf /compartilhamento/samba/$REMOVE_GRUPO
				sed -i "/^\[$REMOVE_GRUPO\]/,/^valid users = @$REMOVE_GRUPO\$/d" /etc/samba/smb.conf
				systemctl restart smbd
				echo Grupo removido com sucesso
			else
				echo O grupo informado não existe, por favor, verifique.
			fi
			;;
		0)
			echo Saindo...
			exit 0
			;;
		*)
			echo Escolha inválida. Tente novamente.
			read -p 'Pressione Enter para continuar...'
			;;
	esac
done


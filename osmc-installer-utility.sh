#!/bin/bash

echo "****************************************************************************************************"
echo "This utility will download the official OSMC image and install it to your target device (eg. sdcard)."
echo "Make sure the target device is NOT CONNECTED before continuing."
echo "****************************************************************************************************"

OS=`uname -s`
if [[ $OS == Darwin ]]; then

	read -p "Is the target device currently removed from your system? (y/n): " ANSWER
	while true
	do
		case $ANSWER in
		[yY]* )
			for CONNECTED_DISK in $(diskutil list |grep "/dev/disk"); do
				LIST_WITHOUT_TARGET+=("$CONNECTED_DISK")
			done
			break;;
		[nN]* ) echo "Stopped."
			exit;;
		* )
			echo "Just enter Y or N, please."; exit ;;
		esac
	done

	echo ""
	read -p "Now please connect the target device and press 'y' to continue or 'n' to stop? (y/n): " ANSWER
	while true
	do
		case $ANSWER in
		[yY]* )
			sleep 5
			for CONNECTED_DISK in $(diskutil list |grep "/dev/disk"); do
				LIST_WITH_TARGET+=("$CONNECTED_DISK")
			done
			break;;
		[nN]* ) echo "Stopped."
			exit;;
		* )
			echo "Just enter Y or N, please."; exit ;;
		esac
	done

	LIST_WITH_ONLY_TARGET=()
	for i in "${LIST_WITH_TARGET[@]}"; do
	skip=
		for j in "${LIST_WITHOUT_TARGET[@]}"; do
			[[ $i == $j ]] && { skip=1; break; }
		done
		[[ -n $skip ]] || LIST_WITH_ONLY_TARGET+=("$i")
	done
	
	AMOUNT_OF_NEW_DISKS=${#LIST_WITH_ONLY_TARGET[@]}
	if [[ "$AMOUNT_OF_NEW_DISKS" == "0" ]]; then
		echo "No new device detected. Stopping..."
		exit 1
	elif [[ "$AMOUNT_OF_NEW_DISKS" > "1" ]]; then
		echo "You inserted more than 1 new device. Stopping..."
		exit 1
	fi
	
	for TARGET_DEVICE in $LIST_WITH_ONLY_TARGET; do
		echo ""
		echo "Using: $TARGET_DEVICE"
		break;
	done
	
	echo ""
	read -p "Which raspberry pi do you have? (1/2): " ANSWER
	while true
	do
		case $ANSWER in
		[1]* )
			IMAGE_NAME="OSMC_TGT_rbp1_20150519.img.gz"
			IMAGE_URL=" OSMC_TGT_rbp1_20150519.img.gz"
			IMAGE_MD5="71319d4b07066c0da72b02d94bc8b3a2"
			break;;
		[2]* )
			IMAGE_NAME="OSMC_TGT_rbp2_20150519.img.gz"
			IMAGE_MD5="23d60b89de02b4128595eef3286e5342"
			break;;
		* )
			echo "Just enter 1 or 2, please."; exit ;;
		esac
	done

	rm -rf osmc_temp && mkdir osmc_temp && pushd osmc_temp

	IMAGE_LOCATION="http://46.37.189.135/osmc/download/installers/diskimages"
	curl -o "$IMAGE_NAME" "$IMAGE_LOCATION/$IMAGE_NAME"
	DOWNLOADED_IMAGE_MD5=$(md5 "$IMAGE_NAME" |awk '{print $4}')

	if [[ "$DOWNLOADED_IMAGE_MD5" != "$IMAGE_MD5" ]]; then
		echo "Incorrect MD5 checksum!. Exiting..."
		exit 1
	else
		gunzip "$IMAGE_NAME"
	fi
	
	echo ""
	diskutil unmountDisk "$TARGET_DEVICE" && 
	echo "Enter your password (if asked) to access the device" &&
	sudo dd bs=1m if="${IMAGE_NAME%.*}" of="/dev/rdisk${TARGET_DEVICE: -1}" && 
	sleep 3 &&
	diskutil eject "$TARGET_DEVICE" &&
	echo "" && echo "You can safely remove the device and plug it into your Raspberry Pi"
	popd
	rm -rf osmc_temp
else
	echo ""
	echo "Unsupported system: $OS"
	exit 1
fi


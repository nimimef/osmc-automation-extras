#!/bin/bash

# Tested and working on OSMC_TGT_rbp2_20150412.img
#
# This script only works if you have installed OSMC. Use a fast microSD card.
# Make sure you have your storage device connected during installation.
# The biggest available mounted media will be selected.


USERNAME="osmc"
PASSWORD="osmc"

COUNTRY="Central Europe"
TIMEZONE="Europe/Amsterdam"
TIMEZONECOUNTRY="Netherlands"

PORT_MARASCHINO=7000
PORT_COUCHPOTATO=9001
PORT_SICKRAGE=9002
PORT_SABNZBD=9003
PORT_TRANSMISSION=8004
PORT_KODI=8888


SSLCERT_SUBJ="/CN="$(cat /etc/hostname)

# Folder structure
SABNZBD_DOWNLOADDIR="/Downloads"
SABNZBD_INCOMPLETEDIR="/Downloads-incomplete/Sabnzbd"
TRANSMISSION_DOWNLOADDIR="/Downloads"
TRANSMISSION_INCOMPLETEDIR="/Downloads-incomplete/Transmission"

COUCHPOTATO_DOWNLOADDIR="/Downloads-incomplete/Couchpotato"
SICKRAGE_DOWNLOADDIR="/Downloads-incomplete/Sickrage"

DOWNLOADED_MOVIES_DIR="/Downloads/Movies"
DOWNLOADED_TVSHOWS_DIR="/Downloads/TV Shows"
COLLECTION_MOVIES_DIR="/Movies"
COLLECTION_TVSHOWS_DIR="/TV Shows"

# General #######################################################################

echo "Starting installation..."
sudo apt-get update -qq

echo '# Storage Device #######################################################################'

CONNECTED_MEDIA="$(fdisk -l |grep sda)"
if [[ "$CONNECTED_MEDIA" == "" ]]; then
	echo "No USB storage device detected."
	STORAGEDIR="/Storage"
else
	STORAGEDIR=$(df |grep "$(df |grep '/media/' |awk '{print $2}' |awk '{max=$1<max&&max~/./?max:$1;min=$1>min&&min~/./?min:$1}END{print max}')" |awk '{print $6}') && echo "$STORAGEDIR"
	echo "Using storage device: "$STORAGEDIR
	df |grep "$(df |grep '/media/' |awk '{print $2}' |awk '{max=$1<max&&max~/./?max:$1;min=$1>min&&min~/./?min:$1}END{print max}')" |grep '/media'
fi

sudo mkdir -p "$STORAGEDIR""$SABNZBD_INCOMPLETEDIR"
sudo mkdir -p "$STORAGEDIR""$SABNZBD_DOWNLOADDIR"
sudo mkdir -p "$STORAGEDIR""$COUCHPOTATO_DOWNLOADDIR"
sudo mkdir -p "$STORAGEDIR""$SICKRAGE_DOWNLOADDIR"
sudo mkdir -p "$STORAGEDIR""$TRANSMISSION_INCOMPLETEDIR"
sudo mkdir -p "$STORAGEDIR""$TRANSMISSION_DOWNLOADDIR"
sudo mkdir -p "$STORAGEDIR""$DOWNLOADED_MOVIES_DIR"
sudo mkdir -p "$STORAGEDIR""$COLLECTION_MOVIES_DIR"
sudo mkdir -p "$STORAGEDIR""$DOWNLOADED_TVSHOWS_DIR"
sudo mkdir -p "$STORAGEDIR""$COLLECTION_TVSHOWS_DIR"
sudo chown -R osmc:osmc "$STORAGEDIR"/* && sudo chmod 777 -R "$STORAGEDIR"/*




echo '# Openssl certificate #######################################################################'

sudo mkdir -p /var/ssl/
SSLKEY_PATH="/var/ssl/"$(cat /etc/hostname)".key" && echo $SSLKEY_PATH
SSLCERT_PATH="/var/ssl/"$(cat /etc/hostname)".cert" && echo $SSLCERT_PATH
sudo openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -subj "$SSLCERT_SUBJ" -keyout "$SSLKEY_PATH" -out "$SSLCERT_PATH"




echo '# Unrar #######################################################################'

cd /home/osmc/
wget -q http://sourceforge.net/projects/bananapi/files/unrar_5.2.6-1_armhf.deb && sudo dpkg -i unrar_5.2.6-1_armhf.deb && rm unrar_5.2.6-1_armhf.deb




echo '# SABnzbd+ #######################################################################'

sudo apt-get install -y -qq sabnzbdplus par2 python-openssl python-yenc

FIND="USER="; REPLACE="USER=osmc"; sudo sed -i "s/.*$FIND.*/$REPLACE/g" /etc/default/sabnzbdplus
FIND="HOST="; REPLACE="HOST=0.0.0.0"; sudo sed -i "s/.*$FIND.*/$REPLACE/g" /etc/default/sabnzbdplus
FIND="PORT="; REPLACE="PORT=8000"; sudo sed -i "s/.*$FIND.*/$REPLACE/g" /etc/default/sabnzbdplus
sudo update-rc.d sabnzbdplus defaults

sudo service sabnzbdplus start && sleep 10 && sudo service sabnzbdplus restart && sleep 5 && sudo service sabnzbdplus stop
SABNZBD_APIKEY=$(cat /home/osmc/.sabnzbd/sabnzbd.ini |grep -m 1 "api_key = " |awk '{print $3}') && echo "Api key found: ""$SABNZBD_APIKEY"

rm -Rf /home/osmc/.sabnzbd
mkdir /home/osmc/.sabnzbd
touch /home/osmc/.sabnzbd/sabnzbd.ini
chmod 600 /home/osmc/.sabnzbd/sabnzbd.ini
echo '__version__ = 19
[misc]
https_port = '$PORT_SABNZBD'
https_key = '$SSLKEY_PATH'
pre_check = 1
api_key = '$SABNZBD_APIKEY'
password = '$PASSWORD'
permissions = 777
download_free = 1G
port = 8000
host = 0.0.0.0
pause_on_post_processing = 1
fail_hopeless = 1
download_dir = '$STORAGEDIR''$SABNZBD_INCOMPLETEDIR'
complete_dir = '$STORAGEDIR''$SABNZBD_DOWNLOADDIR'
par2_multicore = 0
check_new_rel = 0
enable_https = 1
top_only = 1
username = '$USERNAME'
pause_on_pwrar = 2
https_cert = '$SSLCERT_PATH'
action_on_unwanted_extensions = 1
[categories]
[[*]]
priority = 0
pp = 3
name = *
script = None
newzbin = ""
dir = ""
[[couchpotato]]
priority = -100
pp = ""
name = couchpotato
script = Default
newzbin = ""
dir = '$STORAGEDIR''$COUCHPOTATO_DOWNLOADDIR'
[[sickrage]]
priority = -100
pp = ""
name = sickrage
script = Default
newzbin = ""
dir = '$STORAGEDIR''$SICKRAGE_DOWNLOADDIR'
' > /home/osmc/.sabnzbd/sabnzbd.ini
sudo service sabnzbdplus start




echo '# Transmission #######################################################################'

sudo apt-get install -y -qq transmission-daemon && sudo service transmission-daemon stop
#sudo usermod -a -G osmc debian-transmission
#sudo usermod -a -G debian-transmission osmc

FIND="USER="; REPLACE="USER=osmc"; sudo sed -i "s/.*$FIND.*/$REPLACE/g" /etc/init.d/transmission-daemon

sudo rm -f /etc/transmission-daemon/settings.json
sudo touch /etc/transmission-daemon/settings.json
sudo chmod 666 /etc/transmission-daemon/settings.json
echo '{
    "download-dir": "'$STORAGEDIR''$TRANSMISSION_DOWNLOADDIR'", 
    "download-queue-size": 5,
    "idle-seeding-limit-enabled": true, 
    "incomplete-dir": "'$STORAGEDIR''$TRANSMISSION_INCOMPLETEDIR'", 
    "incomplete-dir-enabled": true, 
    "ratio-limit-enabled": true, 
    "rpc-password": "'$PASSWORD'", 
    "rpc-port": '$PORT_TRANSMISSION', 
    "rpc-username": "'$USERNAME'", 
    "rpc-whitelist": "*.*.*.*", 
    "rpc-whitelist-enabled": false, 
    "seed-queue-size": 5, 
    "umask": 00
}
' > /etc/transmission-daemon/settings.json
#sudo chown debian-transmission:debian-transmission /etc/transmission-daemon/settings.json
sudo chown root:osmc /etc/transmission-daemon
sudo chmod 777 /etc/transmission-daemon
sudo chown osmc:osmc /etc/transmission-daemon/settings.json
sudo chmod 666 /etc/transmission-daemon/settings.json




echo '# CouchPotato #######################################################################'

sudo apt-get install -y -qq git
sudo git clone http://github.com/RuudBurger/CouchPotatoServer /opt/CouchPotato
sudo chown -R osmc:osmc /opt/CouchPotato

sudo cp /opt/CouchPotato/init/ubuntu /etc/init.d/couchpotato && sudo chmod a+x /etc/init.d/couchpotato
sudo su -c "echo 'CP_HOME=/opt/CouchPotato
CP_USER=osmc
CP_PIDFILE=/home/osmc/couchpotato.pid
CP_DATA=/opt/CouchPotato' > /etc/default/couchpotato"
sudo update-rc.d couchpotato defaults

rm -f /opt/CouchPotato/settings.conf
touch /opt/CouchPotato/settings.conf
chmod 666 /opt/CouchPotato/settings.conf
echo '[core]
username = '$USERNAME'
ssl_key = '$SSLKEY_PATH'
ssl_cert = '$SSLCERT_PATH'
launch_browser = 0
password = '$(echo -n "$PASSWORD" | md5sum | awk '{print $1}')'
port = '$PORT_COUCHPOTATO'
show_wizard = 0
permission_folder = 0777
permission_file = 0666

[sabnzbd]
category = couchpotato
enabled = 1
ssl = 1
host = localhost:'$PORT_SABNZBD'
api_key = '$SABNZBD_APIKEY'

[transmission]
username = '$USERNAME'
enabled = 1
host = http://localhost:'$PORT_TRANSMISSION'
password = '$PASSWORD'
directory = '$STORAGEDIR''$COUCHPOTATO_DOWNLOADDIR'

[blackhole]
enabled = 0

[manage]
library_refresh_interval = 1
enabled = 1
library = '$STORAGEDIR''$DOWNLOADED_MOVIES_DIR'::'$STORAGEDIR''$COLLECTION_MOVIES_DIR'

[renamer]
cleanup = 0
enabled = 1
from = '$STORAGEDIR''$COUCHPOTATO_DOWNLOADDIR'
to = '$STORAGEDIR''$DOWNLOADED_MOVIES_DIR'
move_leftover = 1
file_action = move
replace_doubles = 0
unrar = 1

[xbmc]
username = '$USERNAME'
enabled = 1
host = localhost:'$PORT_KODI'
password = '$PASSWORD'
meta_enabled = 1
meta_thumbnail = 0
meta_nfo = 0
meta_fanart = 0

[charts]
hide_wanted = 1
hide_library = 1
max_items = 10

[imdb]
chart_display_theater = 0
chart_display_boxoffice = 1
automation_enabled = 1
chart_display_rentals = 1
automation_urls_use = 1,1
automation_providers_enabled = 0
automation_charts_rentals = 0
automation_charts_theater = 0
chart_display_enabled = 1
automation_charts_boxoffice = 0

[download_providers]

[subtitle]
languages = en
enabled = 1

[trailer]
quality = 1080p
enabled = 1

[notification_providers]

[nzb_providers]

[binsearch]
enabled = 1

[nzbclub]
enabled = 1

[newznab]
enabled = 0

[torrent_providers]

[kickasstorrents]
seed_time = 0
enabled = True
only_verified = 1
seed_ratio = 0

[thepiratebay]
seed_time = 0
enabled = 0
seed_ratio = 0

[torrentz]
verified_only = True
minimal_seeds = 1
enabled = 0
seed_time = 0
seed_ratio = 1

[yify]
seed_time = 0
enabled = 0
seed_ratio = 0

[torrent]
minimum_seeders = 1

[omgwtfnzbs]
enabled = 0
extra_score = 20

[automation_providers]

[bluray]
chart_display_enabled = 0

' > /opt/CouchPotato/settings.conf




echo '# SickRage #######################################################################'

sudo apt-get install -y -qq git python-cheetah
sudo git clone https://github.com/SiCKRAGETV/SickRage.git /opt/sickrage
sudo chown -R osmc:osmc /opt/sickrage

sudo cp /opt/sickrage/runscripts/init.ubuntu /etc/init.d/sickrage && sudo chmod a+x /etc/init.d/sickrage
sudo su -c "echo '
SR_USER=osmc
SR_HOME=/opt/sickrage
SR_PIDFILE=/home/osmc/sickrage.pid
SR_DATA=/opt/sickrage' > /etc/default/sickrage"
sudo update-rc.d sickrage defaults

rm -f /opt/sickrage/config.ini
touch /opt/sickrage/config.ini
chmod 644 /opt/sickrage/config.ini
echo '[General]
web_port = '$PORT_SICKRAGE'
web_host = 0.0.0.0
web_username = '$USERNAME'
web_password = '$PASSWORD'
enable_https = 1
https_cert = '$SSLCERT_PATH'
https_key = '$SSLKEY_PATH'
use_nzbs = 1
use_torrents = 1
nzb_method = sabnzbd
torrent_method = transmission
usenet_retention = 1100
quality_default = 33271
provider_order = usenet_crawler sick_beard_index binsearch womble_s_index omgwtfnzbs animenzb animezb kickasstorrents eztv nyaatorrents ezrss tokyotoshokan thepiratebay oldpiratebay rarbg nzbs_org hounddawgs hdbits alpharatio scenetime btn torrentbytes speedcd tntvillage shazbat_tv morethantv iptorrents torrentday sceneaccess bitsoup hdtorrents freshontv nextgen t411 torrentleech
root_dirs = 0|'$STORAGEDIR''$DOWNLOADED_TVSHOWS_DIR'|'$STORAGEDIR''$COLLECTION_TVSHOWS_DIR'
tv_download_dir = '$STORAGEDIR''$SICKRAGE_DOWNLOADDIR'
keep_processed_dir = 0
process_method = move
del_rar_contents = 1
process_automatically = 1
unpack = 1
[KICKASSTORRENTS]
kickasstorrents = 1
kickasstorrents_confirmed = 1
kickasstorrents_ratio = 0
kickasstorrents_minseed = 0
kickasstorrents_minleech = 0
kickasstorrents_proxy = 1
kickasstorrents_proxy_url = http://getprivate.eu/
kickasstorrents_search_mode = sponly
kickasstorrents_search_fallback = 0
kickasstorrents_enable_daily = 1
kickasstorrents_enable_backlog = 1
[USENET_CRAWLER]
usenet_crawler = 1
usenet_crawler_search_mode = eponly
usenet_crawler_search_fallback = 0
usenet_crawler_enable_daily = 1
usenet_crawler_enable_backlog = 1
[SICK_BEARD_INDEX]
sick_beard_index = 1
sick_beard_index_search_mode = eponly
sick_beard_index_search_fallback = 0
sick_beard_index_enable_daily = 1
sick_beard_index_enable_backlog = 1
[BINSEARCH]
binsearch = 1
binsearch_search_mode = eponly
binsearch_search_fallback = 0
binsearch_enable_daily = 1
binsearch_enable_backlog = 1
[WOMBLE_S_INDEX]
womble_s_index = 1
womble_s_index_search_mode = eponly
womble_s_index_search_fallback = 0
womble_s_index_enable_daily = 1
womble_s_index_enable_backlog = 1
[OMGWTFNZBS]
omgwtfnzbs = 0
omgwtfnzbs_search_mode = eponly
omgwtfnzbs_search_fallback = 1
omgwtfnzbs_enable_daily = 1
omgwtfnzbs_enable_backlog = 1
[SABnzbd]
sab_username = '$USERNAME'
sab_password = '$PASSWORD'
sab_apikey = '$SABNZBD_APIKEY'
sab_category = sickrage
sab_category_anime = anime
sab_host = https://localhost:'$PORT_SABNZBD'/
sab_forced = 0
[TORRENT]
torrent_username = '$USERNAME'
torrent_password = '$PASSWORD'
torrent_host = http://localhost:'$PORT_TRANSMISSION'/
torrent_path = '$STORAGEDIR''$SICKRAGE_DOWNLOADDIR'
[KODI]
use_kodi = 1
kodi_host = 0.0.0.0:'$PORT_KODI'
kodi_username = '$USERNAME'
kodi_password = '$PASSWORD'
[Subtitles]
use_subtitles = 1
subtitles_languages = "en"
SUBTITLES_SERVICES_LIST = "itasa,subtitulos,tvsubtitles,opensubtitles,addic7ed,usub,subscenter,thesubdb,subswiki"
SUBTITLES_SERVICES_ENABLED = 0|0|0|1|0|0|0|1|0
subtitles_dir = ""
subtitles_default = 1
[FailedDownloads]
use_failed_downloads = 1
delete_failed = 1
' > /opt/sickrage/config.ini




echo '# Kodi #######################################################################'

sudo touch /walkthrough_completed && sudo chmod 644 /walkthrough_completed && sudo chown osmc:osmc /walkthrough_completed

cd /home/osmc/
wget https://github.com/asavah/script.pidisplaypower/raw/master/script.pidisplaypower-1.0.zip

rm -Rf /home/osmc/Downloads /home/osmc/Movies /home/osmc/Music /home/osmc/Pictures /home/osmc/TV\ Shows

rm -f /home/osmc/.kodi/userdata/sources.xml
touch /home/osmc/.kodi/userdata/sources.xml
chmod 644 /home/osmc/.kodi/userdata/sources.xml
echo '<sources>
    <programs>
        <default pathversion="1"></default>
    </programs>
    <video>
        <default pathversion="1"></default>
        <source>
            <name>Movies</name>
            <path pathversion="1">'$STORAGEDIR''$COLLECTION_MOVIES_DIR'/</path>
            <path pathversion="1">'$STORAGEDIR''$DOWNLOADED_MOVIES_DIR'/</path>
            <allowsharing>true</allowsharing>
        </source>
        <source>
            <name>TV Shows</name>
            <path pathversion="1">'$STORAGEDIR''$COLLECION_TVSHOWS_DIR'/</path>
            <path pathversion="1">'$STORAGEDIR''$DOWNLOADED_TVSHOWS_DIR'/</path>
            <allowsharing>true</allowsharing>
        </source>
    </video>
    <music>
        <default pathversion="1"></default>
    </music>
    <pictures>
        <default pathversion="1"></default>
    </pictures>
    <files>
        <default pathversion="1"></default>
    </files>
</sources>
' > /home/osmc/.kodi/userdata/sources.xml

rm -f /home/osmc/.kodi/userdata/guisettings.xml
touch /home/osmc/.kodi/userdata/guisettings.xml
chmod 644 /home/osmc/.kodi/userdata/guisettings.xml
echo '<settings>
    <audiooutput>
        <audiodevice>PI:Both</audiodevice>
    </audiooutput>
    <filelists>
        <allowfiledeletion>true</allowfiledeletion>
    </filelists>
    <general>
    </general>
    <locale>
        <country>'$COUNTRY'</country>
        <timezone>'$TIMEZONE'</timezone>
        <timezonecountry>'$TIMEZONECOUNTRY'</timezonecountry>
    </locale>
   <screensaver>
        <time>1</time>
    </screensaver>
    <services>
        <airplay>true</airplay>
        <devicename>'$(cat /etc/hostname)'</devicename>
        <airplayios8compat>false</airplayios8compat>
        <airplaypassword>'$PASSWORD'</airplaypassword>
        <useairplaypassword default="true">false</useairplaypassword>
        <webserverpassword>'$PASSWORD'</webserverpassword>
        <webserverport>'$PORT_KODI'</webserverport>
        <webserverusername>'$USERNAME'</webserverusername>
    </services>
</settings>
' > /home/osmc/.kodi/userdata/guisettings.xml




echo '# Maraschino #######################################################################'
sudo apt-get install -y -qq git
sudo git clone https://github.com/mrkipling/maraschino.git /opt/maraschino
sudo cp /opt/maraschino/initd /etc/init.d/maraschino && sudo chmod a+x /etc/init.d/maraschino

sudo cp /opt/maraschino/default /etc/default/maraschino
FIND="PORT="; REPLACE="PORT="$PORT_MARASCHINO; sudo sed -i "s/.*$FIND.*/$REPLACE/g" /etc/default/maraschino
sudo update-rc.d maraschino defaults




echo '# Installation complete #######################################################################'
echo 'Finished! Rebooting...'
sleep 5
sudo shutdown -r now

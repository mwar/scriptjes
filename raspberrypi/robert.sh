#!/bin/bash

# Install DIALOG
REQUIRED_PKG="dialog"
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG|grep "install ok installed")
#echo Checking for $REQUIRED_PKG: $PKG_OK
clear
if [ "" = "$PKG_OK" ]; then
  echo -e "*****************\n** Moi Robert! **\n*****************\n"
  echo "We gaan even wat installeren om het e.e.a. wat duidelijker te maken"
  echo "Daar zijn we admin rechten voor nodig, dus er wordt zo om je wachtwoord gevraagd";
  echo "Het kan even duren voordat het script klaar is"
  sudo apt update >> /dev/null 2>&1
  sudo apt-get install $REQUIRED_PKG >> /dev/null 2>&1
  echo "Okee. Dat was het. Lets go!"
fi

if [ $HOME == "/root" ]; then
  dialog --title "Ingelogd als Super user" \
	--msgbox "Je bent ingelogd als root. Start het script af als gewone gebruiker\nDit kan door exit; te typen" 20 75;
  exit 0;
fi

#####
app=$( dialog --clear --stdout --title "Kies applicatie" \
	--menu "Voor welke applicatie wil je aan de slag?" \
	15 20 2 \
	1 "PiHole" \
	2 "HomeAssistant"
);

apploc=$HOME;
appname="";
case $app in
  1)
    apploc="${apploc}/pihole-docker/";
    appname="pihole";
    ;;
  2)
    apploc="${apploc}/homeassistent-docker/";
    appname="home-assistent";
    ;;
esac

cd $apploc;
####
actie=$( dialog --clear --stdout --title "Wat wil je doen?" \
	--menu "Welke actie wil je gaan uitvoeren" \
	25 50 4 \
	1 "(Her)starten" \
	2 "Stoppen" \
	3 "Updaten" \
	4 "Logs bijken"
);

clear;
dialog --clear --title "Sudo" --msgbox "We zijn admin rechten nodig.\nHierom kan je wachtwoord worden gevraagd" 10 50;


DOCKER_RUN=$(sudo systemctl is-active docker);
if [ $DOCKER_RUN == "inactive" ]; then
 sudo systemctl start docker 2>&1 | dialog --title "Run commando" \
         --programbox "Uitvoeren commando: sudo systemctl start docker" 30 100; 
fi

case $actie in
  1)
    (sudo docker-compose stop &&  \
     sudo docker-compose start && \
     echo -n -e "****\n** Herstarten voltooid\n****") 2>&1 | dialog --title "Run commando" \
	 --programbox "Uitvoeren commando: docker-compose stop & docker-compose start" 30 100;
    ;;
  2)
    (sudo docker-compose stop &&  \
     echo -n -e "****\n** Stoppen voltooid\n****") 2>&1 | dialog --title "Run commando" \
         --programbox "Uitvoeren commando: docker-compose stop & docker-compose start" 30 100;
    ;;
  3)
    (sudo docker-compose pull &&  \
     sudo docker-compose stop && \
     sudo docker-compose start
     echo -n -e "****\n** Herstarten voltooid\n****") 2>&1 | dialog --title "Run commando" \
         --programbox "Uitvoeren commando: docker-compose pull && docker-compose stop && docker-compose start" 30 100;
    ;;
  4)
    dialog --title "Logs bekijken" \
         --msgbox "Je gaat de logging bekijken van ${appname} en die blijf je volgen.\nOm te stoppen toets CTRL + C" 30 100;
    docker logs -n 100 -f $appname;
    ;;
esac

#!/usr/bin/env python3

# Bibliotheken_Implementierung
import os, re, subprocess, sys

# Variablen_Bereich
Pfad_Netzwerkkarten = "/etc/sysconfig/network-scripts"

# Listen_Bereich
Liste_Auswahl = []
Liste_Adressen = []
Liste_Adapter_Namen = []
Liste_Adapter_File_Da = []
Liste_Adapter_File_Nicht = []
Liste_Einstellungen_Neu = []

Liste_UUID = []

# Sprache_Festlegen
Ueberpruefung = subprocess.getoutput("localectl status")
if ("Layout: de" in Ueberpruefung):
	Sprache = "DE"
else:
	Sprache = "ENG"

def Sprach_Ausgabe(Text_DE, Text_ENG, Schalter):
	if (Sprache == 'DE'):
		print (Text_DE)
	else:
		print (Text_ENG)
	if (Schalter == 1):
		sys.exit()

# Abfrage_der_Übergabeparameter
if (len(sys.argv) > 6):
	Sprach_Ausgabe(("Es wurden zu viele Parameter angegeben!\n\nEs sind maximal fünf Parameter zulässig.\n", "It's not possible to write more than five parameters.\n"), 1)
elif (len(sys.argv) != 6):
	Sprach_Ausgabe("Es wurden zu wenige Parameter angegeben!\n\n1. IP-Adresse:\n2. Prefix:\n3. DNS-Server\n4. Gateway:\n5. Search-Domain:", "Too few parameters were specified.\n\n1. ip-address:\n2. prefix:\n3. dns-server:\n4. gateway:\n5. search-domain:\n", 1)

# Netzwerkadapter_Filtern
Adapter_Namen = subprocess.getoutput('lshw -class network | grep "logical name"')
Cutter = re.split("logical name:|\n", Adapter_Namen)

for i in Cutter:
	Konverter = i.split(" ")
	if (Konverter[1] != ""):
		if (Konverter[1] not in Liste_Adapter_Namen):
			Liste_Adapter_Namen.append(Konverter[1])

# Ueberpruefung_der_konfigurierten_Dateien
n = 0
Beenden = 0
Pfad_Anzeige = os.listdir(Pfad_Netzwerkkarten)
while (Beenden != 1):
	try:
		if (Liste_Adapter_Namen[n] in str(Pfad_Anzeige)):
			Liste_Adapter_File_Da.append('ifcfg-' + str(Liste_Adapter_Namen[n]))
		else:
			Liste_Adapter_File_Nicht.append('ifcfg-' + str(Liste_Adapter_Namen[n]))
		n += 1
	except IndexError:
		Beenden = 1

# Ueberpruefung_der_Einstellungen
Beenden = 0
for i in Liste_Adapter_File_Da:
	Datei = open(str(Pfad_Netzwerkkarten + '/' + str(i)), 'r')
	Text = Datei.readlines()
	Datei.close()

	def Datei_Bearbeiten(m = 0, Schreib_Vorgang = 1):
		with open(Pfad_Netzwerkkarten + '/' + str(i), 'w') as f:
			while (Schreib_Vorgang != 0):
				try:
					f.write(str(Liste_Einstellungen_Neu[m]) + '\n')
					m += 1
				except IndexError:
					Schreib_Vorgang = 0
		f.close()
		Liste_Einstellungen_Neu.clear()

	def Auswahl_Anzeigen(Auswahl):
		global Laenge
		os.system('clear')
		for j in range(0, len(Text)):
			Cut = Text[j].split('\n')
			if (Auswahl == '' or Auswahl == ' '):
				print (j, Cut[0])
			else:
				if (int(Auswahl) == j):
					print ('\n'+str(j) + ' Alter Wert: ' + Cut[0])
					Neuer_Wert = str(input(str(j) + ' Neuer Wert: '))
					if (Neuer_Wert != '' and Neuer_Wert != ' '):
						if (Neuer_Wert not in Liste_Einstellungen_Neu):
							Liste_Einstellungen_Neu.append(Neuer_Wert)
				else:
					print (j, Cut[0])
					if (Cut[0] not in Liste_Einstellungen_Neu):
						Liste_Einstellungen_Neu.append(Cut[0])
		Laenge = j
		print ('\n')

	def Werte_Anzeigen():
		os.system('clear')
		Auswahl_Anzeigen("")

	for k in Text:
		if ("ONBOOT=no" in k):
			if (Sprache == 'DE'):
				print ("Möchten Sie den Adapter "+str(i)+" aktivieren oder bearbeiten?")
				Eingabe = str(input("Ihre Eingabe: "))
			else:
				print("Would you want to activate or edit the adapter "+str(i)+"?")
				Eingabe = str(input("Your Input: "))
			if (Eingabe == 'aktivieren' or Eingabe == 'Aktivieren' or Eingabe == 'AKTIVIEREN' or Eingabe == 'A' or Eingabe == 'a' or Eingabe == 'activate' or Eingabe == 'Activate' or Eingabe == 'ACTIVATE'):
				os.system('clear')
				subprocess.run(['ifup', i[6:]])
			elif (Eingabe == 'bearbeiten' or Eingabe == 'Bearbeiten' or Eingabe == 'b' or Eingabe == 'B' or Eingabe == 'edit' or Eingabe == 'Edit' or Eingabe == 'EDIT' or Eingabe == 'e' or Eingabe == 'E'):
				Werte_Anzeigen()
				Sprach_Ausgabe("\nWelche Einstellungen möchten Sie verändern?\nSie können auch Werte mit 'Add' hinzufügen oder das Menü mit 'Beenden' verlassen.\n", "\nWhich configuration should be edit?\nIt is also possible to use 'add' to add a new value.\nTo leave the menu please type 'exit'.\n", 0)
				while (Beenden != 1):
					if (Sprache == "DE"):
						Abfrage = str(input("Ihre Eingabe: "))
					else:
						Abfrage = str(input("Decision: "))
					if (Abfrage != "" or Abfrage != " "):
						if (Abfrage.isdigit()):
							Auswahl_Anzeigen(Abfrage)
							Datei_Bearbeiten()
							Beenden = 1
						else:
							Sprach_Ausgabe('Ihre Eingabe ist nicht zulässig!', "It’s not possible to use this number.", 0)
					elif (Abfrage == "Beenden" or Abfrage == "beenden" or Abfrage == "b" or Abfrage == "B" or Abfrage == "Exit" or Abfrage == "exit" or Abfrage == "e" or Abfrage == "E" or Abfrage == "BEENDEN" or Abfrage == "EXIT"):
						Beenden = 1
					elif (Abfrage == "Add" or Abfrage == "add" or Abfrage == "a" or Abfrage == "A"):
						Werte_Anzeigen()
						if (Sprache == "DE"):
							Frage = str(input("Ihre Eingabe: "))
						else:
							Frage = str(input("Decision: "))
			else:
				Sprach_Ausgabe("Der Adapter "+str(i)+" wurde nicht aktiviert.", "The network interface "+str(i)+" was not activated.", 0)

# Ueberpruefung_der_IP_Adresse
Adapter = ""
IP_Adresse = ""
for i in Liste_Adapter_Namen:
	Statement = "ip a show " + str(i) + '| grep "inet"'
	Ueberpruefung = subprocess.getoutput(Statement)
	Konverter = re.findall("[0-9./0-9 ]", Ueberpruefung)
	for j in range(0, len(Konverter)):
		IP_Adresse += Konverter[j]
	Adapter = i + IP_Adresse
	if (Adapter not in Liste_Adressen):
		Liste_Adressen.append(Adapter)
	IP_Adresse = ""
	Adapter = ""

# Vergabe_einer_UUID_fuer_neue_Adapter
for i in Liste_Adapter_File_Nicht:
	UUID = subprocess.getoutput(["uuidgen", i])
	Liste_UUID.append(UUID)

# Konfiguration_der_neuen_Adapter
n = 0
Liste_Einstellungen = ["TYPE=Ethernet","PROXY_METHOD=none","BROWSER_ONLY=no", "BOOTPROTO=static","DEFROUTE=yes","IPV4_FAILURE_FATAL=no", "IPV6INIT=yes","IPV6_AUTOCONF=yes","IPV6_DEFROUTE=yes", "IPV6_FAILURE_FATAL=yes","IPV6_ADDR_GEN_MODE=stable-privacy","NAME=","UUID=","DEVICE=","ONBOOT=yes","IPADDR=", "PREFIX=","DNS1=",'GATEWAY=','SEARCH=']

Pfad = Pfad_Netzwerkkarten
for i in Liste_Adapter_File_Nicht:
	Datei = open((Pfad + "/" + str(i)), 'w')
	for j in Liste_Einstellungen:
		if (j == "NAME=" or j == "DEVICE="):
			Datei.write(str(j) + str(i.split('ifcfg-')[1]) + '\n')
		elif (j == "UUID="):
			Datei.write(str(j) + str(Liste_UUID[n]) + '\n')
		elif (j == "IPADDR="):
			Datei.write(str(j) + str(sys.argv[1]) + '\n')
		elif (j == "PREFIX="):
			Datei.write(str(j) + str(sys.argv[2]) + '\n')
		elif (j == "DNS1="):
			Datei.write(str(j) + str(sys.argv[3]) + '\n')
		elif (j == 'GATEWAY='):
			if (sys.argv[4] != '0' or sys.argv[4] != 0):
				Datei.write(str(j) + str(sys.argv[4]) + '\n')
		elif (j == 'SEARCH='):
			if (sys.argv[5] != '0' or sys.argv[5] != 0):
				Datei.write(str(j) + str(sys.argv[5]) + '\n')
		else:
			Datei.write(str(j) + '\n')
	n += 1
	subprocess.run(['ifup', str(i.split('ifcfg-')[1])])
	Datei.close()
os.system('service NetworkManager restart'

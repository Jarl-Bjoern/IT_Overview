#!/usr/bin/env python3

# Bibliotheken_Bereich
import os, re, subprocess, sys

# Variablen_Bereich
Festplatten = ""
Zusatz = ""

# Listen_Bereich
Liste_Festplatten = []
Liste_Dateisysteme = ['ext4']

# Funktions_Bereich
def Fehler_Ausgabe(Text):
	print (Text)
	sys.exit()

if (len(sys.argv) > 1 and len(sys.argv) < 7):
	def Paramter_Zaehler():
		Anzahl = len(sys.argv)
		for i in range(1, len(sys.argv)):
			if ("/dev/" not in i):
				Liste_Festplatten.append("/dev/" + str(i))
			elif ('/dev/' in i):
				Liste_Festplatten.append(i)
			else:
				Fehler_Ausgabe('Ihre Festplattenangaben sind nicht zulässig!')

	def Festplatten_Upper(Endwert):
		global Festplatten, Zusatz

		for i in range(0, Liste_Festplatten):
			if (i == Endwert):
				Festplatten += Liste_Festplatten[i]
				break
			else:
				Festplatten += str(Liste_Festplatten[i]) + " "

	Parameter_Zaehler()

	Befehl = 'mdadm --create /dev/md0 --level=' + str(sys.argv[2]) + '--raid-devices=' + str(sys.argv[3])
	os.system('yum install -y mdadm')
	if ('level=10' in Befehl):
		Festplatten_Upper(4-1)
	elif ('level=1' in Befehl or 'level=0' in Befehl):
		Festplatten_Upper(2-1)
	elif ('level=6' in Befehl):
		Festplatten_Upper(6-1)
	else:
		Fehler_Ausgabe("Das gewählte RAID-Level ist nicht zulässig!")
	os.system(Befehl + Festplatten)
	Chunk = subprocess.getoutput('mdadm -D /dev/md0 | grep "Chunk Size"')
	Wert = re.split("Chunk Size|:|K", Chunk)
	print ("Welches Dateisystem möchten Sie verwenden=\n")
	Dateisystem = input("Dateisystem:")
else:
	Fehler_Ausgabe("Es wurden nicht alle Parameter angegeben!\n\n1. RAID-Level:\n2. Anzahl der Festplatten:\n3. X-Festplatten:")

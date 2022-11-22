#!/usr/bin/env python3

import subprocess

Adapter_Name = ""
Buchstaben = 0
Parameter = ""
Programm_Beenden = 0
n = 0
Zahlen = 0

def Beenden():
	global n, Programm_Beenden
	n = 0
	Programm_Beenden = 1

def Status_Anzeige(Eingabe_Wert, Run_Wert):
	global n, Parameter

	def Abfrage(Suchwert, Variable_Text, Textausgabe, Uebergabe_Run, Steuerung):
		if (Steuerung == 0):
			if (Suchwert in Variable_Text):
				print (Textausgabe)
			else:
				subprocess.run(Uebergabe_Run)
		else:
			if (Suchwert not in Variable_Text):
				print (Textausgabe)
			else:
				subprocess.run(Uebergabe_Run)

	Parameter = str(input(Eingabe_Wert))
	if (Parameter == 'Beenden' or Parameter == 'beenden' or Parameter == 'Exit' or Parameter == 'exit'):
		Beenden()
	else:
		if (n == 0):
			Abfrage('.', Parameter, ('Ihre Eingabe '+Parameter+' ist nicht möglich!'), Run_Wert, 0)
		elif (n == 1):
			Abfrage('/', Parameter, 'Es wurde keine Subnetzmaske angegeben!', Run_Wert, 1)
		else:
			subprocess.run(Run_Wert)
		n+= 1

while (Programm_Beenden != 1):
	if (n == 0):
		Adapter_Name = Parameter
		Status_Anzeige('Adaptername: ', ['nmcli connection', 'add type bridge autoconnect yes con-name', Parameter, 'ifname', Parameter])
	elif (n == 1):
		Status_Anzeige('IP-Adresse: ', ['nmcli connection modify', Adapter_Name, 'ipv4.addresses', Parameter, 'ipv4.method manual'])
	elif (n == 2):
		Status_Anzeige('Gateway: ' ['nmcli connection modify', Adapter_Name, 'ipv4.gateway', Parameter])
	elif (n == 3):
		Status_Anzeige('DNS-Server: ', ['nmcli connection modify', Adapter_Name, 'ipv4.dns', Parameter])
	elif (n == 4):
		Status_Anzeige('Search: ', ['nmcli connection modify', Adapter_Name, 'ipv4.dns-search', Parameter])
	else:
		Letzter_Wert = str(input('Hauptadapter: '))
		if (Letzter_Wert != ''):
			for i in Letzter_Wert:
				if (i.isdigit()):
					Zahlen += 1
				elif (i.islower() or i.isupper()):
					Buchstaben += 1
			if (len(Buchstaben) > 0 and len(Zahlen) > 0):
				subprocess.run(['nmcli connection del', Letzter Wert])
				subprocess.run(['nmcli connection add type bridge-slave autoconnect yes con-name', Letzter_Wert, 'ifname', Letzter_Wert, 'master', Adapter_Name])
				Beenden()
			else:
				subprocess.getoutput()
				print ('Der Netzwerkadapter ist nicht vorhanden!')
		else:
			print ('Ihre Eingabe ist nicht zulässig!')

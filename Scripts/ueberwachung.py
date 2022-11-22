#!/usr/bin/env python3

# Bibliotheken_Implementieren
import os, subprocess, threading, time

# Listen_Bereich
Liste_Adressen = []
Liste_Status = []

# Funktions_Bereich
def Listen_Updater(Wert, Listen_Name):
	if (Wert not in Listen_Name):
		Listen_Name.append(Wert)

def Text_Ueberpruefung(Dateiname):
	global Text

	Datei = open(Dateiname, "r")
	Text = Datei.readlines()
	Datei.close()

def IP_Check():
	Text_Ueberpruefung("/etc/scripts/.ip_check")
	for i in Text:
		try:
			subprocess.run(['ping', '-c 3', i], timeout=3)
		except:
			Listen_Updater(i, Liste_Adressen)

def Mail_Senden(Server_SMTP, Problemart = "" Problemstellung = ""):
	Mail_Versenden(Mail_From, Mail_To, Problemart, Problemstellung):
		msg = MIMEMultipart()
		msg['From'] = Mail_From
		msg['To'] = Mail_To
		msg['Date'] = formatdate(localtime=True)
		msg['Subject'] = "Fehler: " + Problemart

		msg.attach(MIMEText(Problemstellung, 'plain'))

		def Anhang_Bearbeiten(Datei):
			f = open(Datei, 'rb')
			p = MIMEBase('application', 'octet-stream')
			p.set_payload((f).read())
			encoders.encode_base64(p)
			p.add_header('Content-Disposition', "attachment; filename=" + str(os.path.basename(Datei)))
			msg.attach(p)
			f.close()
		if (Anhang_Senden == 1):
			Anhang_Bearbeiten(Anhang)

		if ('465' in Server_SMTP):
			Server = smtplib.SMTP(Server_SMTP, timeout=300)
			Server.ehlo()
			Server.starttls()
		elif ('587' in Server_SMTP):
			Server = smtplib.SMTP_SSL(Server_SMTP, timeout=300)
		Server.ehlo()
		Server.login(msg['From'], str(Verschluesselung.decrypt(PW[0]), 'utf-8'))
		Server.sendmail(msg['From'], msg['To'], msg.as_string())
		Server.quit()

	if (len(Liste_Status) > 0):
		for i in Liste_Status:
			Problemstellung += (str(i) + '\n')
		Problemart += "Service unerreichbar"
	if (len(Liste_Adressen) > 0):
		for i in Liste_Adressen:
			Problemstellung += (str(i) + '\n')
		if (len(Problemart) > 0):
			Problemstellung += ", IP-Adressen sind nicht erreichbar"
		else:
			Problemstellung += "IP-Adressen sind nicht erreichbar"
	if (len(Problemstellung) > 0):
		Text_Ueberpruefung("/etc/scripts/.l")
		for i in Text:
			Mail_Versenden("Testmail@gmail.com", str(i), Problemart, Problemstellung)

def Medien_Check(Durchsuchungs_Prozess = 1):
	Text_Ueberpruefung('~/.media')

	while (Durchsuchungs_Prozess != 0):
		Medien_Uebersicht = subprocess.getoutput('lsblk')
		for i in Text:

def Status_Check():
	Text_Ueberpruefung("/etc/scripts/.service_check")

	for i in Text:
		Status = subprocess.getoutput(['service '+str(i)+' status'])
		if ('failed (thawing)' in Status):
			Listen_Updater(i, Liste_Status)
		elif ('failed (Result: exit-code) in Status'):
			Listen_Updater(i, Liste_Status)
		elif ('failed (error)' in Status):
			Listen_Updater(i, Liste_Status)

def Speicher_Check():
	RAM = subprocess.getoutput('free -h')
	Festplatte = subprocess.getoutput('df -h')

def Threads_Starten(Liste_Threads = [], n = 0, count = 0, Vorgang_Beenden = 0):
	Liste_Funktionen = [IP_Check, Medien_Check, Speicher_Check, Status_Check]

	for i in Liste_Funktionen:
		T = threading.Thread(target=i, daemon=True)
		T.name = 't' + str(i)
		T.start()
		if (T.name not in Liste_Threads):
			Liste_Threads.append(T.name)

	while (Vorgang_Beenden != 1):
		if (Liste_Threads[n].is_alive()):
			time.sleep(0.2)
		else:
			if (count != len(Liste_Threads)):
				n += 1
				count += 1
			else:
				Liste_Threads.clear()
				Vorgang_Beenden = 1

# Main_Bereich
if __name__ == '__main__':
	Threads_Starten()
	Mail_Senden(Mail_From, Mail_To)

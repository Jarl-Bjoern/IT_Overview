#!/usr/bin/env python3

import os, subprocess, threading, time

Liste_Log = []

def Log_Writer():
	if (os.path.exists('/etc/clamav') == False):
		os.system('mkdir -p /etc/clamav')

	with open('/etc/clamav/log/sc.log', 'w') as f:
		for i in Liste_Log:
			f.write(i)
	f.close()

def Scan_Vorgang(Steuerung):
	def Scanner(Durchsuchungs_Art, Element):
		def Log_Append(Text_Ausgabe):
			if (Text_Ausgabe not in Liste_Log):
				Liste_Log.append(Text_Ausgabe)

		for x in Durchsuchungs_Art:
			Datei = os.path.join(Element, x)
			Befehl = f'clamscan {Datei}'
			Ausgabe = subprocess.getoutput(Befehl)
			if ('FOUND' in Ausgabe and Durchsuchungs_Art == 'dirs'):
				subprocess.run(['/usr/local/bin/clamscan -r --remove', Datei])
				Log_Append(Ausgabe)
			elif ('FOUND' in Ausgabe and Durchsuchungs_Art == 'files'):
				subprocess.run(['/usr/local/bin/clamscan --remove', Datei])
				Log_Append(Ausgabe)

	for root, dirs, files in os.walk('/', topdown=False):
		if (Steuerung == 1):
			Scanner(files, root)
		else:
			Scanner(dirs, root)

def Threads_Starten():
	t1 = threading.Thread(target=Scan_Vorgang, args=[0], daemon=True)
	t2 = threading.Thread(target=Scan_Vorgang, args=[1], daemon=True)
	t1.start(), t2.start()

	while (t1.is_alive() or t2.is_alive()):
		time.sleep(0.01)

if __name__ == '__main__':
	Threads_Starten()
	Log_Writer()

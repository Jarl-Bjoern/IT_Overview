#!/usr/bin/env python3

import os, subprocess, time

def Vorgang(Text, Schaltsystem):
	if (Schaltsystem == 1):
		Kommando = f'virsh shutdown {Text}'
	elif (Schaltsystem == 2):
		Kommando = f'virsh snapshots-delete --domain {Text} Bestandsaufnahme'
	elif (Schaltsystem == 3):
		Kommando = f'virsh snapshot-create-as --domain {Text} Bestandsaufnahme'
	elif (Schaltsystem == 4):
		Kommando = f'virsh start {Text}'
	os.system(Kommando)
	if (Schaltsystem == 1):
		while True:
			Status = subprocess.getoutput(f'virsh dominfo {Text}')
			if ('laufend' in str(Status)):
				time.sleep(0.3)
			else:
				break

with open('/etc/.scripts/vm_liste', 'r') as f:
		for i in f:
			VM_Name = i.split('\n')[0]
			Ausgabe = subprocess.getoutput(f'virsh snapshot-list --domain {VM_Name} | grep Bestandsaufnahme')
			Status = subprocess.getoutput(f'virsh dominfo {VM_Name} | grep Status')
			Autostart = subprocess.getoutput(f'virsh dominfo {VM_Name} | grep "Automatischer Start"')

			if ('laufend' in str(Status)):
				Vorgang(VM_Name, 1)
			if not (Ausgabe):
				Vorgang(VM_Name, 3)
			else:
				Vorgang(VM_Name, 2), Vorgang(VM_Name, 3)
			if ('deaktiviert' in str(Autostart)):
				pass
			else:
				Vorgang(VM_Name, 4)
f.close()

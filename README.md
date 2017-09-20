# nZEDbPreDBUpdater
Linux Bash script to download PreDB daily from nZEDb/nZEDbPreDumps

This is a script that will check https://github.com/nZEDb/nZEDbPre_Dumps/tree/master/dumps for the current folder listing and then verify against a base file if there is a new folder it will grab the contents of that folder and import into your predb using nZEDb's predb_import.php file. you may need to edit the path accordingly. 

This is still very early stage but appears to be working so far. It is not dynamic so you will need to hunt down paths. 

I installed it into my home dir under a sub folder and run it on a cronjob. 

this requires curl, wget, tail, sed, cut to be installed which should be included in most base linux installs. 

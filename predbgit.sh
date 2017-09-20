#!/bin/bash
#script to crawl the predb repo of the nzedb project to download the latest predb file.
#designed to be ran from cron and not use the GITHUB API as nZEDb does not use authenticated
#API calls causing your IP to be banned regularly

HomeDir=$PWD

#Check if initial run has been completed.
if [ -f "BaseDirList.txt" ]
then
        #Check for new directories
        curl https://github.com/nZEDb/nZEDbPre_Dumps/tree/master/dumps | grep dumps | grep href | grep -v https |grep -v login| grep -v btn | grep -v repo | grep -v none | grep -v READM | cut -d\" -f4 | sed -n '1!p' > CurrDirList.txt
        RC=0
        diff BaseDirList.txt CurrDirList.txt
        RC=$?
        #If new directories get new directories
        if [ $RC = 1 ]
        then
                diff BaseDirList.txt CurrDirList.txt | sed -n '1!p' | cut -d\  -f2 > NewDirList.txt
                #Loop through new directories and get file list for each directory
                while read NDLine
                do
                        NDLFilename=`echo $line | cut -d\/ -f7`
                        curl https://github.com$NDLine | grep csv\.gz | cut -d\" -f4 > $NDLFilename
                        #Create and change to dumps directory
                        mkdir dumps
                        cd dumps
                        #loop through directory listing and get dump files
                        while read NDLFline
                        do
                                filename=`echo $NDLFline | cut -d\/ -f8`
                                echo "Getting $filename"
                                wget -O $filename https://github.com$NDLFline?raw=true
                        done <$HomeDir/$NDLFilename
                        #decompress all dumps and concatenate them all to 1 file
                        gunzip *.gz
                        cat *.csv > all.csv
                        #move to nzedb cli dir and import into DB
                        mv all.csv /var/www/nZEDb/cli/all.csv
                        cd /var/www/nZEDb/cli
                        /bin/php data/predb_import.php local all.csv
                        #Clean up
                        rm -f all.csv
                        cd $HomeDir
                        rm -rf dumps
                        mv $NDLFilename BaseFileList.txt
                done <NewDirList.txt
                mv CurrDirList.txt BaseDirList.txt
        else
                if [ -f BaseFileList.txt ]
                then
                        CurrDir=`tail -1 BaseDirList.txt`
                        curl https://github.com$CurrDir | grep csv\.gz | cut -d\" -f4 > CurrFileList.txt
                        RC=0
                        diff BaseFileList.txt CurrFileList.txt
                        RC=$?
                        if [ $RC = 1 ]
                        then
                                diff BaseFileList.txt CurrFileList.txt | sed -n '1!p' | cut -d\  -f2 > NewFileList.txt
                                mkdir dumps
                                cd dumps
                                while read NFLine
                                do
                                        filename=`echo $NFLine | cut -d\/ -f8`
                                        echo "Getting $filename"
                                        wget -O $filename https://github.com$NFLine?raw=true
                                done <$HomeDir/NewFileList.txt
                                gunzip *.gz
                                cat *.csv > all.csv
                                mv all.csv /var/www/nZEDb/cli/all.csv
                                cd /var/www/nZEDb/cli
                                /bin/php data/predb_import.php all.csv
                                rm -f all.csv
                                cd $HomeDir
                                rm -rf dumps
                                mv CurrFileList.txt BaseFileList.txt
                                rm -f NewFileList
                        fi
                else
                        CurrDir=`tail -1 BaseDirList.txt`
                        curl https://github.com$CurrDir | grep csv\.gz | cut -d\" -f4 > BaseFileList.txt
                        mkdir dumps
                        cd dumps
                        while read BFLine
                        do
                                filename=`echo $BFLine | cut -d\/ -f8`
                                echo "Getting $filename"
                                wget -O $filename https://github.com$BFLine?raw=true
                                echo "Decompressing $filename"
                                gunzip -v $filename
                        done <$HomeDir/BaseFileList.txt
                        cat *.csv > all.csv
                        mv all.csv /var/www/nZEDb/cli/all.csv
                        cd /var/www/nZEDb/cli
                        /bin/php data/predb_import.php local /var/www/nZEDb/cli/all.csv
                        rm -f all.csv
                        cd $HomeDir
                        rm -rf dumps
                fi
        fi
else
        #Initial Run
        #this will get a list of ALL of the PreDB dumps in the repo and download them
        #once downloaded it will run the nZEDb scripts to import them into your PreDB Database for nzedb
        echo "This is the first time the script has run. It will download the full PreDB and import into your DB. This is going to take some time."
        #download list of repo directories
        curl https://github.com/nZEDb/nZEDbPre_Dumps/tree/master/dumps | grep dumps | grep href | grep -v https |grep -v login| grep -v btn | grep -v repo | grep -v none | grep -v READM | cut -d\" -f4 | sed -n '1!p' > BaseDirList.txt
        echo "Retreiving full diectory list and getting files."
        #get dump lists from all directories in repo and import into nzedb, This may take a while
        while read BDLine
        do
                curl https://github.com$BDLine | grep csv\.gz | cut -d\" -f4 > BaseFileList.txt
                mkdir dumps
                cd dumps
                while read BFLine
                do
                        filename=`echo $BFLine | cut -d\/ -f8`
                        echo "Getting $filename"
                        wget -q -O $filename https://github.com$BFLine?raw=true
                        echo "Decompressing $filename"
                        gunzip -v $filename
                done <$HomeDir/BaseFileList.txt
                #gunzip *.gz
                cat *.csv > all.csv
                mv all.csv /var/www/nZEDb/cli/all.csv
                cd /var/www/nZEDb/cli
                echo "Importing PreDB files for current directory"
                /bin/php data/predb_import.php local /var/www/nZEDb/cli/all.csv
                rm -f all.csv
                cd $HomeDir
                rm -rf dumps
        done <BaseDirList.txt
        echo "***********Process Complete***********"
fi


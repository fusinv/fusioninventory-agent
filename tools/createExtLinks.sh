#!/bin/sh
# Create symblink to the subi task modules
set -e

for task in Deploy SNMPQuery NetDiscovery NetInventory ESX; do
    taskLcName=`perl -e" print lc \"$task\""`
    taskFile=$PWD/../agent-task-$taskLcName/lib/FusionInventory/Agent/Task/$task.pm
    taskDir=$PWD/../agent-task-$taskLcName/lib/FusionInventory/Agent/Task/$task
    if [ -f "$taskFile" ] && [ ! -e lib/FusionInventory/Agent/Task/$task.pm ]; then
        echo "create link for $task"
        ln -s "$PWD/../agent-task-$taskLcName/lib/FusionInventory/Agent/Task/$task.pm" lib/FusionInventory/Agent/Task/
        if [ -d "$taskDir" ] && [ ! -e lib/FusionInventory/Agent/Task/$task ]; then
            ln -s "$PWD/../agent-task-$taskLcName/lib/FusionInventory/Agent/Task/$task" lib/FusionInventory/Agent/Task/$task
        fi
    fi
done
if [ ! -e lib/FusionInventory/VMware ]; then
    ln -s "$PWD/../agent-task-esx/lib/FusionInventory/VMware" lib/FusionInventory/VMware
fi
if [ ! -e lib/FusionInventory/Agent/SNMP.pm ]; then
    ln -s $PWD/../agent-task-netdiscovery/lib/FusionInventory/Agent/SNMP.pm lib/FusionInventory/Agent/SNMP.pm
fi

if [ ! -e fusioninventory-esx ]; then
    ln -s $PWD/../agent-task-esx/fusioninventory-esx .
fi

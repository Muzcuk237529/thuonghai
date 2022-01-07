#!/bin/bash
stty intr ""
stty quit ""
stty susp undef








function goto
{
    label=$1
    cd 
    cmd=$(sed -n "/^:[[:blank:]][[:blank:]]*${label}/{:a;n;p;ba};" $0 | 
          grep -v ':$')
    eval "$cmd"
    exit
}




echo "⌛  Setting up... Please Wait..."

az group list | jq -r '.[0].name' > rs
rs=$(cat rs) 

az webapp list --resource-group $rs --output table |  grep -q haivm && goto checkwebapp

echo $RANDOM > number
NUMBER=$(cat number)
echo "haivm$NUMBER$NUMBER.azurewebsites.net/metrics" > site


echo "az appservice plan create --name myAppServicePlan$NUMBER$NUMBER --resource-group $rs --location eastasia --sku F1 --is-linux --output none && az webapp create --resource-group $rs --plan myAppServicePlan$NUMBER$NUMBER --name haivm$NUMBER$NUMBER --deployment-container-image-name docker.io/thuonghai2711/v2ray-azure-web:latest --output none" > webapp.sh 
nohup bash webapp.sh  &>/dev/null &

goto checkvm
: checkvm
echo "⌛  Checking Previous VM..."
az vm list-ip-addresses -n Win11-VM-AP --output tsv > IP.txt 
[ -s IP.txt ] && bash -c "echo You Already Have Running VM... && az vm list-ip-addresses -n Win11-VM-AP --output table" && goto rdp

echo "🖥️  Creating In Process..."
rs=$(cat rs) && az vm create --resource-group $rs --name Win11-VM-AP --image MicrosoftWindowsDesktop:windows-ent-cpc:win11-21h2-ent-cpc-m365:22000.318.2111180022 --public-ip-sku Standard --size Standard_DS2_v2 --location eastasia --admin-username azureuser --admin-password WindowsPassword@001 --out table

echo "⌛  Wait... (Can take up to 2m)"
: test
URL=$(cat site)
CF=$(curl -s --connect-timeout 1 --max-time 2 $URL | grep -Eo "(http|https)://[a-zA-Z0-9./?=_%:-]*" | sort -u | sed s/'http[s]\?:\/\/'//)
echo -n $CF > CF
if [ -s CF ]; then goto rdp; else goto webapp; fi

: webapp
rs=$(cat rs) 
NUMBER=$(cat number)
#az webapp config appsettings set --resource-group $rs --name haivm$NUMBER$NUMBER --settings WEBSITES_PORT=8081 --output none
goto check

: check
URL=$(cat site)
CF=$(curl -s --connect-timeout 1 --max-time 2 $URL | grep -Eo "(http|https)://[a-zA-Z0-9./?=_%:-]*" | sort -u | sed s/'http[s]\?:\/\/'//)
echo -n $CF > CF
if [ -s CF ]; then goto rdp; else sleep 1 && goto check; fi

goto rdp
: rdp

echo "VM has been created! "

echo "Username : azureuser"

echo "Password: WindowsPassword@001"

echo "🖥️  Run Command Setup Internet In Process... (70s)"
sleep 60
URL=$(cat site)
CF=$(curl -s $URL | grep -Eo "(http|https)://[a-zA-Z0-9./?=_%:-]*" | sort -u | sed s/'http[s]\?:\/\/'//) && echo $CF > CF
rs=$(cat rs)


timeout 10s az vm run-command invoke  --command-id RunPowerShellScript --name Win11-VM-AP -g $rs --scripts "cd C:\PerfLogs ; cmd /c curl -L -s -k -O https://raw.githubusercontent.com/kmille36/thuonghai/master/katacoda/AZ/alive.bat ; (gc alive.bat) -replace 'URLH', '$URL' | Out-File -encoding ASCII alive.bat ; cmd /c curl -L -s -k -O https://raw.githubusercontent.com/kmille36/thuonghai/master/katacoda/AZ/config.json ; (gc config.json) -replace 'CF', '$CF' | Out-File -encoding ASCII config.json ; cmd /c curl -L -k -O https://raw.githubusercontent.com/kmille36/thuonghai/master/katacoda/AZ/internet.bat ; cmd /c internet.bat" --out table






rm -rf CF 
rm -rf IP.txt
rm -rf rs
rm -rf webapp.sh
rm -rf number
rm -rf site

echo "Your Windows 11 VM is READY TO USE !!! "

sleep 7200

: checkwebapp
rs=$(cat rs)
web=$(az webapp list --query "[].{hostName: defaultHostName, state: state}" --output tsv | grep haivm | cut -f 1)
echo $web/metrics > site
goto checkvm

#&& az webapp config appsettings set --resource-group $rs --name haivm$NUMBER$NUMBER --settings WEBSITES_PORT=8081 --output none

#&& az webapp config appsettings set --resource-group $rs --name haivm$NUMBER$NUMBER --settings WEBSITES_PORT=8081 --output none

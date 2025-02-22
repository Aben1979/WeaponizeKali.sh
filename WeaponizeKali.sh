#!/usr/bin/env bash

nocolor="\033[0m"
green="\033[0;32m"
yellow="\033[0;33m"
red="\033[0;31m"
red_bold="\033[1;31m"
blue="\033[0;34m"
light_gray="\033[0;37m"
dark_gray="\033[1;30m"
magenta_bold="\033[1;35m"

SITE="https://github.com/penetrarnya-tm/WeaponizeKali.sh"
VERSION="0.1.5"

echo -e "${red_bold}                                                         )${nocolor}"
echo -e "${red_bold} (  (                                                  ( /(       (                )${nocolor}"
echo -e "${red_bold} )\))(   '   (     )                    (         (    )\())   )  )\ (          ( /(${nocolor}"
echo -e "${red_bold}((_)()\ )   ))\ ( /(  \`  )    (    (    )\  (    ))\  ((_)\ ( /( ((_))\     (   )\())${nocolor}"
echo -e "${red_bold}_(())\_)() /((_))(_)) /(/(    )\   )\ )((_) )\  /((_) _ ((_))(_)) _ ((_)    )\ ((_)\ ${nocolor}"
echo -e "${light_gray}\ \((_)/ /(_)) ((_)_ ((_)_\  ((_) _(_/( (_)((_)(_))  | |/ /((_)_ | | (_)   ((_)| |(_)${nocolor}"
echo -e "${light_gray} \ \/\/ / / -_)/ _\` || '_ \)/ _ \| ' \))| ||_ // -_) | ' < / _\` || | | | _ (_-<| ' \ ${nocolor}"
echo -e "${light_gray}  \_/\_/  \___|\__,_|| .__/ \___/|_||_| |_|/__|\___| |_|\_\\\\\__,_||_| |_|(_)/__/|_||_|${nocolor}"
echo -e "${light_gray}                     |_|${nocolor}"
echo    "                           \"the more tools you install, the more you are able to PWN\""
echo -e "                    ${magenta_bold}{${dark_gray} ${SITE} ${magenta_bold}} ${magenta_bold}{${dark_gray} v${VERSION} ${magenta_bold}}${nocolor}"
echo

# -----------------------------------------------------------------------------
# ----------------------------------- Init ------------------------------------
# -----------------------------------------------------------------------------

filesystem() {
	rm -rf tools www
	mkdir tools www
}

# -----------------------------------------------------------------------------
# --------------------------------- Messages ----------------------------------
# -----------------------------------------------------------------------------

info() {
	echo -e "${blue}[*] $1${nocolor}"
}

success() {
	echo -e "${green}[+] $1${nocolor}"
}

warning() {
	echo -e "${yellow}[!] $1${nocolor}"
}

fail() {
	echo -e "${red}[-] $1${nocolor}"
}

progress() {
	echo -e "${magenta_bold}[WPNZKL] Installing $1${nocolor}"
}

# -----------------------------------------------------------------------------
# ---------------------------------- Helpers ----------------------------------
# -----------------------------------------------------------------------------

_pushd() {
	pushd $1 2>&1 > /dev/null
}

_popd() {
	popd 2>&1 > /dev/null
}

installDebPackage() {
	pkg_name=$1
	if ! /usr/bin/dpkg-query -f '${Status}' -W $pkg_name 2>&1 | /bin/grep "ok installed" > /dev/null; then
		warning "$pkg_name not found, installing with apt"
		sudo apt install $pkg_name -y
	fi
	success "Installed deb package(s): $pkg_name"
}

installSnapPackage() {
	pkg_name=$1
	if ! /usr/bin/snap info $pkg_name 2>&1 | /bin/grep "installed" > /dev/null; then
		warning "$pkg_name not found, installing with snap"
		sudo snap install $pkg_name --dangerous
	fi
	success "Installed snap package(s): $pkg_name"
}

installPipPackage() {
	V=$1
	pkg_name=$2
	if ! which $pkg_name > /dev/null 2>&1; then
		warning "$pkg_name not found, installing with pip$V"
		sudo "python${V}" -m pip install -U $pkg_name
	fi
	success "Installed pip$V package(s): $pkg_name"
}

cloneRepository() {
	url=$1
	repo_name=${url##*/}
	repo_name=${repo_name%.*}

	if [ -z "$2" ]; then
		dname=$repo_name
	else
		dname=$2
	fi

	if git clone --recurse-submodules -q $url $dname; then
		success "Cloned repository: $repo_name"
	else
		fail "Failed to clone repository: $repo_name"
	fi
}

downloadRawFile() {
	url=$1
	filename=$2
	if curl -sSL $url -o $filename; then
		success "Downloaded raw file: $filename"
	else
		fail "Failed to download raw file: $filename"
	fi
}

downloadRelease() {
	full_repo_name=$1
	release_name=$2
	filename=$3
	if curl -sSL "https://api.github.com/repos/$full_repo_name/releases/latest" | jq -r '.assets[].browser_download_url' | grep $release_name | wget -O $filename -qi -; then
		success "Downloaded release: $filename"
	else
		fail "Failed to download release: $filename"
	fi
}

# -----------------------------------------------------------------------------
# ------------------------------- Dependencies --------------------------------
# -----------------------------------------------------------------------------

_jq() {
	installDebPackage "jq"
}

_eget() {
	_pushd /tmp
	curl "https://zyedidia.github.io/eget.sh" | sh
	sudo mkdir /opt/eget
	sudo mv eget /opt/eget
	sudo ln -sv "/opt/eget/eget" /usr/local/bin/eget
	_popd
}

_python2() {
	curl -sS "https://bootstrap.pypa.io/pip/2.7/get-pip.py" | sudo python2
	installDebPackage "python2-dev"
	installPipPackage 2 "setuptools"
}

_python3() {
	installDebPackage "python3-pip python3-venv python3-dev"
	installPipPackage 3 "setuptools pipx"
	pipx ensurepath
	curl -sSL "https://install.python-poetry.org" | python3 -
}

_krb5() {
	installDebPackage "libkrb5-dev krb5-user krb5-config"
}

_impacket() {
	installDebPackage "ntpsec-ntpdate"
	installPipPackage 2 "impacket"
	installPipPackage 3 "impacket"
}

_npm() {
	installDebPackage "npm"
}

_snap() {
	installDebPackage "snapd"
	sudo service snapd start
	sudo apparmor_parser -r /etc/apparmor.d/*snap-confine*
	sudo apparmor_parser -r /var/lib/snapd/apparmor/profiles/snap*
	export PATH="$PATH:/snap/bin"
}

_dotnet() {
	# For Covenant
	curl -sSL "https://dot.net/v1/dotnet-install.sh" | sudo bash /dev/stdin -Channel 3.1
	# For SharpGen
	curl -sSL "https://dot.net/v1/dotnet-install.sh" | bash /dev/stdin -Channel 2.1
}

dependencies() {
	_jq
	_eget
	_python2
	_python3
	_krb5
	_impacket
	_npm
	_snap
	_dotnet
}

# -----------------------------------------------------------------------------
# ----------------------------------- tools -----------------------------------
# -----------------------------------------------------------------------------

APIHashReplace() {
	_pushd tools
	progress "APIHashReplace"
	cloneRepository "https://github.com/matthewB-huntress/APIHashReplace.git"
	_popd
}

AutoBlue-MS17-010() {
	_pushd tools
	progress "AutoBlue-MS17-010"
	cloneRepository "https://github.com/3ndG4me/AutoBlue-MS17-010.git"
	_popd
}

BloodHound() {
	_pushd tools
	progress "BloodHound"
	installDebPackage "neo4j"
	downloadRelease "ly4k/BloodHound" BloodHound-linux-x64 BloodHound.zip
	unzip -q BloodHound.zip
	mv BloodHound-linux-x64 BloodHound
	rm BloodHound.zip
	cd BloodHound
	sudo chown root:root chrome-sandbox
	sudo chmod 4755 chrome-sandbox
	chmod +x BloodHound
	sudo mkdir /usr/share/neo4j/logs/
	mkdir -p ~/.config/bloodhound

	downloadRawFile "https://github.com/ShutdownRepo/Exegol-images/raw/main/sources/bloodhound/customqueries.json" /tmp/customqueries1.json
	downloadRawFile "https://github.com/CompassSecurity/BloodHoundQueries/raw/master/customqueries.json" /tmp/customqueries2.json
	downloadRawFile "https://github.com/ZephrFish/Bloodhound-CustomQueries/raw/main/customqueries.json" /tmp/customqueries3.json
	downloadRawFile "https://github.com/ly4k/Certipy/raw/main/customqueries.json" /tmp/customqueries4.json

	python3 - << 'EOT'
import json
from pathlib import Path

merged, dups = {'queries': []}, set()
for jf in sorted((Path('/tmp')).glob('customqueries*.json')):
    with open(jf, 'r') as f:
        for query in json.load(f)['queries']:
            if 'queryList' in query.keys():
                qt = tuple(q['query'] for q in query['queryList'])
                if qt not in dups:
                    merged['queries'].append(query)
                    dups.add(qt)

with open(Path.home() / '.config' / 'bloodhound' / 'customqueries.json', 'w') as f:
    json.dump(merged, f, indent=4)

EOT
	rm /tmp/customqueries*.json

	downloadRawFile "https://github.com/ShutdownRepo/Exegol-images/raw/main/sources/bloodhound/config.json" ~/.config/bloodhound/config.json
	sed -i 's/"password": "exegol4thewin"/"password": "WeaponizeK4li!"/g' ~/.config/bloodhound/config.json

	_popd
}

BloodHound.py() {
	progress "BloodHound.py"
	pipx install -f "git+https://github.com/fox-it/BloodHound.py.git"
}

CVE-2019-1040-scanner() {
	_pushd tools
	progress "CVE-2019-1040-scanner"
	mkdir CVE-2019-1040-scanner
	cd CVE-2019-1040-scanner
	downloadRawFile "https://github.com/fox-it/cve-2019-1040-scanner/raw/master/scan.py" CVE-2019-1040-scanner.py
	chmod +x CVE-2019-1040-scanner.py
	_popd
}

CVE-2020-1472-checker() {
	_pushd tools
	progress "CVE-2020-1472-checker"
	cloneRepository "https://github.com/SecuraBV/CVE-2020-1472.git"
	mv CVE-2020-1472 CVE-2020-1472-checker
	cd CVE-2020-1472-checker
	python3 -m pip install -U -r requirements.txt
	chmod +x zerologon_tester.py
	_popd
}

CVE-2021-1675() {
	_pushd tools
	progress "CVE-2021-1675"
	mkdir CVE-2021-1675
	cd CVE-2021-1675
	downloadRawFile "https://github.com/cube0x0/CVE-2021-1675/raw/main/CVE-2021-1675.py" CVE-2021-1675-MS-RPRN.py
	downloadRawFile "https://github.com/cube0x0/CVE-2021-1675/raw/main/SharpPrintNightmare/CVE-2021-1675.py" CVE-2021-1675-MS-PAR.py
	downloadRawFile "https://github.com/m8sec/CVE-2021-34527/raw/main/CVE-2021-34527.py" CVE-2021-1675.py
	_popd
}

Certipy() {
	progress "Certipy"
	pipx install -f "git+https://github.com/ly4k/Certipy.git"
}

Coercer() {
	progress "Coercer"
	pipx install -f "git+https://github.com/p0dalirius/Coercer.git"
}

Covenant() {
	_pushd tools
	cloneRepository "https://github.com/cobbr/Covenant.git"
	cd Covenant
	cloneRepository "https://gist.github.com/S3cur3Th1sSh1t/967927eb89b81a5519df61440357f945.git" /tmp/Stageless_Covenant_HTTP
	mv /tmp/Stageless_Covenant_HTTP/Stageless_Covenant_HTTP.cs GruntHTTPStageless.cs
	rm -rf /tmp/Stageless_Covenant_HTTP
	#cd Covenant/Covenant
	#sudo /root/.dotnet/dotnet run
	_popd
}

CrackMapExec() {
	progress "CrackMapExec"
	pipx install -f "git+https://github.com/Porchetta-Industries/CrackMapExec.git"
	mkdir -p ~/.cme
	downloadRawFile "https://github.com/penetrarnya-tm/WeaponizeKali.sh/raw/main/conf/cme.conf" ~/.cme/cme.conf
}

DFSCoerce() {
	_pushd tools
	progress "DFSCoerce"
	cloneRepository "https://github.com/Wh04m1001/DFSCoerce.git"
	cd DFSCoerce
	chmod +x dfscoerce.py
	_popd
}

DInjector() {
	_pushd tools
	progress "DInjector"
	cloneRepository "https://github.com/snovvcrash/DInjector.git"
	cd DInjector
	git checkout dev
	_popd
}

DLLsForHackers() {
	_pushd tools
	progress "DLLsForHackers"
	cloneRepository "https://github.com/Mr-Un1k0d3r/DLLsForHackers.git"
	_popd
}

DonPAPI() {
	_pushd tools
	progress "DonPAPI"
	cloneRepository "https://github.com/login-securite/DonPAPI.git"
	cd DonPAPI
	python3 -m pip install -U -r requirements.txt
	chmod +x DonPAPI.py
	_popd
}

DivideAndScan() {
	progress "DivideAndScan"
	pipx install -f "git+https://github.com/snovvcrash/DivideAndScan.git"
}

Ebowla() {
	_pushd tools
	progress "Ebowla"
	cloneRepository "https://github.com/Genetic-Malware/Ebowla.git"
	cd Ebowla
	rm -rf .git
	installDebPackage "golang mingw-w64 wine"
	python2 -m pip install -U configobj pyparsing pycrypto
	downloadRawFile "https://github.com/penetrarnya-tm/WeaponizeKali.sh/raw/main/conf/genetic.config" genetic.config
	_popd
}

Empire() {
	_pushd tools
	progress "Empire"
	cloneRepository "https://github.com/BC-SECURITY/Empire.git"
	cd Empire
	sudo STAGING_KEY=`echo 'WeaponizeK4li!' | md5sum | cut -d' ' -f1` ./setup/install.sh
	sudo poetry install
	echo $'#!/usr/bin/env bash\nsudo poetry run python empire.py ${@}' > ps-empire.sh
	chmod +x ps-empire.sh
	_popd
}

InvisibilityCloak() {
	_pushd tools
	progress "InvisibilityCloak"
	mkdir InvisibilityCloak
	cd InvisibilityCloak
	downloadRawFile "https://github.com/h4wkst3r/InvisibilityCloak/raw/main/InvisibilityCloak.py" InvisibilityCloak.py
	_popd
}

ItWasAllADream() {
	_pushd tools
	progress "ItWasAllADream"
	cloneRepository "https://github.com/byt3bl33d3r/ItWasAllADream.git"
	cd ItWasAllADream
	poetry install
	_popd
}

LDAPPER() {
	_pushd tools
	progress "LDAPPER"
	cloneRepository "https://github.com/shellster/LDAPPER.git"
	cd LDAPPER
	python3 -m pip install -U -r requirements.txt
	_popd
}

LDAPmonitor() {
	_pushd tools
	progress "LDAPmonitor"
	cloneRepository "https://github.com/p0dalirius/LDAPmonitor.git"
	cd LDAPmonitor/python
	python3 -m pip install -U -r requirements.txt
	chmod +x pyLDAPmonitor.py
	_popd
}

LdapRelayScan() {
	_pushd tools
	progress "LdapRelayScan"
	cloneRepository "https://github.com/zyn3rgy/LdapRelayScan.git"
	_popd
}

LightMe() {
	_pushd tools
	progress "LightMe"
	cloneRepository "https://github.com/WazeHell/LightMe.git"
	_popd
}

MANSPIDER() {
	progress "MANSPIDER"
	installDebPackage "antiword"
	pipx install man-spider
}

MS17-010() {
	_pushd tools
	progress "MS17-010"
	cloneRepository "https://github.com/helviojunior/MS17-010.git"
	_popd
}

Masky-tools() {
	progress "Masky"
	pipx install -f "git+https://github.com/Z4kSec/Masky"
}

Max() {
	_pushd tools
	progress "Max"
	cloneRepository "https://github.com/knavesec/Max.git"
	cd Max
	python3 -m pip install -U -r requirements.txt
	_popd
}

MeterPwrShell() {
	_pushd tools
	progress "MeterPwrShell"
	mkdir MeterPwrShell
	cd MeterPwrShell
	downloadRawFile "https://github.com/GetRektBoy724/MeterPwrShell/releases/download/v2.0.0/MeterPwrShell2Kalix64" MeterPwrShell2Kalix64
	chmod +x MeterPwrShell2Kalix64
	_popd
}

Neo-reGeorg() {
	_pushd tools
	progress "Neo-reGeorg"
	cloneRepository "https://github.com/L-codes/Neo-reGeorg.git"
	python2 -m pip install -U requests
	_popd
}

Nim() {
	progress "Nim"
	installDebPackage "mingw-w64" # "nim"
	curl "https://nim-lang.org/choosenim/init.sh" -sSf | CHOOSENIM_NO_ANALYTICS=1 sh
}

Nimcrypt2() {
	_pushd tools
	progress "Nimcrypt2"
	cloneRepository "https://github.com/icyguider/Nimcrypt2.git"
	cd Nimcrypt2
	installDebPackage "gcc mingw-w64 xz-utils git"
	nimble install winim nimcrypto docopt ptr_math strenc -y
	_popd
}

NimlineWhispers() {
	_pushd tools
	progress "NimlineWhispers"
	cloneRepository "https://github.com/snovvcrash/NimlineWhispers.git"
	_popd
}

Obsidian() {
	progress "Obsidian"
	downloadRelease "obsidianmd/obsidian-releases" obsidian.*amd64.snap /tmp/obsidian.snap
	installSnapPackage /tmp/obsidian.snap
	rm /tmp/obsidian.snap
	cp /var/lib/snapd/desktop/applications/obsidian_obsidian.desktop ~/Desktop/obsidian_obsidian.desktop
}

PCredz() {
	progress "PCredz"
	if [[ "$use_docker" ]]; then
		docker pull snovvcrash/pcredz
	else
		_pushd tools
		installDebPackage "libpcap-dev"
		cloneRepository "https://github.com/lgandx/PCredz.git"
		python3 -m pip install -U Cython
		python3 -m pip install -U python-libpcap
		_popd
	fi
}

PEzor() {
	_pushd tools
	progress "PEzor"
	cloneRepository "https://github.com/phra/PEzor.git"
	cd PEzor
	sudo bash install.sh
	#sudo cat /root/.bashrc | grep PEzor
	_popd
}

PKINITtools() {
	_pushd tools
	progress "PKINITtools"
	cloneRepository "https://github.com/dirkjanm/PKINITtools.git"
	python3 -m pip install -U minikerberos
	cd PKINITtools
	chmod +x getnthash.py gets4uticket.py gettgtpkinit.py
	_popd
}

PetitPotam() {
	_pushd tools
	progress "PetitPotam"
	cloneRepository "https://github.com/topotam/PetitPotam.git"
	_popd
}

PetitPotam-Ext() {
	_pushd tools
	progress "PetitPotam-Ext"
	cloneRepository "https://github.com/ly4k/PetitPotam.git" PetitPotam-Ext
	_popd
}

Physmem2profit-tools() {
	_pushd tools
	progress "Physmem2profit"
	cloneRepository "https://github.com/snovvcrash/Physmem2profit.git"
	cd Physmem2profit/client
	sed -i 's/acora==2.1/acora/g' rekall/rekall-core/setup.py
	sed -i 's/pycryptodome==3.4.7/pycryptodome/g' rekall/rekall-core/setup.py
	bash install.sh
	_popd
}

PoshC2() {
	progress "PoshC2"
	#curl -sSL "https://github.com/nettitude/PoshC2/raw/dev/Install.sh" | sudo bash -s -- -p /opt/PoshC2 -b dev
	installDebPackage "poshc2"
}

PrivExchange() {
	_pushd tools
	progress "PrivExchange"
	cloneRepository "https://github.com/dirkjanm/PrivExchange.git"
	_popd
}

Responder() {
	_pushd tools
	progress "Responder"
	cloneRepository "https://github.com/lgandx/Responder.git"
	cd Responder
	sed -i 's/Challenge = Random/Challenge = 1122334455667788/g' Responder.conf
	_popd
}

RustScan() {
	progress "RustScan"
	eget -t 2.0.1 -a amd64 "RustScan/RustScan" --to /tmp/rustscan.deb
	sudo dpkg -i /tmp/rustscan.deb
	rm /tmp/rustscan.deb
	sudo wget https://gist.github.com/snovvcrash/8b85b900bd928493cd1ae33b2df318d8/raw/fe8628396616c4bf7a3e25f2c9d1acc2f36af0c0/rustscan-ports-top1000.toml -O /root/.rustscan.toml
}

SCShell() {
	_pushd tools
	progress "SCShell"
	cloneRepository "https://github.com/Mr-Un1k0d3r/SCShell.git"
	_popd
}

ScareCrow() {
	_pushd tools
	progress "ScareCrow"
	mkdir ScareCrow
	cd ScareCrow
	downloadRelease "optiv/ScareCrow" ScareCrow.*linux_amd64 ScareCrow
	chmod +x ScareCrow
	_popd
}

ShadowCoerce() {
	_pushd tools
	progress "ShadowCoerce"
	cloneRepository "https://github.com/ShutdownRepo/ShadowCoerce.git"
	_popd
}

SharpGen() {
	_pushd tools
	progress "SharpGen"
	cloneRepository "https://github.com/cobbr/SharpGen.git"
	_popd
}

ShellPop() {
	_pushd tools
	progress "ShellPop"
	cloneRepository "https://github.com/0x00-0x00/ShellPop.git"
	cd ShellPop
	python2 -m pip install -U -r requirements.txt
	sudo python2 setup.py install
	_popd
}

Shhhloader() {
	_pushd tools
	progress "Shhhloader"
	cloneRepository "https://github.com/icyguider/Shhhloader.git"
	cd Shhhloader
	python3 randomize_sw2_seed.py
	_popd
}

Sliver() {
	progress "Sliver"
	curl "https://sliver.sh/install" | sudo bash
}

TrustVisualizer() {
	_pushd tools
	progress "TrustVisualizer"
	cloneRepository "https://github.com/snovvcrash/TrustVisualizer.git"
	cd TrustVisualizer
	python3 -m pip install -U -r requirements.txt
	_popd
}

WebclientServiceScanner() {
	progress "WebclientServiceScanner"
	pipx install -f "git+https://github.com/Hackndo/WebclientServiceScanner.git"
}

Windows-Exploit-Suggester() {
	_pushd tools
	progress "Windows-Exploit-Suggester"
	cloneRepository "https://github.com/a1ext/Windows-Exploit-Suggester.git"
	cd Windows-Exploit-Suggester
	python3 -m pip install -U -r requirements.txt
	_popd
}

ZeroTier() {
	progress "ZeroTier"
	curl -s "https://install.zerotier.com" | sudo bash
}

aced() {
	_pushd tools
	progress "aced"
	cloneRepository "https://github.com/garrettfoster13/aced.git"
	cd aced
	python3 -m pip install -U -r requirements.txt
	_popd
}

ack3() {
	_pushd tools
	progress "ack3"
	cloneRepository "https://github.com/beyondgrep/ack3.git"
	cd ack3
	echo yes | sudo perl -MCPAN -e 'install File::Next'
	perl Makefile.PL
	make
	make test
	sudo make install
	_popd
}

aclpwn.py() {
	progress "aclpwn.py"
	pipx install -f "git+https://github.com/fox-it/aclpwn.py.git"
}

adidnsdump() {
	progress "adidnsdump"
	pipx install -f "git+https://github.com/dirkjanm/adidnsdump.git"
}

aquatone() {
	_pushd tools
	progress "aquatone"
	mkdir aquatone
	cd aquatone
	downloadRelease "michenriksen/aquatone" aquatone_linux_amd64.*.zip aquatone.zip
	unzip -q aquatone.zip
	rm LICENSE.txt aquatone.zip
	chmod +x aquatone
	_popd
}

arsenal() {
	_pushd tools
	progress "arsenal"
	cloneRepository "https://github.com/Orange-Cyberdefense/arsenal.git"
	cd arsenal
	python3 -m pip install -U -r requirements.txt
	chmod +x run
	_popd
}

bettercap() {
	_pushd tools
	progress "bettercap"
	installDebPackage "libpcap-dev libusb-1.0-0-dev libnetfilter-queue-dev"
	mkdir bettercap
	cd bettercap
	eget -t v2.31.1 -qs linux/amd64 "bettercap/bettercap"
	sudo ./bettercap -eval "caplets.update; ui.update; q"
	downloadRawFile "https://github.com/penetrarnya-tm/WeaponizeKali.sh/raw/main/cap/arpspoof.cap" arpspoof.cap
	downloadRawFile "https://github.com/penetrarnya-tm/WeaponizeKali.sh/raw/main/cap/wsus.cap" wsus.cap
	_popd
}

bloodhound-import() {
	progress "bloodhound-import"
	pipx install -f "git+https://github.com/fox-it/bloodhound-import.git"
}

bloodhound-quickwin() {
	_pushd tools
	progress "bloodhound-quickwin"
	cloneRepository "https://github.com/kaluche/bloodhound-quickwin.git"
	cd bloodhound-quickwin
	python3 -m pip install -U -r requirements.txt
	_popd
}

bloodyAD() {
	_pushd tools
	progress "bloodyAD"
	cloneRepository "https://github.com/CravateRouge/bloodyAD.git"
	cd bloodyAD
	python3 -m pip install -U -r requirements.txt
	_popd
}

certi() {
	progress "certi"
	pipx install -f "git+https://github.com/zer1t0/certi.git"
}

chisel-server() {
	_pushd tools
	progress "chisel"
	mkdir chisel
	cd chisel
	downloadRelease "jpillora/chisel" chisel.*linux_amd64.gz chisel.gz
	gunzip chisel.gz
	chmod +x chisel
	_popd
}

crowbar() {
	progress "crowbar"
	pipx install -f "git+https://github.com/galkan/crowbar.git"
}

dementor.py() {
	_pushd tools
	progress "dementor.py"
	cloneRepository "https://gist.github.com/3xocyte/cfaf8a34f76569a8251bde65fe69dccc.git" dementor
	cd dementor
	chmod +x dementor.py
	_popd
}

dnsx() {
	_pushd tools
	progress "dnsx"
	mkdir dnsx
	eget -qs linux/amd64 "projectdiscovery/dnsx" --to dnsx
	_popd
}

donut() {
	_pushd tools
	progress "donut"
	cloneRepository "https://github.com/S4ntiagoP/donut.git"
	cd donut
	git checkout syscalls
	make
	installDebPackage "mono-devel"
	_popd
}

dsniff() {
	progress "dsniff"
	#sudo sysctl -w net.ipv4.ip_forward=1
	sudo sh -c 'echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf'
	installDebPackage "dsniff"
}

eavesarp() {
	_pushd tools
	progress "eavesarp"
	cloneRepository "https://github.com/arch4ngel/eavesarp.git"
	cd eavesarp
	sudo python3 -m pip install -U -r requirements.txt
	_popd
}

enum4linux-ng() {
	progress "enum4linux-ng"
	pipx install -f "git+https://github.com/cddmp/enum4linux-ng.git"
}

evil-winrm() {
	_pushd tools
	progress "evil-winrm"
	downloadRawFile "https://github.com/penetrarnya-tm/WeaponizeKali.sh/raw/main/misc/evil-winrm.sh" evil-winrm.sh
	chmod +x evil-winrm.sh
	_popd
}

feroxbuster() {
	_pushd tools
	progress "feroxbuster"
	mkdir feroxbuster
	cd feroxbuster
	downloadRelease "epi052/feroxbuster" x86_64-linux-feroxbuster.zip feroxbuster.zip
	unzip -q feroxbuster.zip
	rm feroxbuster.zip
	chmod +x feroxbuster
	_popd
}

ffuf() {
	progress "ffuf"
	installDebPackage "ffuf"
}

gMSADumper() {
	_pushd tools
	progress "gMSADumper"
	cloneRepository "https://github.com/micahvandeusen/gMSADumper.git"
	_popd
}

gateway-finder-imp() {
	_pushd tools
	progress "gateway-finder-imp"
	cloneRepository "https://github.com/whitel1st/gateway-finder-imp.git"
	cd gateway-finder-imp
	python3 -m pip install -U -r requirements.txt
	_popd
}

go-windapsearch() {
	_pushd tools
	progress "go-windapsearch"
	mkdir go-windapsearch
	cd go-windapsearch
	downloadRawFile "https://github.com/penetrarnya-tm/WeaponizeKali.sh/raw/main/elf/windapsearch" windapsearch
	chmod +x windapsearch
	_popd
}

gobuster() {
	progress "gobuster"
	installDebPackage "gobuster"
}

hashcat-utils() {
	_pushd tools
	progress "hashcat-utils"
	cloneRepository "https://github.com/hashcat/hashcat-utils.git"
	cd hashcat-utils/src
	make
	_popd
}

hoaxshell() {
	_pushd tools
	progress "hoaxshell"
	cloneRepository "https://github.com/t3l3machus/hoaxshell.git"
	cd hoaxshell
	python3 -m pip install -U -r requirements.txt
	_popd
}

http-server() {
	progress "http-server"
	sudo npm install -g http-server
}

httpx() {
	_pushd tools
	progress "httpx"
	mkdir httpx
	eget -qs linux/amd64 "projectdiscovery/httpx" --to httpx
	_popd
}

impacket() {
	progress "impacket"
	pipx install -f "git+https://github.com/SecureAuthCorp/impacket.git"
	_pushd tools
	progress "impacket-src"
	cloneRepository "https://github.com/SecureAuthCorp/impacket.git"
	progress "impacket-ShutdownRepo"
	cloneRepository "https://github.com/ShutdownRepo/impacket.git" impacket-ShutdownRepo
	progress "impacket-snovvcrash"
	cloneRepository "https://github.com/snovvcrash/impacket.git" impacket-snovvcrash
	_popd
}

iCULeak.py() {
	_pushd tools
	progress "iCULeak.py"
	cloneRepository "https://github.com/llt4l/iCULeak.py.git"
	cd iCULeak.py
	python3 -m pip install .
	chmod +x iCULeak.py
	_popd
}

ipmitool() {
	progress "ipmitool"
	installDebPackage "ipmitool"
}

kerbrute() {
	_pushd tools
	progress "kerbrute"
	mkdir kerbrute
	cd kerbrute
	downloadRelease "ropnop/kerbrute" kerbrute_linux_amd64 kerbrute
	chmod +x kerbrute
	_popd
}

krbrelayx() {
	_pushd tools
	progress "krbrelayx"
	cloneRepository "https://github.com/dirkjanm/krbrelayx.git"
	cd krbrelayx
	chmod +x addspn.py dnstool.py printerbug.py
	_popd
}

ldap_shell() {
	_pushd tools
	progress "ldap_shell"
	cloneRepository "https://github.com/PShlyundin/ldap_shell.git"
	cd ldap_shell
	python3 -m pip install .
	_popd
}

ldapdomaindump() {
	_pushd tools
	progress "ldapdomaindump"
	cloneRepository "https://github.com/dirkjanm/ldapdomaindump.git"
	cd ldapdomaindump
	python2 -m pip install -U ldap3 dnspython
	sudo python2 setup.py install
	_popd
}

ldapsearch-ad() {
	_pushd tools
	progress "ldapsearch-ad"
	cloneRepository "https://github.com/yaap7/ldapsearch-ad.git"
	cd ldapsearch-ad
	python3 -m pip install -U -r requirements.txt
	_popd
}

ldeep() {
	progress "ldeep"
	pipx install -f "git+https://github.com/franc-pentest/ldeep.git"
}

ligolo-ng-proxy() {
	_pushd tools
	progress "ligolo-ng"
	mkdir ligolo-ng
	cd ligolo-ng
	downloadRelease "tnpitsecurity/ligolo-ng" ligolo-ng_proxy.*Linux_64bit.tar.gz ligolo-proxy.tar.gz
	tar -xzf ligolo-proxy.tar.gz
	rm LICENSE ligolo-proxy.tar.gz
	_popd
}

lsassy() {
	progress "lsassy"
	pipx install -f "git+https://github.com/Hackndo/lsassy.git"
}

mapcidr() {
	_pushd tools
	progress "mapcidr"
	mkdir mapcidr
	eget -qs linux/amd64 "projectdiscovery/mapcidr" --to mapcidr
	_popd
}

masscan() {
	_pushd tools
	progress "masscan"
	cloneRepository "https://github.com/robertdavidgraham/masscan.git"
	cd masscan
	make
	sudo make install
	_popd
}

mitm6() {
	progress "mitm6"
	pipx install -f "git+https://github.com/fox-it/mitm6.git"
}

mscache() {
	_pushd tools
	progress "mscache"
	cloneRepository "https://github.com/QAX-A-Team/mscache.git"
	python2 -m pip install -U passlib
	_popd
}

nac_bypass() {
	_pushd tools
	progress "nac_bypass"
	cloneRepository "https://github.com/snovvcrash/nac_bypass.git"
	installDebPackage "bridge-utils arptables ebtables"
	sudo sh -c 'echo "br_netfilter" >> /etc/modules'
	_popd
}

nanodump-tools() {
	_pushd tools
	progress "nanodump-tools"
	cloneRepository "https://github.com/helpsystems/nanodump.git"
	_popd
}

nextnet() {
	_pushd tools
	progress "nextnet"
	mkdir nextnet
	cd nextnet
	downloadRelease "hdm/nextnet" nextnet.*linux_amd64.tar.gz nextnet.tar.gz
	tar -xzf nextnet.tar.gz
	rm LICENSE nextnet.tar.gz
	_popd
}

nishang() {
	_pushd tools
	progress "nishang"
	cloneRepository "https://github.com/samratashok/nishang.git"
	_popd
}

noPac() {
	_pushd tools
	progress "noPac"
	cloneRepository "https://github.com/Ridter/noPac.git"
	_popd
}

ntlm-scanner() {
	_pushd tools
	progress "ntlm-scanner"
	cloneRepository "https://github.com/preempt/ntlm-scanner.git"
	_popd
}

ntlmv1-multi() {
	_pushd tools
	progress "ntlmv1-multi"
	cloneRepository "https://github.com/evilmog/ntlmv1-multi.git"
	_popd
}

nullinux() {
	_pushd tools
	progress "nullinux"
	cloneRepository "https://github.com/m8r0wn/nullinux.git"
	cd nullinux
	sudo bash setup.sh
	_popd
}

odat() {
	_pushd tools
	progress "odat"
	mkdir odat
	cd odat
	downloadRelease "quentinhardy/odat" odat-linux.*.tar.gz odat.tar.gz
	tar -xzf odat.tar.gz
	rm odat.tar.gz
	mv odat-* odat-dir
	mv odat-dir/* .
	rm -rf odat-dir
	_popd
}

paperify() {
	_pushd tools
	progress "paperify"
	cloneRepository "https://github.com/alisinabh/paperify.git"
	installDebPackage "qrencode imagemagick"
	cd paperify
	chmod +x paperify.sh
	_popd
}

payloadGenerator() {
	_pushd tools
	progress "payloadGenerator"
	cloneRepository "https://github.com/smokeme/payloadGenerator.git"
	_popd
}

powerview.py() {
	_pushd tools
	progress "powerview.py"
	cloneRepository "https://github.com/aniqfakhrul/powerview.py.git"
	cd powerview.py
	python3 -m pip install -U -r requirements.txt
	_popd
}

pretender-tools() {
	_pushd tools
	progress "pretender"
	mkdir pretender
	eget -qs linux/amd64 "RedTeamPentesting/pretender" --to pretender
	_popd
}

py() {
	FUNC=$(declare -f downloadRawFile)

	sudo bash -c "$FUNC; downloadRawFile 'https://github.com/penetrarnya-tm/WeaponizeKali.sh/raw/main/py/bin_to_pwsh.py' /usr/local/bin/bin_to_pwsh.py"
	sudo chmod +x /usr/local/bin/bin_to_pwsh.py

	sudo bash -c "$FUNC; downloadRawFile 'https://github.com/penetrarnya-tm/WeaponizeKali.sh/raw/main/py/bh_get_ad_group_member.py' /usr/local/bin/bh_get_ad_group_member.py"
	sudo chmod +x /usr/local/bin/bh_get_ad_group_member.py

	sudo bash -c "$FUNC; downloadRawFile 'https://github.com/penetrarnya-tm/WeaponizeKali.sh/raw/main/py/bh_get_ad_user_memberof.py' /usr/local/bin/bh_get_ad_user_memberof.py"
	sudo chmod +x /usr/local/bin/bh_get_ad_user_memberof.py

	sudo bash -c "$FUNC; downloadRawFile 'https://github.com/penetrarnya-tm/WeaponizeKali.sh/raw/main/py/bh_get_domain_trust_mapping.py' /usr/local/bin/bh_get_domain_trust_mapping.py"
	sudo chmod +x /usr/local/bin/bh_get_domain_trust_mapping.py

	sudo bash -c "$FUNC; downloadRawFile 'https://github.com/penetrarnya-tm/WeaponizeKali.sh/raw/main/py/bloodhound-print.py' /usr/local/bin/bloodhound-print.py"
	sudo chmod +x /usr/local/bin/bloodhound-print.py

	sudo bash -c "$FUNC; downloadRawFile 'https://github.com/penetrarnya-tm/WeaponizeKali.sh/raw/main/py/parse_esc1.py' /usr/local/bin/parse_esc1.py"
	sudo chmod +x /usr/local/bin/parse_esc1.py

	sudo bash -c "$FUNC; downloadRawFile 'https://github.com/penetrarnya-tm/WeaponizeKali.sh/raw/main/py/cred_stasher.py' /usr/local/bin/cred_stasher.py"
	sudo chmod +x /usr/local/bin/cred_stasher.py
}

pywsus() {
	_pushd tools
	progress "pywsus"
	cloneRepository "https://github.com/GoSecure/pywsus.git"
	cd pywsus
	python3 -m pip install -U -r requirements.txt
	_popd
}

pyGPOAbuse() {
	_pushd tools
	progress "pyGPOAbuse"
	cloneRepository "https://github.com/Hackndo/pyGPOAbuse.git"
	cd pyGPOAbuse
	python3 -m pip install -U -r requirements.txt
	python3 -m pip install -U aiosmb
	_popd
}

pyKerbrute() {
	_pushd tools
	progress "pyKerbrute"
	cloneRepository "https://github.com/3gstudent/pyKerbrute.git"
	cd pyKerbrute
	git checkout 1908a02
	_popd
}

pypykatz() {
	progress "pypykatz"
	pipx install -f "git+https://github.com/skelsec/pypykatz.git"
}

pywerview() {
	_pushd tools
	progress "pywerview"
	cloneRepository "https://github.com/the-useless-one/pywerview.git"
	cd pywerview
	installDebPackage "libkrb5-dev"
	python3 -m pip install -U -r requirements.txt
	_popd
}

pywhisker() {
	_pushd tools
	progress "pywhisker"
	cloneRepository "https://github.com/ShutdownRepo/pywhisker.git"
	cd pywhisker
	python3 -m pip install -U -r requirements.txt
	_popd
}

rbcd-attack() {
	_pushd tools
	progress "rbcd-attack"
	cloneRepository "https://github.com/tothi/rbcd-attack.git"
	_popd
}

rbcd_permissions() {
	_pushd tools
	progress "rbcd_permissions"
	cloneRepository "https://github.com/NinjaStyle82/rbcd_permissions.git"
	_popd
}

rdp-tunnel-tools() {
	_pushd tools
	progress "rdp-tunnel-tools"
	cloneRepository "https://github.com/NotMedic/rdp-tunnel.git"
	_popd
}

revsocks-server() {
	_pushd tools
	progress "revsocks"
	mkdir revsocks
	eget -qs linux/amd64 "kost/revsocks" --to revsocks
	_popd
}

rtfm() {
	_pushd tools
	progress "rtfm"
	cloneRepository "https://github.com/leostat/rtfm.git"
	cd rtfm
	./rtfm -u 2>/dev/null
	echo 'function rtfm() { ~/tools/rtfm/rtfm.py "$@" 2>/dev/null }' >> ~/.zshrc
	_popd
}

sRDI() {
	_pushd tools
	progress "sRDI"
	cloneRepository "https://github.com/monoxgas/sRDI.git"
	_popd
}

seclists() {
	progress "seclists"
	installDebPackage "seclists"
}

sgn() {
	_pushd tools
	progress "sgn"
	mkdir sgn
	cd sgn
	downloadRelease "EgeBalci/sgn" sgn_linux_amd64.*.zip sgn.zip
	unzip -q sgn.zip
	mv sgn_*/sgn .
	rm -rf sgn.zip sgn_*
	chmod +x sgn
	_popd
}

smartbrute() {
	_pushd tools
	progress "smartbrute"
	cloneRepository "https://github.com/ShutdownRepo/smartbrute.git"
	cd smartbrute
	rm -rf assets memes
	python3 -m pip install .
	_popd
}

snmpwn() {
	_pushd tools
	progress "snmpwn"
	cloneRepository "https://github.com/hatlord/snmpwn.git"
	cd snmpwn
	bundle install --path ~/.gem
	_popd
}

spraykatz() {
	_pushd tools
	progress "spraykatz"
	cloneRepository "https://github.com/aas-n/spraykatz.git"
	cd spraykatz
	python3 -m pip install -U -r requirements.txt
	_popd
}

ssb() {
	_pushd tools
	progress "ssb"
	mkdir ssb
	cd ssb
	downloadRelease "kitabisa/ssb" ssb.*amd64.tar.gz ssb.tar.gz
	tar -xzf ssb.tar.gz
	rm LICENSE.md ssb.tar.gz
	_popd
}

sshspray() {
	_pushd tools
	cloneRepository "https://github.com/mcorybillington/sshspray.git"
	cd sshspray
	echo '#!/usr/bin/env python3\n' | cat - sshspray.py > t
	mv t sshspray.py
	chmod +x sshspray.py
	_popd
}

sshuttle() {
	progress "sshuttle"
	installDebPackage "sshpass sshuttle"
}

targetedKerberoast() {
	_pushd tools
	progress "targetedKerberoast"
	cloneRepository "https://github.com/ShutdownRepo/targetedKerberoast.git"
	cd targetedKerberoast
	python3 -m pip install -U -r requirements.txt
	_popd
}

ticket_converter() {
	_pushd tools
	progress "ticket_converter"
	cloneRepository "https://github.com/eloypgz/ticket_converter.git"
	cd ticket_converter
	python2 -m pip install -U -r requirements.txt
	_popd
}

traitor() {
	_pushd tools
	progress "traitor"
	mkdir traitor
	cd traitor
	downloadRelease "liamg/traitor" traitor.*amd64 traitor
	chmod +x traitor
	_popd
}

transfer.sh() {
	_pushd tools
	progress "transfer.sh"
	mkdir transfersh
	cd transfersh
	downloadRelease "dutchcoders/transfer.sh" transfersh.*-linux-amd64 transfer.sh
	chmod +x transfer.sh
	_popd
}

updog() {
	progress "updog"
	pipx install -f "git+https://github.com/sc0tfree/updog.git"
}

webpage2html() {
	_pushd tools
	progress "webpage2html"
	cloneRepository "https://github.com/snovvcrash/webpage2html.git"
	cd webpage2html
	python2 -m pip install -U -r requirements.txt
	_popd
}

wesng() {
	_pushd tools
	progress "wesng"
	cloneRepository "https://github.com/bitsadmin/wesng.git"
	cd wesng
	python3 wes.py --update
	_popd
}

windapsearch() {
	_pushd tools
	progress "windapsearch"
	installDebPackage "libsasl2-dev libldap2-dev libssl-dev"
	cloneRepository "https://github.com/ropnop/windapsearch.git"
	cd windapsearch
	python3 -m pip install -U -r requirements.txt
	_popd
}

wmiexec-RegOut() {
	_pushd tools
	progress "wmiexec-RegOut"
	cloneRepository "https://github.com/XiaoliChan/wmiexec-RegOut.git"
	_popd
}

xc() {
	_pushd tools
	progress "xc"
	cloneRepository "https://github.com/xct/xc.git"
	cd xc
	GO111MODULE=off go get golang.org/x/sys/...
	GO111MODULE=off go get golang.org/x/text/encoding/unicode
	GO111MODULE=off go get github.com/hashicorp/yamux
	installDebPackage "rlwrap upx"
	python3 build.py
	chmod -x xc xc.exe
	cp xc xc.exe ../../www
	_popd
}

yersina() {
	progress "yersina"
	installDebPackage "yersina"
}

tools() {
	APIHashReplace
	AutoBlue-MS17-010
	BloodHound
	BloodHound.py
	Certipy
	CVE-2019-1040-scanner
	CVE-2020-1472-checker
	CVE-2021-1675
	Coercer
	Covenant
	CrackMapExec
	DFSCoerce
	DInjector
	DLLsForHackers
	DivideAndScan
	DonPAPI
	Ebowla
	Empire
	InvisibilityCloak
	ItWasAllADream
	LDAPPER
	LDAPmonitor
	LdapRelayScan
	LightMe
	MS17-010
	#MANSPIDER
	Masky-tools
	Max
	MeterPwrShell
	Nim
	Nimcrypt2
	NimlineWhispers
	Obsidian
	PCredz
	PEzor
	PKINITtools
	PetitPotam
	PetitPotam-Ext
	Physmem2profit-tools
	PoshC2
	PrivExchange
	Responder
	RustScan
	SCShell
	ScareCrow
	ShadowCoerce
	SharpGen
	ShellPop
	WebclientServiceScanner
	Shhhloader
	Sliver
	TrustVisualizer
	Windows-Exploit-Suggester
	#ZeroTier
	aced
	#ack3
	aclpwn.py
	adidnsdump
	aquatone
	arsenal
	bettercap
	bloodhound-import
	bloodhound-quickwin
	bloodyAD
	certi
	chisel-server
	crowbar
	dementor.py
	dnsx
	donut
	dsniff
	eavesarp
	enum4linux-ng
	evil-winrm
	feroxbuster
	ffuf
	gMSADumper
	gateway-finder-imp
	gitjacker
	go-windapsearch
	gobuster
	hashcat-utils
	hoaxshell
	http-server
	httpx
	impacket
	ipmitool
	iCULeak.py
	kerbrute
	krbrelayx
	ldap_shell
	ldapdomaindump
	ldapsearch-ad
	ldeep
	ligolo-ng-proxy
	lsassy
	mapcidr
	masscan
	mitm6
	mscache
	nac_bypass
	nanodump-tools
	nextnet
	nishang
	noPac
	ntlm-scanner
	ntlmv1-multi
	nullinux
	odat
	paperify
	payloadGenerator
	powerview.py
	pretender-tools
	py
	pywsus
	pyGPOAbuse
	pyKerbrute
	pypykatz
	pywerview
	pywhisker
	rbcd-attack
	rbcd_permissions
	rdp-tunnel-tools
	revsocks-server
	rtfm
	sRDI
	seclists
	sgn
	smartbrute
	snmpwn
	spraykatz
	ssb
	sshspray
	sshuttle
	targetedKerberoast
	ticket_converter
	traitor
	transfer.sh
	updog
	webpage2html
	wesng
	windapsearch
	wmiexec-RegOut
	#xc
	yersina
}

# -----------------------------------------------------------------------------
# ------------------------------------ www ------------------------------------
# -----------------------------------------------------------------------------

exe() {
	_pushd www
	downloadRawFile "https://github.com/penetrarnya-tm/WeaponizeKali.sh/raw/main/exe/SandboxDefender.exe" sandboxdefender.exe
	downloadRawFile "https://github.com/penetrarnya-tm/WeaponizeKali.sh/raw/main/exe/SharpStrike.exe" sharpstrike.exe
	downloadRawFile "https://github.com/penetrarnya-tm/WeaponizeKali.sh/raw/main/exe/SharpStrikeGUI.exe" sharpstrikegui.exe
	_popd
}

ps1() {
	_pushd www
	downloadRawFile "https://github.com/penetrarnya-tm/WeaponizeKali.sh/raw/main/ps1/Invoke-ADCSPwn.ps1" invoke-adcspwn.ps1
	downloadRawFile "https://github.com/penetrarnya-tm/WeaponizeKali.sh/raw/main/ps1/Invoke-KeeTheftSyscalls.ps1" invoke-keetheftsyscalls.ps1
	downloadRawFile "https://github.com/penetrarnya-tm/WeaponizeKali.sh/raw/main/ps1/Invoke-Masky.ps1" invoke-masky.ps1
	downloadRawFile "https://github.com/penetrarnya-tm/WeaponizeKali.sh/raw/main/ps1/Invoke-MirrorDump.ps1" invoke-mirrordump.ps1
	downloadRawFile "https://github.com/penetrarnya-tm/WeaponizeKali.sh/raw/main/ps1/Invoke-Physmem2profit.ps1" invoke-physmem2profit.ps1
	downloadRawFile "https://github.com/penetrarnya-tm/WeaponizeKali.sh/raw/main/ps1/Invoke-RestrictedAdmin.ps1" invoke-restrictedadmin.ps1
	downloadRawFile "https://github.com/penetrarnya-tm/WeaponizeKali.sh/raw/main/ps1/Invoke-RunOF.ps1" invoke-runof.ps1
	downloadRawFile "https://github.com/penetrarnya-tm/WeaponizeKali.sh/raw/main/ps1/Invoke-SharpDcomTrigger.ps1" invoke-sharpdcomtrigger.ps1
	downloadRawFile "https://github.com/penetrarnya-tm/WeaponizeKali.sh/raw/main/ps1/Invoke-SharpEfsTrigger.ps1" invoke-sharpefstrigger.ps1
	downloadRawFile "https://github.com/penetrarnya-tm/WeaponizeKali.sh/raw/main/ps1/Invoke-SharpRdpThiefInjector.ps1" invoke-sharprdpthiefinjector.ps1
	downloadRawFile "https://github.com/penetrarnya-tm/WeaponizeKali.sh/raw/main/ps1/Invoke-SharpSCCM.ps1" invoke-sharpsccm.ps1
	downloadRawFile "https://github.com/penetrarnya-tm/WeaponizeKali.sh/raw/main/ps1/Invoke-SharpSpoolTrigger.ps1" invoke-sharpspooltrigger.ps1
	downloadRawFile "https://github.com/penetrarnya-tm/WeaponizeKali.sh/raw/main/ps1/Invoke-TokenDuplicator.ps1" invoke-tokenduplicator.ps1
	downloadRawFile "https://github.com/penetrarnya-tm/WeaponizeKali.sh/raw/main/ps1/Invoke-VeraCryptThiefInjector.ps1" invoke-veracryptthiefinjector.ps1
	_popd
}

sys() {
	_pushd www
	downloadRawFile "https://github.com/penetrarnya-tm/WeaponizeKali.sh/raw/main/sys/WinDivert64.sys" windivert64.sys
	_popd
}

ADRecon() {
	_pushd www
	downloadRawFile "https://github.com/adrecon/ADRecon/raw/master/ADRecon.ps1" adrecon.ps1
	_popd
}

ADSearch() {
	_pushd www
	downloadRawFile "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_Any/ADSearch.exe" adsearch.exe
	_popd
}

ASREPRoast() {
	_pushd www
	downloadRawFile "https://github.com/HarmJ0y/ASREPRoast/raw/master/ASREPRoast.ps1" asreproast.ps1
	_popd
}

AccessChk() {
	_pushd www
	downloadRawFile "https://xor.cat/assets/other/Accesschk.zip" accesschk-accepteula.zip
	unzip -q accesschk-accepteula.zip
	mv accesschk.exe accesschk-accepteula.exe
	rm Eula.txt accesschk-accepteula.zip
	downloadRawFile "https://download.sysinternals.com/files/AccessChk.zip" accesschk.zip
	unzip -q accesschk.zip
	rm Eula.txt accesschk64a.exe accesschk.zip
	_popd
}

Amsi-Bypass-Powershell() {
	_pushd www
	cloneRepository "https://github.com/S3cur3Th1sSh1t/Amsi-Bypass-Powershell.git"
	_popd
}

Certify() {
	_pushd www
	downloadRawFile "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.0_Any/Certify.exe" certify.exe
	_popd
}

DDexec() {
	_pushd www
	downloadRawFile "https://github.com/arget13/DDexec/raw/main/ddexec.sh" ddexec.sh
	_popd
}

DefenderStop() {
	_pushd www
	downloadRelease "dosxuz/DefenderStop" DefenderStop_x64.exe defenderstop.exe
	_popd
}

Discover-PSMSExchangeServers() {
	_pushd www
	downloadRawFile "https://github.com/PyroTek3/PowerShell-AD-Recon/raw/master/Discover-PSMSExchangeServers" discover-psmsexchangeservers.ps1
	_popd
}

Discover-PSMSSQLServers() {
	_pushd www
	downloadRawFile "https://github.com/PyroTek3/PowerShell-AD-Recon/raw/master/Discover-PSMSSQLServers" discover-psmssqlservers.ps1
	_popd
}

DomainPasswordSpray() {
	_pushd www
	downloadRawFile "https://github.com/dafthack/DomainPasswordSpray/raw/master/DomainPasswordSpray.ps1" domainpasswordspray.ps1
	_popd
}

Grouper2() {
	_pushd www
	downloadRelease "l0ss/Grouper2" Grouper2.exe grouper2.exe
	_popd
}

HandleKatz() {
	_pushd www
	cloneRepository "https://gist.github.com/S3cur3Th1sSh1t/9f328fc411ff103c0800294c523503e2.git" /tmp/Invoke-HandleKatzInject
	mv /tmp/Invoke-HandleKatzInject/Invoke-HandleKatzInject.ps1 invoke-handlekatzinject.ps1
	rm -rf /tmp/Invoke-HandleKatzInject
	_popd
}

HiveNightmare() {
	_pushd www
	downloadRelease "GossiTheDog/HiveNightmare" HiveNightmare.exe hivenightmare.exe
	downloadRawFile "https://github.com/FireFart/hivenightmare/raw/main/release/hive.exe" hive.exe
	cloneRepository "https://github.com/HuskyHacks/ShadowSteal.git"
	cd ShadowSteal
	nimble install zippy argparse winim -y
	make
	mv bin/ShadowSteal.exe ../shadowsteal.exe
	chmod -x ../shadowsteal.exe
	cd ..
	rm -rf ShadowSteal
	_popd
}

Intercepter-NG() {
	_pushd www
	downloadRawFile "http://sniff.su/Intercepter-NG.v1.1.zip" intercepter-ng.zip
	_popd
}

Inveigh() {
	_pushd www
	downloadRawFile "https://github.com/Kevin-Robertson/Inveigh/raw/master/Inveigh-Relay.ps1" inveigh-relay.ps1
	downloadRawFile "https://github.com/Kevin-Robertson/Inveigh/raw/master/Inveigh.ps1" inveigh.ps1
	downloadRawFile "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.0_Any/Inveigh.exe" inveigh.exe
	_popd
}

Invoke-ACLPwn() {
	_pushd www
	downloadRawFile "https://github.com/fox-it/Invoke-ACLPwn/raw/master/Invoke-ACLPwn.ps1" invoke-aclpwn.ps1
	_popd
}

Invoke-ConPtyShell() {
	_pushd www
	downloadRawFile "https://github.com/antonioCoco/ConPtyShell/raw/master/Invoke-ConPtyShell.ps1" invoke-conptyshell.ps1
	_popd
}

Invoke-ImpersonateUser-PTH() {
	_pushd www
	downloadRawFile "https://github.com/S3cur3Th1sSh1t/NamedPipePTH/raw/main/Invoke-ImpersonateUser-PTH.ps1" invoke-impersonateuser-pth.ps1
	_popd
}

Invoke-PSInject() {
	_pushd www
	downloadRawFile "https://github.com/EmpireProject/PSInject/raw/master/Invoke-PSInject.ps1" invoke-psinject.ps1
	_popd
}

Invoke-PatchWdigest() {
	_pushd www
	cloneRepository "https://gist.github.com/snovvcrash/43e976779efdd20df1596c6492198c99.git" /tmp/Invoke-PatchWdigestInject
	mv /tmp/Invoke-PatchWdigestInject/Invoke-PatchWdigestInject.ps1 invoke-patchwdigestinject.ps1
	rm -rf /tmp/Invoke-PatchWdigestInject
	_popd
}

Invoke-Portscan() {
	_pushd www
	downloadRawFile "https://github.com/PowerShellMafia/PowerSploit/raw/master/Recon/Invoke-Portscan.ps1" invoke-portscan.ps1
	_popd
}

Invoke-RunasCs() {
	_pushd www
	downloadRawFile "https://github.com/antonioCoco/RunasCs/raw/master/Invoke-RunasCs.ps1" invoke-runascs.ps1
	_popd
}

Invoke-SMBClient() {
	_pushd www
	downloadRawFile "https://github.com/Kevin-Robertson/Invoke-TheHash/raw/master/Invoke-SMBClient.ps1" invoke-smbclient.ps1
	_popd
}

Invoke-SMBEnum() {
	_pushd www
	downloadRawFile "https://github.com/Kevin-Robertson/Invoke-TheHash/raw/master/Invoke-SMBEnum.ps1" invoke-smbenum.ps1
	_popd
}

Invoke-SMBExec() {
	_pushd www
	downloadRawFile "https://github.com/Kevin-Robertson/Invoke-TheHash/raw/master/Invoke-SMBExec.ps1" invoke-smbexec.ps1
	_popd
}

Invoke-WMIExec() {
	_pushd www
	downloadRawFile "https://github.com/Kevin-Robertson/Invoke-TheHash/raw/master/Invoke-WMIExec.ps1" invoke-wmiexec.ps1
	_popd
}

Invoke-noPac() {
	_pushd www
	cloneRepository "https://gist.github.com/S3cur3Th1sSh1t/0ed2fb0b5ae485b68cbc50e89581baa6.git" /tmp/Invoke-noPac
	mv /tmp/Invoke-noPac/Invoke-noPac.ps1 invoke-nopac.ps1
	rm -rf /tmp/Invoke-noPac
	_popd
}

JAWS() {
	_pushd www
	downloadRawFile "https://github.com/411Hall/JAWS/raw/master/jaws-enum.ps1" jaws-enum.ps1
	_popd
}

JuicyPotato() {
	_pushd www
	downloadRelease "ohpe/juicy-potato" JuicyPotato.exe juicypotato64.exe
	downloadRelease "ivanitlearning/Juicy-Potato-x86" Juicy.Potato.x86.exe juicypotato32.exe
	_popd
}

KSC-Console() {
	_pushd www
	downloadRawFile "https://aes.s.kaspersky-labs.com/administrationkit/ksc10/13.2.0.1511/russian-7864598-ru/3439313231317c44454c7c31/ksc_13_13.2.0.1511_Console_ru.exe" ksc_console.exe
	_popd
}

KrbRelay() {
	_pushd www
	downloadRawFile "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_Any/KrbRelay.exe" krbrelay.exe
	_popd
}

KrbRelayUp() {
	_pushd www
	downloadRawFile "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_Any/KrbRelayUp.exe" krbrelayup.exe
	_popd
}

LaZagne() {
	_pushd www
	downloadRelease "AlessandroZ/LaZagne" lazagne.exe lazagne.exe
	_popd
}

OffensivePythonPipeline() {
	_pushd www
	cloneRepository "https://github.com/Qazeer/OffensivePythonPipeline.git"
	_popd
}

Out-EncryptedScript() {
	_pushd www
	downloadRawFile "https://github.com/PowerShellMafia/PowerSploit/raw/master/ScriptModification/Out-EncryptedScript.ps1" out-encryptedscript.ps1
	_popd
}

PEASS() {
	installDebPackage "peass"
}

PingCastle() {
	_pushd www
	downloadRelease "vletoux/pingcastle" PingCastle.*.zip pingcastle.zip
	_popd
}

PowerShellArmoury() {
	_pushd www
	downloadRawFile "https://github.com/cfalta/PowerShellArmoury/raw/master/New-PSArmoury.ps1" new-psarmoury.ps1
	downloadRawFile "https://github.com/penetrarnya-tm/WeaponizeKali.sh/raw/main/misc/PSArmoury.json" psarmoury.json
	_popd
}

PowerUp() {
	_pushd www
	downloadRawFile "https://github.com/PowerShellMafia/PowerSploit/raw/master/Privesc/PowerUp.ps1" powerup.ps1
	_popd
}

PowerUpSQL() {
	_pushd www
	downloadRawFile "https://github.com/NetSPI/PowerUpSQL/raw/master/PowerUpSQL.ps1" powerupsql.ps1
	_popd
}

PowerView2() {
	_pushd www
	downloadRawFile "https://github.com/PowerShellEmpire/PowerTools/raw/master/PowerView/powerview.ps1" powerview2.ps1
	_popd
}

PowerView3() {
	_pushd www
	downloadRawFile "https://github.com/PowerShellMafia/PowerSploit/raw/master/Recon/PowerView.ps1" powerview3.ps1
	_popd
}

PowerView3-GPO() {
	_pushd www
	downloadRawFile "https://github.com/PowerShellMafia/PowerSploit/raw/26a0757612e5654b4f792b012ab8f10f95d391c9/Recon/PowerView.ps1" powerview3-gpo.ps1
	_popd
}

PowerView4() {
	_pushd www
	downloadRawFile "https://github.com/ZeroDayLab/PowerSploit/raw/master/Recon/PowerView.ps1" powerview4.ps1
	_popd
}

Powermad() {
	_pushd www
	downloadRawFile "https://github.com/Kevin-Robertson/Powermad/raw/master/Powermad.ps1" powermad.ps1
	_popd
}

PrintSpoofer() {
	_pushd www
	downloadRelease "itm4n/PrintSpoofer" PrintSpoofer64.exe printspoofer64.exe
	_popd
}

PrivescCheck() {
	_pushd www
	downloadRawFile "https://github.com/itm4n/PrivescCheck/raw/master/PrivescCheck.ps1" privesccheck.ps1
	_popd
}

PSTools() {
	_pushd www
	downloadRawFile "https://download.sysinternals.com/files/PSTools.zip" pstools.zip
	unzip -q pstools.zip
	rm Eula.txt Pstools.chm psversion.txt pstools.zip
	_popd
}

PowerShx() {
	_pushd www
	eget -qs windows/amd64 "iomoath/PowerShx" --to powershx.exe
	_popd
}

ProcDump() {
	_pushd www
	downloadRawFile "https://download.sysinternals.com/files/Procdump.zip" procdump.zip
	unzip -q procdump.zip
	rm Eula.txt procdump64a.exe procdump.zip
	_popd
}

Python-2.7.18() {
	_pushd www
	downloadRawFile "https://www.python.org/ftp/python/2.7.18/python-2.7.18.amd64.msi" python-2.7.18.amd64.msi
	_popd
}

RawCopy() {
	_pushd www
	downloadRawFile "https://github.com/jschicht/RawCopy/raw/master/RawCopy64.exe" rawcopy64.exe
	_popd
}

RemotePotato0() {
	_pushd www
	downloadRelease "antonioCoco/RemotePotato0" RemotePotato0.zip remotepotato0.zip
	unzip -q remotepotato0.zip
	rm remotepotato0.zip
	_popd
}

RoguePotato() {
	_pushd www
	downloadRelease "antonioCoco/RoguePotato" RoguePotato.zip roguepotato.zip
	unzip -q roguepotato.zip
	rm roguepotato.zip
	_popd
}

Rubeus() {
	_pushd www
	downloadRawFile "https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/raw/master/Rubeus.exe" rubeus.exe
	_popd
}

Seatbelt() {
	_pushd www
	downloadRawFile "https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/raw/master/Seatbelt.exe" seatbelt.exe
	_popd
}

SessionGopher() {
	_pushd www
	downloadRawFile "https://github.com/Arvanaghi/SessionGopher/raw/master/SessionGopher.ps1" sessiongopher.ps1
	_popd
}

SharpChrome() {
	_pushd www
	downloadRawFile "https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/raw/master/SharpChrome.exe" sharpchrome.exe
	_popd
}

SharpDPAPI() {
	_pushd www
	downloadRawFile "https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/raw/master/SharpDPAPI.exe" sharpdpapi.exe
	_popd
}

SharpGPOAbuse() {
	_pushd www
	downloadRawFile "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.0_Any/SharpGPOAbuse.exe" sharpgpoabuse.exe
	_popd
}

SharpHandler() {
	_pushd www
	downloadRawFile "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.0_Any/SharpHandler.exe" sharphandler.exe
	_popd
}

SharpHound() {
	_pushd www
	downloadRelease "BloodHoundAD/SharpHound" "SharpHound.*[0-9].zip" sharphound.zip
	unzip -q sharphound.zip
	rm SharpHound.exe.config SharpHound.pdb System.Console.dll System.Diagnostics.Tracing.dll System.Net.Http.dll sharphound.zip
	_popd
}

SharpLAPS() {
	_pushd www
	downloadRelease "swisskyrepo/SharpLAPS" SharpLAPS.exe sharplaps.exe
	_popd
}

SharpNamedPipePTH() {
	_pushd www
	downloadRawFile "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.0_Any/SharpNamedPipePTH.exe" sharpnamedpipepth.exe
	downloadRawFile "https://github.com/penetrarnya-tm/WeaponizeKali.sh/raw/main/ps1/Invoke-SharpNamedPipePTH.ps1" invoke-sharpnamedpipepth.ps1
	_popd
}

SharpRDP() {
	_pushd www
	downloadRawFile "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.5_Any/SharpRDP.exe" sharprdp.exe
	_popd
}

SharpSecDump() {
	_pushd www
	downloadRawFile "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.0_Any/SharpSecDump.exe" sharpsecdump.exe
	_popd
}

SharpView() {
	_pushd www
	downloadRawFile "https://github.com/tevora-threat/SharpView/raw/master/Compiled/SharpView.exe" sharpview.exe
	_popd
}

SharpWMI() {
	_pushd www
	downloadRawFile "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.0_Any/SharpWMI.exe" sharpwmi.exe
	_popd
}

SharpWebServer() {
	_pushd www
	downloadRawFile "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.0_Any/SharpWebServer.exe" sharpwebserver.exe
	_popd
}

Sherlock() {
	_pushd www
	downloadRawFile "https://github.com/rasta-mouse/Sherlock/raw/master/Sherlock.ps1" sherlock.ps1
	_popd
}

Snaffler() {
	_pushd www
	downloadRelease "SnaffCon/Snaffler" Snaffler.exe snaffler.exe
	_popd
}

SpoolSample() {
	_pushd www
	downloadRawFile "https://github.com/BlackDiverX/WinTools/raw/master/SpoolSample-Printerbug/SpoolSample.exe" spoolsample.exe
	_popd
}

StandIn() {
	_pushd www
	downloadRawFile "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.0_Any/StandIn.exe" standin.exe
	_popd
}

WerTrigger() {
	_pushd www
	downloadRawFile "https://github.com/sailay1996/WerTrigger/archive/refs/heads/master.zip" wertrigger.zip
	_popd
}

WinPwn() {
	_pushd www
	cloneRepository "https://github.com/S3cur3Th1sSh1t/WinPwn.git"
	cd WinPwn
	bash Get_WinPwn_Repo.sh --install
	_popd
}

Wireshark() {
	_pushd www
	downloadRawFile "https://1.eu.dl.wireshark.org/win64/WiresharkPortable64_3.6.6.paf.exe" wireshark-portable.exe
	_popd
}

arpfox() {
	_pushd www
	downloadRelease "malfunkt/arpfox" arpfox_linux_amd64.gz arpfox.gz
	gunzip arpfox.gz
	_popd
}

chisel-clients() {
	_pushd www
	mkdir tmp1
	cd tmp1
	downloadRelease "jpillora/chisel" chisel.*linux_amd64.gz chisel.gz
	gunzip chisel.gz
	mv chisel ../chisel
	cd ..
	mkdir tmp2
	cd tmp2
	downloadRelease "jpillora/chisel" chisel.*windows_amd64.gz chisel.exe.gz
	gunzip chisel.exe.gz
	mv chisel.exe ../chisel.exe
	cd ..
	rm -rf tmp1 tmp2
	downloadRawFile "https://github.com/penetrarnya-tm/WeaponizeKali.sh/raw/main/exe/chisel-garble.exe" chisel-garble.exe
	downloadRawFile "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.0_Any/SharpChisel.exe" sharpchisel.exe
	_popd
}

ligolo-ng-agents() {
	_pushd www
	mkdir tmp1
	cd tmp1
	downloadRelease "tnpitsecurity/ligolo-ng" ligolo-ng_agent.*Linux_64bit.tar.gz ligolo-agent.tar.gz
	tar -xzf ligolo-agent.tar.gz
	mv agent ../ligolo-agent
	cd ..
	mkdir tmp2
	cd tmp2
	downloadRelease "tnpitsecurity/ligolo-ng" ligolo-ng_agent.*Windows_64bit.zip ligolo-agent.exe.zip
	unzip -q ligolo-agent.exe.zip
	mv agent.exe ../ligolo-agent.exe
	cd ..
	chmod -x ligolo-agent ligolo-agent.exe
	rm -rf tmp1 tmp2
	_popd
}

linux-exploit-suggester() {
	_pushd www
	downloadRawFile "https://github.com/mzet-/linux-exploit-suggester/raw/master/linux-exploit-suggester.sh" les.sh
	_popd
}

linux-smart-enumeration() {
	_pushd www
	downloadRawFile "https://github.com/diego-treitos/linux-smart-enumeration/raw/master/lse.sh" lse.sh
	_popd
}

mimikatz() {
	_pushd www
	downloadRelease "gentilkiwi/mimikatz" mimikatz_trunk.zip mimikatz.zip
	_popd
}

nanodump-www() {
	_pushd www
	downloadRawFile "https://github.com/helpsystems/nanodump/raw/main/dist/nanodump_ssp.x64.dll" nanodump_ssp.x64.dll
	downloadRawFile "https://github.com/helpsystems/nanodump/raw/main/dist/load_ssp.x64.exe" load_ssp.x64.exe
	cloneRepository "https://gist.github.com/snovvcrash/5487fc83a3c878eaa07c0ca30b709c30.git" /tmp/Invoke-NanoDumpSSPInject
	mv /tmp/Invoke-NanoDumpSSPInject/Invoke-NanoDumpSSPInject.ps1 invoke-nanodumpsspinject.ps1
	rm -rf /tmp/Invoke-NanoDumpSSPInject
	_popd
}

netcat-win() {
	_pushd www
	downloadRawFile "https://eternallybored.org/misc/netcat/netcat-win32-1.12.zip" nc.zip
	unzip -q nc.zip
	rm doexec.c generic.h getopt.c getopt.h hobbit.txt license.txt Makefile netcat.c readme.txt nc.zip
	_popd
}

pamspy() {
	_pushd www
	eget -q "citronneur/pamspy" --to pamspy
	_popd
}

plink() {
	_pushd www
	downloadRawFile "https://the.earth.li/~sgtatham/putty/latest/w64/plink.exe" plink.exe
	_popd
}

powercat() {
	_pushd www
	downloadRawFile "https://github.com/besimorhino/powercat/raw/master/powercat.ps1" powercat.ps1
	_popd
}

pretender-www() {
	_pushd www
	eget -qs linux/amd64 "RedTeamPentesting/pretender" --to pretender
	chmod -x pretender
	eget -qs windows/amd64 "RedTeamPentesting/pretender" --to pretender.exe
	chmod -x pretender.exe
	_popd
}

pspy() {
	_pushd www
	downloadRelease "DominicBreuker/pspy" pspy64 pspy
	_popd
}

pypykatz-exe() {
	_pushd www
	downloadRelease "skelsec/pypykatz" pypykatz.exe pypykatz.exe
	_popd
}

rdp-tunnel-www() {
	_pushd www
	downloadRawFile "https://github.com/NotMedic/rdp-tunnel/raw/master/rdp2tcp.exe" rdp2tcp.exe
	_popd
}

revsocks-clients() {
	_pushd www
	eget -qs linux/amd64 "kost/revsocks" --to revsocks
	chmod -x revsocks
	eget -qs windows/amd64 "kost/revsocks" --to revsocks.exe
	chmod -x revsocks.exe
	_popd
}

static-binaries() {
	_pushd www
	cloneRepository "https://github.com/andrew-d/static-binaries.git"
	_popd
}

suid3num.py() {
	_pushd www
	downloadRawFile "https://github.com/Anon-Exploiter/SUID3NUM/raw/master/suid3num.py" suid3num.py
	_popd
}

www() {
	exe
	ps1
	sys
	ADRecon
	ADSearch
	ASREPRoast
	AccessChk
	Amsi-Bypass-Powershell
	Certify
	DDexec
	DefenderStop
	Discover-PSMSExchangeServers
	Discover-PSMSSQLServers
	DomainPasswordSpray
	#Grouper2
	HandleKatz
	#HiveNightmare
	Intercepter-NG
	Inveigh
	Invoke-ACLPwn
	Invoke-ConPtyShell
	Invoke-ImpersonateUser-PTH
	Invoke-PSInject
	Invoke-PatchWdigest
	Invoke-Portscan
	Invoke-RunasCs
	Invoke-SMBClient
	Invoke-SMBEnum
	Invoke-SMBExec
	Invoke-WMIExec
	Invoke-noPac
	JAWS
	JuicyPotato
	KSC-Console
	KrbRelay
	KrbRelayUp
	LaZagne
	OffensivePythonPipeline
	Out-EncryptedScript
	PEASS
	PingCastle
	PowerShellArmoury
	PowerUp
	PowerUpSQL
	PowerView2
	PowerView3
	PowerView3-GPO
	PowerView4
	Powermad
	PrintSpoofer
	PrivescCheck
	PSTools
	ProcDump
	Python-2.7.18
	RawCopy
	RemotePotato0
	RoguePotato
	Rubeus
	Seatbelt
	SessionGopher
	SharpChrome
	SharpDPAPI
	SharpGPOAbuse
	SharpHandler
	SharpHound
	SharpLAPS
	SharpNamedPipePTH
	SharpRDP
	SharpSecDump
	SharpView
	SharpWMI
	SharpWebServer
	Sherlock
	Snaffler
	SpoolSample
	StandIn
	WerTrigger
	WinPwn
	Wireshark
	arpfox
	chisel-clients
	ligolo-ng-agents
	linux-exploit-suggester
	mimikatz
	nanodump-www
	netcat-win
	pamspy
	plink
	powercat
	pretender-www
	pspy
	pypykatz-exe
	rdp-tunnel-www
	revsocks-clients
	static-binaries
	suid3num.py
}

# -----------------------------------------------------------------------------
# ----------------------------------- Help ------------------------------------
# -----------------------------------------------------------------------------

help() {
	echo "usage: WeaponizeKali.sh [-h] [-i] [-d] [-t] [w]"
	echo
	echo "optional arguments:"
	echo "  -h                    show this help message and exit"
	echo "  -i                    initialize filesystem (re-create ./tools and ./www directories)"
	echo "  -d                    resolve dependencies"
	echo "  -t                    download and install tools on Kali Linux"
	echo "  -w                    download scripts and binaries for transferring onto the victim host"
}

# -----------------------------------------------------------------------------
# ----------------------------------- Main ------------------------------------
# -----------------------------------------------------------------------------

while getopts "chidtw" opt; do
	case "$opt" in
	c)
		use_docker=1
		;;
	h)
		call_help=1
		;;
	i)
		init_filesystem=1
		;;
	d)
		resolve_dependencies=1
		;;
	t)
		call_tools=1
		;;
	w)
		call_www=1
		;;
	esac
done

if [[ "$call_help" ]]; then
	help
	exit
fi

if [[ "$init_filesystem" ]]; then
	filesystem
fi

if [[ "$resolve_dependencies" ]]; then
	echo -e "${red}################################### dependencies ####################################"
	dependencies
fi

if [[ "$call_tools" ]]; then
	sudo apt update
	echo -e "${red}####################################### tools #######################################"
	tools
fi

if [[ "$call_www" ]]; then
	echo -e "${red}######################################## www ########################################"
	www
fi

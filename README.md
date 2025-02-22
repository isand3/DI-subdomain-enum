# DI-subdomain-enum
A few scripts that work together to enumerate subdomains for a target or a list of targets from a JSON file, and then organize the results so you can do your job faster.

Note that these scripts have a straightforward purpose, so they are crude by design.<br/>
They are also easily modified.<br/>

# manysubs.sh
Enumerates subdomains for every domain (asset) in the JSON file from Defend Iceland (placed in the current directory) using subfinder and assetfinder. <br/>
Then validates with httpx.<br/>
It will supply the current directory with a txt file for each domain, in addition to an all.txt file with a list of every subdomain.

# onesub.sh
Does the same as `manysubs.sh`, but for one domain.

# update.sh
Copies the scripts to bin

# Dependencies
Requires: `jq`, `subfinder`, `assetfinder`, `httpx` (projectdiscovery)

https://github.com/jqlang/jq

https://github.com/projectdiscovery/subfinder

https://github.com/tomnomnom/assetfinder

https://github.com/projectdiscovery/httpx



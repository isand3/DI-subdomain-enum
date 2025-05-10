# DI-subdomain-enum
Scripts that enumerate subdomains for a list of targets from a JSON file, and then organize the results so you can do your job faster.

Note that these scripts have a straightforward purpose, so they are crude by design.<br/>
They are also easily modified.<br/>

# manysubs.sh
Enumerates subdomains for every domain (asset) in the JSON file from Defend Iceland (placed in the current directory) using subfinder and assetfinder. <br/>
It will supply the current directory with a txt file containing all subdomains found.

# update.sh
Copies scripts in `./DI-subdomain-enum/base` to `/bin` (for future proofing)

# Dependencies
Requires: `jq`, `subfinder`, `assetfinder`

https://github.com/jqlang/jq

https://github.com/projectdiscovery/subfinder

https://github.com/tomnomnom/assetfinder

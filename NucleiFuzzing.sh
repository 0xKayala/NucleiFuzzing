#!/bin/bash

# ASCII art
echo -e "\e[91m

$$\   $$\                     $$\           $$\ $$$$$$$$\                            $$\                     
$$$\  $$ |                    $$ |          \__|$$  _____|                           \__|                    
$$$$\ $$ |$$\   $$\  $$$$$$$\ $$ | $$$$$$\  $$\ $$ |   $$\   $$\ $$$$$$$$\ $$$$$$$$\ $$\ $$$$$$$\   $$$$$$\  
$$ $$\$$ |$$ |  $$ |$$  _____|$$ |$$  __$$\ $$ |$$$$$\ $$ |  $$ |\____$$  |\____$$  |$$ |$$  __$$\ $$  __$$\ 
$$ \$$$$ |$$ |  $$ |$$ /      $$ |$$$$$$$$ |$$ |$$  __|$$ |  $$ |  $$$$ _/   $$$$ _/ $$ |$$ |  $$ |$$ /  $$ |
$$ |\$$$ |$$ |  $$ |$$ |      $$ |$$   ____|$$ |$$ |   $$ |  $$ | $$  _/    $$  _/   $$ |$$ |  $$ |$$ |  $$ |
$$ | \$$ |\$$$$$$  |\$$$$$$$\ $$ |\$$$$$$$\ $$ |$$ |   \$$$$$$  |$$$$$$$$\ $$$$$$$$\ $$ |$$ |  $$ |\$$$$$$$ |
\__|  \__| \______/  \_______|\__| \_______|\__|\__|    \______/ \________|\________|\__|\__|  \__| \____$$ |
                                                                                                   $$\   $$ |
                                                                                                   \$$$$$$  |
                                                                                                    \______/ 
                                                                                                    
\e[0m"

# Help menu
display_help() {
    echo -e "NucleiFuzzing is a powerful automation tool for detecting xss,sqli,ssrf,open-redirect...etc vulnerabilities in web applications\n\n"
    echo -e "Usage: $0 [options]\n\n"
    echo "Options:"
    echo "  -h, --help              Display help information"
    echo "  -d, --domain <domain>   Domain to scan for xss,sqli,ssrf,open-redirect"
    exit 0
}

# Step 0: Ask the user to enter the target domain
echo -n "Enter your target domain: "
read target_domain

# Step 1: Run the dork command and collect the URLs found
echo "Running dork command and collecting URLs..."
urls=$(echo "site:*.$target_domain ext:php" | hakrawler -plain | grep "?" | uro | httpx -silent)

# Check if URLs found
if [ -z "$urls" ]; then
    echo "No URLs found"
    exit 1
fi

# Save the URLs to a file
echo "$urls" > hakrawlerurls.txt

# Step 2: Collect live subdomains and verify them with httpx
echo "Collecting live subdomains..."
subfinder -d "$target_domain" | httpx -silent -o subdomains.txt

# Step 3: Run the command on live subdomains and save the output
echo "Running waybackurls and collecting subparameters..."
while read -r subdomain; do
    echo "Processing $subdomain"
    echo "https://$subdomain" | waybackurls | grep "?" | uro | httpx -silent >> subparameters.txt
done < subdomains.txt

# Combine hakrawlerurls.txt and subparameters.txt into final_data.txt
cat hakrawlerurls.txt subparameters.txt > final_data.txt

# Step 4: Run nuclei fuzzer on final_data.txt
echo "Running nuclei fuzzer on final_data.txt"
nuclei -l final_data.txt -t fuzzing-templates

# Step 5: Run main nuclei tool and print the output
echo "Running main nuclei tool on final_data.txt"
nuclei -l final_data.txt -t nuclei-templates -rl 05 -es info

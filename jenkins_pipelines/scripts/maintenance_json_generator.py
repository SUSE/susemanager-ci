import argparse
import json
import subprocess
import sys

import requests

# dictionary for 4.3 client tools
clienttools43dict = {
    "sle12sp5_client": "/SUSE_Updates_SLE-Manager-Tools_12_x86_64/",
    "sle12sp5_minion": "/SUSE_Updates_SLE-Manager-Tools_12_x86_64/",
    "sle15_client": ["/SUSE_Updates_SLE-Manager-Tools_15_x86_64/",
                     "/SUSE_Updates_SLE-Product-SLES_15-LTSS_x86_64/"],
    "sle15_minion": ["/SUSE_Updates_SLE-Manager-Tools_15_x86_64/",
                     "/SUSE_Updates_SLE-Product-SLES_15-LTSS_x86_64/"],
    "sle15sp1_client": ["/SUSE_Updates_SLE-Manager-Tools_15_x86_64/",
                        "/SUSE_Updates_SLE-Product-SLES_15-SP1-LTSS_x86_64/"],
    "sle15sp1_minion": ["/SUSE_Updates_SLE-Manager-Tools_15_x86_64/",
                        "/SUSE_Updates_SLE-Product-SLES_15-SP1-LTSS_x86_64/"],
    "sle15sp2_client": ["/SUSE_Updates_SLE-Manager-Tools_15_x86_64/",
                        "/SUSE_Updates_SLE-Product-SLES_15-SP2-LTSS_x86_64/"],
    "sle15sp2_minion": ["/SUSE_Updates_SLE-Manager-Tools_15_x86_64/",
                        "/SUSE_Updates_SLE-Product-SLES_15-SP2-LTSS_x86_64/"],
    "sle15sp3_client": ["/SUSE_Updates_SLE-Manager-Tools_15_x86_64/",
                        "/SUSE_Updates_SLE-Module-Basesystem_15-SP3_x86_64/",
                        "/SUSE_Updates_SLE-Module-Server-Applications_15-SP3_x86_64/",
                        "/SUSE_Updates_SLE-Product-SLES_15-SP3-LTSS_x86_64/"],
    "sle15sp3_minion": ["/SUSE_Updates_SLE-Manager-Tools_15_x86_64/",
                        "/SUSE_Updates_SLE-Module-Basesystem_15-SP3_x86_64/",
                        "/SUSE_Updates_SLE-Module-Server-Applications_15-SP3_x86_64/",
                        "/SUSE_Updates_SLE-Product-SLES_15-SP3-LTSS_x86_64/"],
    "sle15sp4_client": ["/SUSE_Updates_SLE-Manager-Tools_15_x86_64/",
                        "/SUSE_Updates_SLE-Module-Basesystem_15-SP4_x86_64/",
                        "/SUSE_Updates_SLE-Module-Server-Applications_15-SP4_x86_64/",
                        "/SUSE_Updates_SLE-Product-SLES_15-SP4-LTSS_x86_64/"],
    "sle15sp4_minion": ["/SUSE_Updates_SLE-Manager-Tools_15_x86_64/",
                        "/SUSE_Updates_SLE-Module-Basesystem_15-SP4_x86_64/",
                        "/SUSE_Updates_SLE-Module-Server-Applications_15-SP4_x86_64/",
                        "/SUSE_Updates_SLE-Product-SLES_15-SP4-LTSS_x86_64/"],
    "sle15sp5_client": ["/SUSE_Updates_SLE-Manager-Tools_15_x86_64/",
                        "/SUSE_Updates_SLE-Module-Basesystem_15-SP5_x86_64/",
                        "/SUSE_Updates_SLE-Module-Server-Applications_15-SP5_x86_64/"],
    "sle15sp5_minion": ["/SUSE_Updates_SLE-Manager-Tools_15_x86_64/",
                        "/SUSE_Updates_SLE-Module-Basesystem_15-SP5_x86_64/",
                        "/SUSE_Updates_SLE-Module-Server-Applications_15-SP5_x86_64/"],
    "sle15sp5s390_minion": ["/SUSE_Updates_SLE-Manager-Tools_15_s390x/",
                            "/SUSE_Updates_SLE-Module-Basesystem_15-SP5_s390x/",
                            "/SUSE_Updates_SLE-Module-Server-Applications_15-SP5_s390x/"],
    "centos7_client": "/SUSE_Updates_RES_7-CLIENT-TOOLS_x86_64/",
    "centos7_minion": "/SUSE_Updates_RES_7-CLIENT-TOOLS_x86_64",
    "rocky8_minion": "/SUSE_Updates_RES_8-CLIENT-TOOLS_x86_64/",
    "alma8_minion": "/SUSE_Updates_RES_8-CLIENT-TOOLS_x86_64/",
    "ubuntu2004_minion": "/SUSE_Updates_Ubuntu_20.04-CLIENT-TOOLS_x86_64/",
    "ubuntu2204_minion": "/SUSE_Updates_Ubuntu_22.04-CLIENT-TOOLS_x86_64/",
    "debian10_minion": "/SUSE_Updates_Debian_10-CLIENT-TOOLS_x86_64/",
    "debian11_minion": "/SUSE_Updates_Debian_11-CLIENT-TOOLS_x86_64/",
    "debian12_minion": "/SUSE_Updates_Debian_12-CLIENT-TOOLS_x86_64/",
    "opensuse154arm_minion": ["/SUSE_Updates_openSUSE-SLE_15.4/",
                              "/SUSE_Updates_SLE-Manager-Tools_15_aarch64/"],
    "opensuse155arm_minion": ["/SUSE_Updates_openSUSE-SLE_15.5/",
                              "/SUSE_Updates_SLE-Manager-Tools_15_aarch64/"],
    "rhel9_minion": "/SUSE_Updates_EL_9-CLIENT-TOOLS_x86_64/",
    "rocky9_minion": "/SUSE_Updates_EL_9-CLIENT-TOOLS_x86_64/",
    "alma9_minion": "/SUSE_Updates_EL_9-CLIENT-TOOLS_x86_64/",
    "oracle9_minion": "/SUSE_Updates_EL_9-CLIENT-TOOLS_x86_64/",
    "slemicro51_minion": ["/SUSE_Updates_SLE-Manager-Tools-For-Micro_5_x86_64/",
                          "/SUSE_Updates_SUSE-MicroOS_5.1_x86_64/"],
    "slemicro52_minion": ["/SUSE_Updates_SLE-Manager-Tools-For-Micro_5_x86_64/",
                          "/SUSE_Updates_SUSE-MicroOS_5.2_x86_64/"],
    "slemicro53_minion": ["/SUSE_Updates_SLE-Manager-Tools-For-Micro_5_x86_64/",
                          "/SUSE_Updates_SUSE-MicroOS_5.3_x86_64/",
                          "/SUSE_Updates_SLE-Micro_5.3_x86_64/"],
    "slemicro54_minion": ["/SUSE_Updates_SLE-Manager-Tools-For-Micro_5_x86_64/",
                          "/SUSE_Updates_SUSE-MicroOS_5.4_x86_64/",
                          "/SUSE_Updates_SLE-Micro_5.4_x86_64/"],
    "slemicro55_minion": ["/SUSE_Updates_SLE-Manager-Tools-For-Micro_5_x86_64/",
                          "/SUSE_Updates_SUSE-MicroOS_5.5_x86_64/",
                          "/SUSE_Updates_SLE-Micro_5.5_x86_64/"],
    "salt_migration_minion": ["/SUSE_Updates_SLE-Manager-Tools_15_x86_64/",
                              "/SUSE_Updates_SLE-Module-Basesystem_15-SP5_x86_64/",
                              "/SUSE_Updates_SLE-Module-Server-Applications_15-SP5_x86_64/"],
}

# dictionary for 5.0 client tools
clienttools50betadict = {
    "sle12sp5_client": "/SUSE_Updates_SLE-Manager-Tools_12-BETA_x86_64/",
    "sle12sp5_minion": "/SUSE_Updates_SLE-Manager-Tools_12-BETA_x86_64/",
    "sle15_client": "/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/",
    "sle15_minion": "/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/",
    "sle15sp1_client": "/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/",
    "sle15sp1_minion": "/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/",
    "sle15sp2_client": "/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/",
    "sle15sp2_minion": "/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/",
    "sle15sp3_client": "/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/",
    "sle15sp3_minion": "/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/",
    "sle15sp4_client": "/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/",
    "sle15sp4_minion": "/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/",
    "sle15sp5_client": "/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/",
    "sle15sp5_minion": "/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/",
    "sle15sp5s390_minion": "/SUSE_Updates_SLE-Manager-Tools_15-BETA_s390x/",
    "centos7_client": "/SUSE_Updates_RES_7-CLIENT-TOOLS-BETA_x86_64/",
    "centos7_minion": "/SUSE_Updates_RES_7-CLIENT-TOOLS-BETA_x86_64",
    "rocky8_minion": "/SUSE_Updates_RES_8-CLIENT-TOOLS-BETA_x86_64/",
    "alma8_minion": "/SUSE_Updates_RES_8-CLIENT-TOOLS-BETA_x86_64/",
    "ubuntu2004_minion": "/SUSE_Updates_Ubuntu_20.04-CLIENT-TOOLS-BETA_x86_64/",
    "ubuntu2204_minion": "/SUSE_Updates_Ubuntu_22.04-CLIENT-TOOLS-BETA_x86_64/",
    "debian10_minion": "/SUSE_Updates_Debian_10-CLIENT-TOOLS-BETA_x86_64/",
    "debian11_minion": "/SUSE_Updates_Debian_11-CLIENT-TOOLS-BETA_x86_64/",
    "debian12_minion": "/SUSE_Updates_Debian_12-CLIENT-TOOLS-BETA_x86_64/",
    "opensuse154arm_minion": "/SUSE_Updates_SLE-Manager-Tools_15-BETA_aarch64/",
    "opensuse155arm_minion": "/SUSE_Updates_SLE-Manager-Tools_15-BETA_aarch64/",
    "rhel9_minion": "/SUSE_Updates_EL_9-CLIENT-TOOLS-BETA_x86_64/",
    "rocky9_minion": "/SUSE_Updates_EL_9-CLIENT-TOOLS-BETA_x86_64/",
    "alma9_minion": "/SUSE_Updates_EL_9-CLIENT-TOOLS-BETA_x86_64/",
    "oracle9_minion": "/SUSE_Updates_EL_9-CLIENT-TOOLS-BETA_x86_64/",
    "slemicro51_minion": ["/SUSE_Updates_SLE-Manager-Tools-BETA-For-Micro_5_x86_64/",
                          "/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/"],
    "slemicro52_minion": ["/SUSE_Updates_SLE-Manager-Tools-BETA-For-Micro_5_x86_64/",
                          "/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/"],
    "slemicro53_minion": ["/SUSE_Updates_SLE-Manager-Tools-BETA-For-Micro_5_x86_64/",
                          "/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/"],
    "slemicro54_minion": ["/SUSE_Updates_SLE-Manager-Tools-BETA-For-Micro_5_x86_64/",
                          "/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/"],
    "slemicro55_minion": ["/SUSE_Updates_SLE-Manager-Tools-BETA-For-Micro_5_x86_64/",
                          "/SUSE_Updates_SLE-Manager-Tools_15-BETA_x86_64/"],
    "salt_migration_minion": "/SUSE_Updates_SLE-Manager-Tools_15_x86_64-BETA/"
}

# Dictionary for SUMA 4.3 Server and Proxy, which is then added together with the common dictionary for 4.3 client tools
nodesdict43 = {
    "server": ["/SUSE_Updates_SLE-Module-SUSE-Manager-Server_4.3_x86_64/",
               "/SUSE_Updates_SLE-Product-SUSE-Manager-Server_4.3_x86_64/",
               "/SUSE_Updates_SLE-Module-Basesystem_15-SP4_x86_64/",
               "/SUSE_Updates_SLE-Module-Web-Scripting_15-SP4_x86_64/",
               "/SUSE_Updates_SLE-Module-Server-Applications_15-SP4_x86_64/"],
    "proxy": ["/SUSE_Updates_SLE-Module-SUSE-Manager-Proxy_4.3_x86_64/",
              "/SUSE_Updates_SLE-Product-SUSE-Manager-Proxy_4.3_x86_64/",
              "/SUSE_Updates_SLE-Module-Basesystem_15-SP4_x86_64/",
              "/SUSE_Updates_SLE-Module-Server-Applications_15-SP4_x86_64/"]
}
nodesdict43.update(clienttools43dict)

# 5.0 Server coming from
# https://build.suse.de/package/view_file/SUSE:SLE-15-SP5:Update:Products:Manager50/000product/SUSE-Manager-Server.product?expand=1
# line 25 + 71 with ":" changed to "_" 5.0 Proxy coming from
# https://build.suse.de/package/view_file/SUSE:SLE-15-SP5:Update:Products:Manager50/000product/SUSE-Manager-Proxy.product?expand=1
# line 25 + 71 with ":" changed to "_"
# Only product, we are extension not module anymore

# Dictionary for SUMA 5.0 Server and Proxy, which is then added together with
# the common dictionary for 4.3 client tools and 5.0 BETA client tools. Both
# client tools are needed until 5.0 gets its own client tools.
nodesdict50 = {
    "server": ["/SUSE_Products_SUSE-Manager-Server_5.0_x86_64/",
               "/SUSE_Updates_SUSE-Manager-Server_5.0_x86_64/"],
    "proxy": ["/SUSE_Products_SUSE-Manager-Proxy_5.0_x86_64/",
              "/SUSE_Updates_SUSE-Manager-Proxy_5.0_x86_64/"]
}

# Merging clienttools43dict and clienttools50betadict
# For now we need non-BETA together with BETA client tools until the split
# between 4.3 and 5.0 for client tools happens, just before GA
# After the split the 5.0 non-BETA client tools will have different names than
# the 4.3 non-BETA client tools. They will not be common.
finaldict = {}

for key, value in clienttools43dict.items():
    if key in clienttools50betadict:
        if isinstance(value, list):
            if isinstance(clienttools50betadict[key], list):
                finaldict[key] = value + clienttools50betadict[key]
            else:
                finaldict[key] = value + [clienttools50betadict[key]]
        else:
            if isinstance(clienttools50betadict[key], list):
                finaldict[key] = [value] + clienttools50betadict[key]
            else:
                finaldict[key] = [value, clienttools50betadict[key]]
    else:
        finaldict[key] = value

# Merging finaldict with nodesdict50
for key, value in nodesdict50.items():
    if key in finaldict:
        if isinstance(finaldict[key], list):
            finaldict[key].extend(value)
        else:
            finaldict[key] = [finaldict[key]] + value
    else:
        finaldict[key] = value

nodesdict50 = finaldict


def parse_args():
    parser = argparse.ArgumentParser(
        description="This script reads the open qam-manager requests and creates a json file that can be fed in the "
                    "BV testsuite pipeline")
    parser.add_argument("-v", "--version", dest="version",
                        help="Version of SUMA you want to run this script for, the options are 43 for 4.3 and 50 for "
                             "5.0. The default is 43 for now",
                        default="43", action='store')
    parser.add_argument("-i", "--mi_ids", dest="mi_ids", help="MI IDs", default=None, action='store')

    args = parser.parse_args()
    return args


def read_requests():
    # Find open requests
    result = object
    try:
        # TODO Find a better way to query the open requests, this is fragile because it depends on external utils
        #  being there.
        result = subprocess.run(["osc --apiurl https://api.suse.de qam open -G qam-manager"], shell=True,
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except subprocess.CalledProcessError:
        print("The ibs command failed for some reason")
    output = result.stdout.decode('utf-8')
    lines = output.splitlines()
    # Create empty list to add the maintenance incidents from the output
    mi_ids = []
    for line in lines:
        if "ReviewRequest" in line:
            line1 = line.rstrip()
            line2 = line1.split(sep=":")
            mi_id = line2[3]
            mi_ids.append(mi_id)
    return mi_ids


def find_valid_repos(mi_ids, version):
    if version == '43':
        dict_version = nodesdict43
    elif version == '50':
        dict_version = nodesdict50
    else:
        print("You have not given one of the correct options, run the script with -h to see the correct ones")
        sys.exit(1)
    finaldict = {}
    for node, suffixraw in dict_version.items():
        for mi_id in mi_ids:
            if isinstance(suffixraw, str):
                suffix = suffixraw
                repo = create_url(mi_id, suffix)
                if repo is not None:
                    if node in finaldict:
                        # This is needed for mi_ids that have multiple repos for each node, e.g. basesystem and server
                        # apps for server
                        if mi_id in finaldict[node]:
                            for i in range(1, 100):
                                if str(mi_id) + '-' + str(i) not in finaldict[node]:
                                    finaldict[node][str(mi_id) + '-' + str(i)] = repo
                                    break
                        else:
                            finaldict[node][mi_id] = repo
                    else:
                        # for each mi_id we have multiple repos sometimes for each node
                        finaldict[node] = {mi_id: repo}
            elif isinstance(suffixraw, list):
                for suffix in suffixraw:
                    repo = create_url(mi_id, suffix)
                    if repo is not None:
                        if node in finaldict:
                            # This is needed for mi_ids that have multiple repos for each node, e.g. basesystem and
                            # server apps for server
                            if mi_id in finaldict[node]:
                                for i in range(1, 100):
                                    if str(mi_id) + '-' + str(i) not in finaldict[node]:
                                        finaldict[node][str(mi_id) + '-' + str(i)] = repo
                                        break
                            else:
                                # for each mi_id we have multiple repos sometimes for each node
                                finaldict[node][mi_id] = repo
                        else:
                            # for each mi_id we have multiple repos sometimes for each node
                            finaldict[node] = {mi_id: repo}

    # TODO Remove the following hardcoding at GA, we should start getting MIs for server and proxy
    # Add exception for specific URL for "server" and "proxy" nodes in version 5.0
    if version == '50':
        # Hardcoded URLs for "server" and "proxy" nodes until we get MIs with them
        server_url = "http://download.suse.de/ibs/SUSE:/SLE-15-SP5:/Update:/Products:/Manager50/images/repo/SUSE-Manager-Server-5.0-POOL-x86_64-Media1/"
        proxy_url = "http://download.suse.de/ibs/SUSE:/SLE-15-SP5:/Update:/Products:/Manager50/images/repo/SUSE-Manager-Proxy-5.0-POOL-x86_64-Media1/"
        finaldict['server'] = {'server_50': server_url}
        finaldict['proxy'] = {'proxy_50': proxy_url}

    # Format into json and print
    # Check that it's not empty and save to file
    if finaldict:
        with open('custom_repositories.json', 'w', encoding='utf-8') as f:
            json.dump(finaldict, f, indent=2)
    else:
        print("Dictionary is empty, something went wrong")
        sys.exit(1)


def create_url(mi_id, suffix):
    link = ["http://download.suse.de/ibs/SUSE:/Maintenance:/", str(mi_id)]

    if link[:-1] == str(mi_id):
        link.append(suffix)
        url = ''.join(link)
    else:
        link = ''.join(link)
        url = str(link) + suffix
    re = requests.get(url)
    if re.ok:
        return url


def main():
    args = parse_args()
    if args.mi_ids is not None:
        # Ignore spaces before or after the comma
        mi_ids = [id.strip() for id in args.mi_ids.split(",")]
    else:
        mi_ids = read_requests()
    find_valid_repos(mi_ids, args.version)


if __name__ == '__main__':
    main()

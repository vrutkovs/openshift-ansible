#!/bin/bash

set -euxo pipefail

dns_zone="{{ dns_managed_zone | default(openshift_gcp_prefix + 'managed-zone') }}"
# configure DNS
(
# Retry DNS changes until they succeed since this may be a shared resource
while true; do
    dns="${TMPDIR:-/tmp}/dns.yaml"
    rm -f $dns
    gcloud dns record-sets export --project "{{ openshift_gcp_project }}" -z "${dns_zone}" --zone-file-format "${dns}"
    cat "${dns}"

    # Fetch API record to get a list of masters + bootstrap node
    public_ip_output=($(grep -F -e '{{ openshift_master_cluster_public_hostname }}.' "${dns}" | awk '{ print $5 }')) || public_ip_output=""

    for index in "${!public_ip_output[@]}"; do
        if [ ${index} -eq 0 ]; then
            # Remove first record - its an address of bootstrap node
            grep -F -e "{{ openshift_master_cluster_public_hostname }}." "${dns}" | awk '{ print "--name", $1, "--ttl", $2, "--type", $4, $5; }' | head -n1 > "${dns}.input" || true
            break
        fi
    done
    if [ -s "${dns}.input" ]; then
        cat "${dns}.input"
        cat "${dns}.input" | xargs -L1 gcloud --project "{{ openshift_gcp_project }}" dns record-sets transaction --transaction-file="${dns}" remove -z "${dns_zone}"
        cat "${dns}"
        # Commit all DNS changes, retrying if preconditions are not met
        if ! out="$( gcloud --project "{{ openshift_gcp_project }}" dns record-sets transaction --transaction-file=$dns execute -z "${dns_zone}" 2>&1 )"; then
            rc=$?
            if [[ "${out}" == *"HTTPError 412: Precondition not met"* ]]; then
                continue
            fi
            exit $rc
        fi
    fi
    rm "${dns}.input"
    break
done
) &

for i in `jobs -p`; do wait $i; done

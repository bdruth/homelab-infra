# Fission CRD Installation Workaround

## Problem
Fission CRDs in recent versions have annotations exceeding Kubernetes' 262KB limit, causing installation failures with client-side apply.

## Solution
Use **server-side apply** with `kubernetes.core.k8s` module in Ansible:

```yaml
- name: Install Fission CRDs using server-side apply
  kubernetes.core.k8s:
    src: "{{ item }}"
    state: present
    apply: true
    server_side_apply:
      field_manager: ansible
    wait: true
    wait_timeout: 300
  loop:
    - "https://raw.githubusercontent.com/fission/fission/v1.21.0/crds/v1/fission.io_*.yaml"
```

## Key Points
- Uses **official Fission CRDs** (no custom minimal definitions needed)
- `server_side_apply` bypasses annotation size limits
- `field_manager: ansible` avoids conflicts with other tools
- Works with all 8 Fission CRDs including environments and functions
- Compatible with MicroK8s environment

## Reference
Based on GitHub issue comment: "kubectl apply --server-side=true -f avoids metadata byte limit"

# current_practice

Examples written against **Kubernetes v1.37** (August 2026).

The rest of this repo teaches the object model: pods, deployments, services,
volumes, RBAC. That material is still correct and it is still the right place
to start. This folder is the layer on top — the things a team gets wrong
*after* they know what a Deployment is, and the API surface that has changed
enough since v1.27 that older notes are now misleading.

Every file is runnable and every file is commented with the reason the field
exists, not just what it does.

## Run them

Either use the two-node kubeadm cluster from `Kubernetes_installation_readme_file`,
or bring up a local one:

```bash
kind create cluster --config current_practice/00-kind-cluster.yaml

# The kind config disables the default CNI on purpose — see the file.
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.32.2/manifests/tigera-operator.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.32.2/manifests/custom-resources.yaml

kubectl apply -f current_practice/01-namespace-pod-security.yaml   # fails on purpose
kubectl apply -f current_practice/02-secure-deployment.yaml
```

## What's in here

| File | What it teaches |
|---|---|
| `00-kind-cluster.yaml` | Local 3-node cluster, default CNI off so NetworkPolicy is real |
| `01-namespace-pod-security.yaml` | Pod Security Admission — what replaced PodSecurityPolicy |
| `02-secure-deployment.yaml` | A workload the `restricted` standard accepts, and why the image matters more than the YAML |
| `03-native-sidecar.yaml` | Native sidecars, and the two bugs they fix |
| `04-probes-and-shutdown.yaml` | startupProbe, liveness vs readiness, and why rolling updates drop requests |
| `05-autoscaling-hpa-v2.yaml` | `autoscaling/v2`, multiple metrics, scale-up and scale-down behaviour |
| `06-availability-pdb-spread.yaml` | PodDisruptionBudget and topology spread |
| `07-jobs-failure-and-success.yaml` | `podFailurePolicy`, Indexed Jobs, `successPolicy` |
| `08-resource-governance.yaml` | Requests vs limits, quota, LimitRange, PriorityClass — and the CPU limit argument |
| `09-in-place-pod-resize.yaml` | Resizing a running pod without restarting it |
| `10-gateway-api.yaml` | Gateway API, and why Ingress stopped getting features |
| `11-validating-admission-policy.yaml` | Admission control in CEL, no webhook to run |
| `12-storage.yaml` | `ReadWriteOncePod`, PVC retention policy, expansion |
| `13-network-policy.yaml` | Default-deny, and the test that proves your CNI enforces it |

## What changed since v1.27, in one table

If you have slides, notes or manifests from before 2024, these are the ones
that will embarrass you in front of a room.

| Gone or frozen | Use instead | Removed in |
|---|---|---|
| PodSecurityPolicy | Pod Security Admission labels | v1.25 |
| `policy/v1beta1` PodDisruptionBudget | `policy/v1` | v1.25 |
| `autoscaling/v2beta1`, `v2beta2` | `autoscaling/v2` | v1.26 |
| `batch/v1beta1` CronJob | `batch/v1` | v1.25 |
| Dockershim | containerd or CRI-O | v1.24 |
| `apt.kubernetes.io`, `packages.cloud.google.com` | `pkgs.k8s.io` | switched off Mar 2024 |
| Dashboard manifest install | Helm chart only | Dashboard v7.0.0 |
| Ingress (frozen, not removed) | Gateway API | — |

| Newer, and worth knowing | Status |
|---|---|
| Native sidecar containers | GA v1.33 |
| `podFailurePolicy` | GA v1.31 |
| Job `successPolicy` | GA v1.33 |
| ValidatingAdmissionPolicy | GA v1.30 |
| `ReadWriteOncePod` | GA v1.29 |
| StatefulSet PVC retention policy | GA v1.32 |
| `preStop.sleep` (no shell needed) | GA v1.34 |
| In-place pod resize | GA v1.35 |
| User namespaces (`hostUsers: false`) | Beta, on by default v1.33 |
| Dynamic Resource Allocation | GA v1.34 |

## Version support

Kubernetes supports the three most recent minor versions — 14 months each.

| Version | Released | End of life |
|---|---|---|
| 1.37 | 26 Aug 2026 | 28 Oct 2027 |
| 1.36 | 22 Apr 2026 | 28 Jun 2027 |
| 1.35 | 17 Dec 2025 | 28 Feb 2027 |

Anything older than 1.35 gets no security patches.

## A note on the image tags

Images are pinned, never `:latest`, and the versions here were current in
September 2026 (nginx stable 1.30, busybox 1.37). Pinning is the point —
`11-validating-admission-policy.yaml` rejects `:latest` outright. Bump them
when you next run a class; the manifests do not depend on the exact tag.

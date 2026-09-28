# kubernetes_demo

Hands-on Kubernetes examples used in training, verified against **Kubernetes
v1.37**.

Two layers:

- the root and `examples/` cover the object model — pods, deployments,
  services, volumes, configmaps, RBAC, statefulsets, jobs, daemonsets
- [`current_practice/`](current_practice/) covers what teams get wrong *after*
  that, and the API surface that has changed since v1.27

## Start here

Build a cluster:

- **Two nodes, kubeadm, the real thing** — [`Kubernetes_installation_readme_file`](Kubernetes_installation_readme_file)
- **One laptop, three minutes** — `kind create cluster --config current_practice/00-kind-cluster.yaml`

Then:

```bash
kubectl apply -f examples/demo_k8s_deployment.yaml
kubectl apply -f current_practice/02-secure-deployment.yaml
```

## Layout

```
installation_scripts/     kubeadm node preparation, Ubuntu 22.04/24.04
examples/                 the object model, one concept per file
current_practice/         v1.37 practice: security, availability, scheduling
WordPress_MySQL_Deployment/   a two-tier app with kustomize
```

## September 2026 update

This repo previously targeted **v1.27**, which left support in 2024. What
changed:

**The installer was broken.** `pre_configure_k8s_master.sh` pointed at
`apt.kubernetes.io` and `packages.cloud.google.com`. Those repositories were
frozen in September 2023 and switched off in March 2024, so the script failed
at `apt update` for anyone who ran it after that date. Both scripts now use
`pkgs.k8s.io`, keys in `/etc/apt/keyrings` with `signed-by=`, and a
`KUBE_VERSION` you can override.

**Three manifests did not apply.** Two had duplicate `spec:` keys, one nested
`volumes` inside a container, and a ConfigMap had an unquoted integer. All
four are fixed, with a comment saying what was wrong — they make good
exercises.

**The Dashboard instructions installed software that no longer ships that
way.** Dashboard dropped manifest installs at v7.0.0; it is Helm only now.

**Images were unpinned or ancient.** `nginx:latest` is gone, along with
`nginx:latest-alpine`, which was never a real tag. Everything is pinned.

**`current_practice/` is new** — 14 files covering Pod Security Admission,
native sidecars, `autoscaling/v2`, PodDisruptionBudgets, topology spread,
`podFailurePolicy`, in-place pod resize, Gateway API,
ValidatingAdmissionPolicy, `ReadWriteOncePod` and NetworkPolicy. Each one
explains the problem the field exists to solve, not just the syntax.

All manifests validate against the v1.37 schemas with
[kubeconform](https://github.com/yannh/kubeconform):

```bash
kubeconform -kubernetes-version 1.37.0 -strict -summary \
  -ignore-missing-schemas -ignore-filename-pattern 'kind-cluster' \
  examples/*.yaml current_practice/*.yaml
```

## Version support

Kubernetes supports the three most recent minor versions, 14 months each.

| Version | Released | End of life |
|---|---|---|
| 1.37 | 26 Aug 2026 | 28 Oct 2027 |
| 1.36 | 22 Apr 2026 | 28 Jun 2027 |
| 1.35 | 17 Dec 2025 | 28 Feb 2027 |

---

Maintained by [Ravi Kulkarni](https://www.linkedin.com/in/ravisharadkulkarni)
— cloud, DevOps and AI enablement for engineering teams. Riga, Latvia.
[ssktraining.com](https://ssktraining.com)

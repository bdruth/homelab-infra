# Interacting with Gitea Actions via `tea` CLI

When inspecting CI/CD runs at https://gitea.cusack-ruth.name (e.g., to debug
failed workflow runs), use the `tea` CLI rather than browser/curl. The `tea`
binary is installed via Homebrew and already authenticated for `bruth` on
`gitea.cusack-ruth.name`.

## Quirks

- `tea` itself errors with "core.repositoryformatversion does not support
  extension: worktreeconfig" when run from inside this repo's working tree
  (the macOS `homelab-infra` checkout). **Workaround**: `cd /tmp` (or any
  non-git directory) before running `tea` commands.
- `tea actions runs` subcommands fail with "gitea server at ... is older than
  1.26.0". **Workaround**: use `tea api` directly against the REST endpoints.
- The `/actions/jobs/<id>/logs` endpoint **truncates partway through** for
  failed jobs (observed: ~320 lines for a 12-minute Ansible run that should
  have produced thousands). Successful jobs return the complete log. If a
  failed job's log cuts off mid-task, the actual failure may be downstream;
  cross-check with on-host inspection (e.g., container `started_at`
  timestamps) to reconstruct what happened. Offset query params don't help
  — same content regardless of offset.

## Useful commands

List recent workflow runs (run number == what's in the web URL,
`runs/<number>`; the API id is different):

```sh
cd /tmp && tea api "repos/bruth/homelab-infra/actions/runs?limit=10" \
  | python3 -c "import sys,json; [print(r['id'], r['run_number'], r['status'], r.get('conclusion','-'), r['display_title']) for r in json.load(sys.stdin)['workflow_runs']]"
```

(Use `r.get('conclusion','-')` rather than `r['conclusion']` — in_progress
runs don't have the key.)

Translate a web run number to the API id:

```sh
cd /tmp && tea api "repos/bruth/homelab-infra/actions/runs?limit=20" \
  | python3 -c "import sys,json; [print(r['id']) for r in json.load(sys.stdin)['workflow_runs'] if r['run_number']==<NUMBER>]"
```

Get the jobs for a run (use the API id, not the run number):

```sh
cd /tmp && tea api "repos/bruth/homelab-infra/actions/runs/<RUN_API_ID>/jobs" \
  | python3 -c "import sys,json; [print(j['id'],j['name'],j['status'],j['conclusion'],j.get('runner_name','?')) for j in json.load(sys.stdin).get('jobs',[])]"
```

`runner_name` matters: on this gitea instance the runners are named after the
host they live on (e.g., `beelink-gti`, `asrock-nuc`). When debugging an
ansible-driven workflow, knowing which runner ran the job tells you whether
the playbook may have been targeting its own host (see "Bootstrap paradox"
below).

Fetch the log for a job (jobs endpoint is rooted at the repo, not the run):

```sh
cd /tmp && tea api "repos/bruth/homelab-infra/actions/jobs/<JOB_ID>/logs" | tail -200
```

For Ansible-driven workflows, look for `[ERROR]`, `failed=`, `fatal:` markers,
or `exitcode '1'` near the end of the file. If the log appears to end
mid-task, see the truncation note above.

## Why the run number != API id

Gitea's web UI uses a per-repo monotonic `run_number` in the URL
(`/actions/runs/112`), but the REST API uses a globally unique `id`
(`8800` in that example). Always translate first.

## Bootstrap paradox: gitea-act-runner CI

The `gitea-act-runner` role deploys the runner that runs the CI. If the
playbook's `docker compose up -d` task recreates the running container, the
runner dies mid-job and the workflow reports failure even though the
deployment converged successfully (the new container comes up fine seconds
later). Symptoms:

- Job log truncates well before completion (~30s of activity for a multi-min
  job).
- Container `docker inspect ... --format '{{.State.StartedAt}}'` shows it
  restarted *during* the failed run window.
- The container is healthy after the run; container logs show
  "runner: <name> ... declare successfully".

Mitigation already in the role: `docker compose up -d` is gated on
`compose_template.changed`, so no-op runs don't recreate the container.
A genuine config change will still self-destruct on the host running the
job; in that case the workflow status will be a false negative — verify
convergence on-host before treating it as a real failure.

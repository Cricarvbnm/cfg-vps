# Mihomo secrets integration

**Goal:** Deploy the SOPS files in `secrets/cfg-mihomo/`.

**Architecture:** sops-nix owns the server configuration; a oneshot service
replaces the client directory after extracting and preparing a new tree.
Keep plaintext out of the Nix store. Keep Caddy masked during container tests.

- [x] Test client deployment with a smaller tree, empty tree and invalid archive;
  failures must preserve the installed tree.
- [x] Implement the deployment script and declare secrets in `mihomo.nix` and
  `caddy.nix` alongside the services that consume them.
  Server: `/etc/mihomo/config.yaml`, root:mihomo, 0640, restart mihomo on change.
  Archive contents: `/srv/mihomo`, root:caddy, directories 0750 and files 0640.
- [x] Connect startup ordering and secret-change deployment.
- [x] Evaluate both system configurations and test in `tests/environment`, with
  Caddy masked before activation. Check ownership, update behavior and mihomo.

Review focus: failed extraction preserves old files; removed files disappear;
empty client directories work; Caddy has directory traversal permissions;
startup ordering does not introduce a systemd cycle.

Implementation finding: the supplied server file uses SOPS YAML, so use
`format = "yaml"; key = "";` to install the entire decrypted document.
The client archive uses binary format.

Validation: four script tests and ShellCheck pass; default and podman-test builds
pass. Container activation verifies ownership and reads as caddy/mihomo. A smaller
client fixture removes old files without changing mihomo's InvocationID; a server
fixture changes the InvocationID. Caddy remained masked and inactive during all
activations. The original encrypted configuration was restored and the container
stopped after testing.

Review fixes: use Wants+After instead of Requires for consumer dependencies on
SOPS, so unrelated secret installation does not restart those consumers. Retain
the previous client tree if rollback itself fails; the fault-injection test
verifies that the backup survives.

Follow-up: archive structure checks were removed at the user's request. All
services depend on SOPS using Wants+After, including the client deployment unit.

Destination clarification: replace the entire `/srv/mihomo` tree with all tarball
contents, retaining `client/` and any future sibling entries. Deployment must not
depend on the archive containing a `client/` directory. Tests cover sibling
entries, removal of obsolete root entries, and an empty archive.

Module layout: the server secret belongs to `modules/mihomo.nix`; the archive
secret and deployment service belong to `modules/caddy.nix`. The separate config
module was removed. Both rebuilt configurations produce identical store paths
to their versions before this reorganization.

The Caddy module is now a directory: `modules/caddy.nix/default.nix` deploys
Caddy and imports `mihomo-client.nix`, which owns archive deployment and its
Caddy startup dependencies. The flake still imports `./modules/caddy.nix`.

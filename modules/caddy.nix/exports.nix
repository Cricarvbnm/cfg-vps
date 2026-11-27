let
  inherit (import ./shared.nix) state-directory;

  ca = "acme-v02.api.letsencrypt.org-directory";
  domain = "alechron.duckdns.org";
  cert-directory = "${state-directory}/caddy/certificates/${ca}/${domain}";
in
{
  cert = {
    crt = "${cert-directory}/${domain}.crt";
    key = "${cert-directory}/${domain}.key";
  };
}

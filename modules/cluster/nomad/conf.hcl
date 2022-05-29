name = "rrr"
datacenter = "dc1"  # TODO
region = "fmfmf"    # TODO

log_level = "INFO"
log_json = true

data_dir = "/var/lib/nomad/"

/* TODO
advertise {
  # Edit to the private IP address.
  http = "server_ip:4646"
  rpc  = "server_ip:4647"
  serf = "server_ip:4648" # non-default ports may be specified
}
*/

server {
  enabled = true
  bootstrap_expect = server_count
}


job "ethnode" {

  meta {
    run_uuid = "${uuidv4()}"
  }
  
  datacenters = ["dc1"]

  group "ethnode" {

    network {
      mode = "host"

      port "p2p" {
        static = 30303
      }
      port "authrpc" {
        static = 8551
      }
    }

    service {
      provider = "nomad"
      name = "p2p"
      port = "p2p"
      check {
        name     = "p2p"
        type     = "tcp"
        interval = "10s"
        timeout  = "1s"
      }
    }

    service {
      provider = "nomad"
      name     = "authrpc"
      port     = "authrpc"
      check {
        name     = "authrpc"
        type     = "tcp"
        interval = "10s"
        timeout  = "1s"
      }
    }

    task "geth" {
      driver = "raw_exec"

      config {
        command = "/usr/bin/geth" 
        args    = [
          "--authrpc.addr", "localhost",
          "--authrpc.port", "${NOMAD_PORT_authrpc}",
          "--authrpc.vhosts", "localhost",
          "--authrpc.jwtsecret", "/tmp/jwtsecret",
          "--syncmode", "snap",
          "--http",
          "--http.api", "personal,eth,net,web3,txpool",
          "--http.corsdomain", "*"
        ]
      }
    }

    task "lighthouse" {
      driver = "raw_exec"

      config {
        command = "/usr/local/bin/lighthouse" 
        args    = [
          "bn",
          "--network", "mainnet",
          "--execution-endpoint", "http://localhost:${NOMAD_PORT_authrpc}",
          "--execution-jwt", "/tmp/jwtsecret",
          "--checkpoint-sync-url", "https://mainnet.checkpoint.sigp.io",
          "--disable-deposit-contract-sync"
        ]
      }
    }
  }
}
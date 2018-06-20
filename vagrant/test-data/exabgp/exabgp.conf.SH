group flownetmon {
        # Remote peer
        neighbor ${neighbor} {
                hold-time 180;
                # local AS number
                local-as ${local_as};
                # Remote AS number
                peer-as ${peer_as};
                # ID for this ExaBGP router
                router-id ${router_id};
                graceful-restart 1200;
                # Local IP addess which used for connections to this peer
                local-address ${local_addr};
                description "ju3";
        }
        process service-dynamic {
                run /etc/exabgp/runsocat.sh;
        }   
}

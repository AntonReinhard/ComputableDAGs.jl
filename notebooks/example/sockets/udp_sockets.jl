@info "setting up UDP sockets"

# use UDP sockets
socket_prefix = "udp://localhost:"

global close_sockets

@error "UDP does not support PAIR sockets"

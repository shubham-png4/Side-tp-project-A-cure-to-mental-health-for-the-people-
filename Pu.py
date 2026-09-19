import argparse
import re
import subprocess
import scapy.all as scapy


class NetworkToolkit:
    """Core network utility class providing MAC manipulation, IP scanning, and packet sniffing."""

    @staticmethod
    def change_mac(interface: str, new_mac: str) -> bool:
        """Changes the MAC address of a target interface (Linux)."""
        if not re.match(r"^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$", new_mac):
            print("[-] Invalid MAC address format.")
            return False

        print(f"[+] Changing MAC address for {interface} to {new_mac}...")
        try:
            subprocess.run(["ifconfig", interface, "down"], check=True)
            subprocess.run(["ifconfig", interface, "hw", "ether", new_mac], check=True)
            subprocess.run(["ifconfig", interface, "up"], check=True)
            print("[+] MAC address changed successfully.")
            return True
        except subprocess.CalledProcessError:
            print("[-] Failed to change MAC address. Ensure you are running as root.")
            return False

    @staticmethod
    def scan_network(ip_range: str) -> list[dict[str, str]]:
        """Scans a subnet using ARP requests to discover active hosts and their MAC addresses."""
        print(f"[+] Scanning network range: {ip_range}...")
        
        arp_request = scapy.ARP(pdst=ip_range)
        broadcast = scapy.Ether(dst="ff:ff:ff:ff:ff:ff")
        arp_request_broadcast = broadcast / arp_request

        answered_list = scapy.srp(arp_request_broadcast, timeout=2, verbose=False)[0]

        clients = []
        for element in answered_list:
            client_dict = {"ip": element[1].psrc, "mac": element[1].hwsrc}
            clients.append(client_dict)
            
        return clients

    @staticmethod
    def sniff_packets(interface: str = None, filter_str: str = None, count: int = 0):
        """Sniffs incoming/outgoing network packets and extracts header info."""
        print(f"[+] Starting packet sniffer on interface: {interface or 'Default'}...")
        if filter_str:
            print(f"[+] BPF Filter active: '{filter_str}'")
        print("[*] Press Ctrl+C to stop.\n")

        def process_packet(packet):
            if packet.haslayer(scapy.IP):
                ip_src = packet[scapy.IP].src
                ip_dst = packet[scapy.IP].dst
                proto = packet[scapy.IP].proto

                info = f"[IP] {ip_src} -> {ip_dst} | Protocol: {proto}"
                
                if packet.haslayer(scapy.TCP):
                    info += f" | TCP Port: {packet[scapy.TCP].sport} -> {packet[scapy.TCP].dport}"
                elif packet.haslayer(scapy.UDP):
                    info += f" | UDP Port: {packet[scapy.UDP].sport} -> {packet[scapy.UDP].dport}"

                print(info)

        scapy.sniff(iface=interface, filter=filter_str, store=False, prn=process_packet, count=count)


def main():
    parser = argparse.ArgumentParser(description="Multi-functional Python Network Toolkit")
    subparsers = parser.add_subparsers(dest="mode", help="Modes of operation")

    # Mode 1: MAC Changer
    mac_parser = subparsers.add_parser("mac", help="Change your MAC address (Linux)")
    mac_parser.add_argument("-i", "--interface", required=True, help="Network interface (e.g., eth0, wlan0)")
    mac_parser.add_argument("-m", "--mac", required=True, help="New MAC address (e.g., 00:11:22:33:44:55)")

    # Mode 2: Network Scanner
    scan_parser = subparsers.add_parser("scan", help="Scan a network using ARP")
    scan_parser.add_argument("-r", "--range", required=True, help="IP target or range (e.g., 192.168.1.1/24)")

    # Mode 3: Packet Sniffer
    sniff_parser = subparsers.add_parser("sniff", help="Sniff traffic on a network interface")
    sniff_parser.add_argument("-i", "--interface", help="Target interface to listen on")
    sniff_parser.add_argument("-f", "--filter", help="BPF filter (e.g., 'tcp', 'udp port 53', 'ip src 192.168.1.1')")
    sniff_parser.add_argument("-c", "--count", type=int, default=0, help="Number of packets to capture (0 for infinite)")

    args = parser.parse_args()

    if args.mode == "mac":
        NetworkToolkit.change_mac(args.interface, args.mac)

    elif args.mode == "scan":
        results = NetworkToolkit.scan_network(args.range)
        print("\nIP Address\t\tMAC Address")
        print("-----------------------------------------")
        for client in results:
            print(f"{client['ip']}\t\t{client['mac']}")

    elif args.mode == "sniff":
        try:
            NetworkToolkit.sniff_packets(interface=args.interface, filter_str=args.filter, count=args.count)
        except KeyboardInterrupt:
            print("\n[+] Sniffer stopped.")
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
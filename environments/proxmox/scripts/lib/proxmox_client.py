#!/usr/bin/env python3
"""
Proxmox API Client Library
Provides high-level wrappers for common Proxmox operations
"""

import os
import sys
from typing import List, Dict, Optional, Any
from proxmoxer import ProxmoxAPI
from proxmoxer.core import ResourceException
import json


class ProxmoxClient:
    """High-level Proxmox API client"""

    def __init__(self, host: str = None, user: str = None,
                 token_name: str = None, token_value: str = None,
                 verify_ssl: bool = False):
        """
        Initialize Proxmox client with API token authentication

        Args:
            host: Proxmox host (or PROXMOX_HOST env var)
            user: API user (or PROXMOX_USER env var)
            token_name: API token name (or PROXMOX_TOKEN_NAME env var)
            token_value: API token value (or PROXMOX_TOKEN_VALUE env var)
            verify_ssl: Verify SSL certificates (default: False)
        """
        self.host = host or os.getenv('PROXMOX_HOST')
        self.user = user or os.getenv('PROXMOX_USER')
        self.token_name = token_name or os.getenv('PROXMOX_TOKEN_NAME')
        self.token_value = token_value or os.getenv('PROXMOX_TOKEN_VALUE')

        if not all([self.host, self.user, self.token_name, self.token_value]):
            raise ValueError(
                "Missing required credentials. Set PROXMOX_HOST, PROXMOX_USER, "
                "PROXMOX_TOKEN_NAME, and PROXMOX_TOKEN_VALUE environment variables."
            )

        self.proxmox = ProxmoxAPI(
            self.host,
            user=self.user,
            token_name=self.token_name,
            token_value=self.token_value,
            verify_ssl=verify_ssl
        )

    # ===== NODE OPERATIONS =====

    def get_nodes(self) -> List[Dict]:
        """Get list of all nodes in the cluster"""
        try:
            return self.proxmox.nodes.get()
        except ResourceException as e:
            print(f"Error getting nodes: {e}", file=sys.stderr)
            return []

    def get_node_status(self, node: str) -> Dict:
        """Get status of a specific node"""
        try:
            return self.proxmox.nodes(node).status.get()
        except ResourceException as e:
            print(f"Error getting node status: {e}", file=sys.stderr)
            return {}

    def get_node_version(self, node: str) -> Dict:
        """Get version information for a node"""
        try:
            return self.proxmox.nodes(node).version.get()
        except ResourceException as e:
            print(f"Error getting node version: {e}", file=sys.stderr)
            return {}

    # ===== VM OPERATIONS =====

    def get_vms(self, node: str = None) -> List[Dict]:
        """Get list of all VMs, optionally filtered by node"""
        vms = []
        nodes = [node] if node else [n['node'] for n in self.get_nodes()]

        for n in nodes:
            try:
                node_vms = self.proxmox.nodes(n).qemu.get()
                for vm in node_vms:
                    vm['node'] = n
                vms.extend(node_vms)
            except ResourceException as e:
                print(f"Error getting VMs from node {n}: {e}", file=sys.stderr)

        return vms

    def get_vm(self, node: str, vmid: int) -> Dict:
        """Get details of a specific VM"""
        try:
            return self.proxmox.nodes(node).qemu(vmid).status.current.get()
        except ResourceException as e:
            print(f"Error getting VM {vmid}: {e}", file=sys.stderr)
            return {}

    def start_vm(self, node: str, vmid: int) -> Dict:
        """Start a VM"""
        try:
            return self.proxmox.nodes(node).qemu(vmid).status.start.post()
        except ResourceException as e:
            print(f"Error starting VM {vmid}: {e}", file=sys.stderr)
            return {}

    def stop_vm(self, node: str, vmid: int) -> Dict:
        """Stop a VM"""
        try:
            return self.proxmox.nodes(node).qemu(vmid).status.stop.post()
        except ResourceException as e:
            print(f"Error stopping VM {vmid}: {e}", file=sys.stderr)
            return {}

    def shutdown_vm(self, node: str, vmid: int) -> Dict:
        """Gracefully shutdown a VM"""
        try:
            return self.proxmox.nodes(node).qemu(vmid).status.shutdown.post()
        except ResourceException as e:
            print(f"Error shutting down VM {vmid}: {e}", file=sys.stderr)
            return {}

    def reboot_vm(self, node: str, vmid: int) -> Dict:
        """Reboot a VM"""
        try:
            return self.proxmox.nodes(node).qemu(vmid).status.reboot.post()
        except ResourceException as e:
            print(f"Error rebooting VM {vmid}: {e}", file=sys.stderr)
            return {}

    def reset_vm(self, node: str, vmid: int) -> Dict:
        """Reset (hard reboot) a VM"""
        try:
            return self.proxmox.nodes(node).qemu(vmid).status.reset.post()
        except ResourceException as e:
            print(f"Error resetting VM {vmid}: {e}", file=sys.stderr)
            return {}

    def suspend_vm(self, node: str, vmid: int) -> Dict:
        """Suspend a VM"""
        try:
            return self.proxmox.nodes(node).qemu(vmid).status.suspend.post()
        except ResourceException as e:
            print(f"Error suspending VM {vmid}: {e}", file=sys.stderr)
            return {}

    def resume_vm(self, node: str, vmid: int) -> Dict:
        """Resume a suspended VM"""
        try:
            return self.proxmox.nodes(node).qemu(vmid).status.resume.post()
        except ResourceException as e:
            print(f"Error resuming VM {vmid}: {e}", file=sys.stderr)
            return {}

    def delete_vm(self, node: str, vmid: int, purge: bool = False) -> Dict:
        """Delete a VM"""
        try:
            params = {'purge': 1} if purge else {}
            return self.proxmox.nodes(node).qemu(vmid).delete(**params)
        except ResourceException as e:
            print(f"Error deleting VM {vmid}: {e}", file=sys.stderr)
            return {}

    def clone_vm(self, node: str, vmid: int, newid: int, name: str = None,
                 full: bool = True, target: str = None) -> Dict:
        """Clone a VM"""
        try:
            params = {
                'newid': newid,
                'full': 1 if full else 0
            }
            if name:
                params['name'] = name
            if target:
                params['target'] = target

            return self.proxmox.nodes(node).qemu(vmid).clone.post(**params)
        except ResourceException as e:
            print(f"Error cloning VM {vmid}: {e}", file=sys.stderr)
            return {}

    def create_vm(self, node: str, vmid: int, **kwargs) -> Dict:
        """
        Create a new VM

        Common kwargs:
            name: VM name
            memory: RAM in MB
            cores: CPU cores
            sockets: CPU sockets
            ostype: OS type (l26 for Linux 2.6+)
            net0: Network config (e.g., 'virtio,bridge=vmbr0')
            ide2: ISO image (e.g., 'local:iso/debian.iso,media=cdrom')
            scsi0: Disk config (e.g., 'local-lvm:32,format=qcow2')
        """
        try:
            params = {'vmid': vmid, **kwargs}
            return self.proxmox.nodes(node).qemu.post(**params)
        except ResourceException as e:
            print(f"Error creating VM: {e}", file=sys.stderr)
            return {}

    def get_vm_config(self, node: str, vmid: int) -> Dict:
        """Get VM configuration"""
        try:
            return self.proxmox.nodes(node).qemu(vmid).config.get()
        except ResourceException as e:
            print(f"Error getting VM config: {e}", file=sys.stderr)
            return {}

    def update_vm_config(self, node: str, vmid: int, **kwargs) -> Dict:
        """Update VM configuration"""
        try:
            return self.proxmox.nodes(node).qemu(vmid).config.put(**kwargs)
        except ResourceException as e:
            print(f"Error updating VM config: {e}", file=sys.stderr)
            return {}

    # ===== SNAPSHOT OPERATIONS =====

    def get_snapshots(self, node: str, vmid: int) -> List[Dict]:
        """Get list of snapshots for a VM"""
        try:
            return self.proxmox.nodes(node).qemu(vmid).snapshot.get()
        except ResourceException as e:
            print(f"Error getting snapshots: {e}", file=sys.stderr)
            return []

    def create_snapshot(self, node: str, vmid: int, snapname: str,
                       description: str = None, vmstate: bool = False) -> Dict:
        """Create a VM snapshot"""
        try:
            params = {
                'snapname': snapname,
                'vmstate': 1 if vmstate else 0
            }
            if description:
                params['description'] = description

            return self.proxmox.nodes(node).qemu(vmid).snapshot.post(**params)
        except ResourceException as e:
            print(f"Error creating snapshot: {e}", file=sys.stderr)
            return {}

    def delete_snapshot(self, node: str, vmid: int, snapname: str) -> Dict:
        """Delete a VM snapshot"""
        try:
            return self.proxmox.nodes(node).qemu(vmid).snapshot(snapname).delete()
        except ResourceException as e:
            print(f"Error deleting snapshot: {e}", file=sys.stderr)
            return {}

    def rollback_snapshot(self, node: str, vmid: int, snapname: str) -> Dict:
        """Rollback to a snapshot"""
        try:
            return self.proxmox.nodes(node).qemu(vmid).snapshot(snapname).rollback.post()
        except ResourceException as e:
            print(f"Error rolling back snapshot: {e}", file=sys.stderr)
            return {}

    # ===== STORAGE OPERATIONS =====

    def get_storage(self, node: str = None) -> List[Dict]:
        """Get list of storage resources"""
        try:
            if node:
                return self.proxmox.nodes(node).storage.get()
            else:
                return self.proxmox.storage.get()
        except ResourceException as e:
            print(f"Error getting storage: {e}", file=sys.stderr)
            return []

    def get_storage_content(self, node: str, storage: str, content: str = None) -> List[Dict]:
        """Get content of a storage location"""
        try:
            params = {'content': content} if content else {}
            return self.proxmox.nodes(node).storage(storage).content.get(**params)
        except ResourceException as e:
            print(f"Error getting storage content: {e}", file=sys.stderr)
            return []

    def get_storage_status(self, node: str, storage: str) -> Dict:
        """Get status of a storage location"""
        try:
            return self.proxmox.nodes(node).storage(storage).status.get()
        except ResourceException as e:
            print(f"Error getting storage status: {e}", file=sys.stderr)
            return {}

    # ===== CONTAINER (LXC) OPERATIONS =====

    def get_containers(self, node: str = None) -> List[Dict]:
        """Get list of all containers"""
        containers = []
        nodes = [node] if node else [n['node'] for n in self.get_nodes()]

        for n in nodes:
            try:
                node_cts = self.proxmox.nodes(n).lxc.get()
                for ct in node_cts:
                    ct['node'] = n
                containers.extend(node_cts)
            except ResourceException as e:
                print(f"Error getting containers from node {n}: {e}", file=sys.stderr)

        return containers

    def get_container(self, node: str, vmid: int) -> Dict:
        """Get details of a specific container"""
        try:
            return self.proxmox.nodes(node).lxc(vmid).status.current.get()
        except ResourceException as e:
            print(f"Error getting container {vmid}: {e}", file=sys.stderr)
            return {}

    def start_container(self, node: str, vmid: int) -> Dict:
        """Start a container"""
        try:
            return self.proxmox.nodes(node).lxc(vmid).status.start.post()
        except ResourceException as e:
            print(f"Error starting container {vmid}: {e}", file=sys.stderr)
            return {}

    def stop_container(self, node: str, vmid: int) -> Dict:
        """Stop a container"""
        try:
            return self.proxmox.nodes(node).lxc(vmid).status.stop.post()
        except ResourceException as e:
            print(f"Error stopping container {vmid}: {e}", file=sys.stderr)
            return {}

    def shutdown_container(self, node: str, vmid: int) -> Dict:
        """Gracefully shutdown a container"""
        try:
            return self.proxmox.nodes(node).lxc(vmid).status.shutdown.post()
        except ResourceException as e:
            print(f"Error shutting down container {vmid}: {e}", file=sys.stderr)
            return {}

    # ===== TASK OPERATIONS =====

    def get_tasks(self, node: str, limit: int = 50) -> List[Dict]:
        """Get list of tasks for a node"""
        try:
            return self.proxmox.nodes(node).tasks.get(limit=limit)
        except ResourceException as e:
            print(f"Error getting tasks: {e}", file=sys.stderr)
            return []

    def get_task_status(self, node: str, upid: str) -> Dict:
        """Get status of a specific task"""
        try:
            return self.proxmox.nodes(node).tasks(upid).status.get()
        except ResourceException as e:
            print(f"Error getting task status: {e}", file=sys.stderr)
            return {}

    # ===== NETWORK OPERATIONS =====

    def get_network(self, node: str) -> List[Dict]:
        """Get network configuration for a node"""
        try:
            return self.proxmox.nodes(node).network.get()
        except ResourceException as e:
            print(f"Error getting network config: {e}", file=sys.stderr)
            return []

    # ===== TEMPLATE OPERATIONS =====

    def create_template(self, node: str, vmid: int) -> Dict:
        """Convert a VM to a template"""
        try:
            return self.proxmox.nodes(node).qemu(vmid).template.post()
        except ResourceException as e:
            print(f"Error creating template: {e}", file=sys.stderr)
            return {}

    def get_vm_agent_network(self, node: str, vmid: int) -> List[Dict]:
        """Get network information from QEMU guest agent"""
        try:
            result = self.proxmox.nodes(node).qemu(vmid).agent('network-get-interfaces').get()
            return result.get('result', [])
        except ResourceException as e:
            # Agent not running or not installed
            return []

    def get_vm_ip_address(self, node: str, vmid: int) -> Optional[str]:
        """
        Get IP address of a VM using multiple methods

        Tries in order:
        1. QEMU guest agent network info
        2. Current status (if agent reports it)
        3. Returns None if unable to determine

        Args:
            node: Proxmox node name
            vmid: VM ID

        Returns:
            IP address as string, or None if not found
        """
        # Method 1: Try guest agent network info
        try:
            interfaces = self.get_vm_agent_network(node, vmid)
            for iface in interfaces:
                # Skip loopback
                if iface.get('name') in ['lo', 'lo0']:
                    continue

                # Look for IPv4 addresses
                ip_addresses = iface.get('ip-addresses', [])
                for ip_info in ip_addresses:
                    if ip_info.get('ip-address-type') == 'ipv4':
                        ip = ip_info.get('ip-address')
                        # Skip localhost
                        if ip and not ip.startswith('127.'):
                            return ip
        except:
            pass

        # Method 2: Check current VM status
        try:
            status = self.get_vm(node, vmid)
            # Some Proxmox setups report agent IP in status
            if 'agent-netinfo' in status:
                # Parse agent network info if available
                pass
        except:
            pass

        return None

    # ===== HELPER METHODS =====

    def find_vm_by_name(self, name: str) -> Optional[Dict]:
        """Find a VM by name"""
        for vm in self.get_vms():
            if vm.get('name') == name:
                return vm
        return None

    def find_vm(self, identifier: str) -> Optional[Dict]:
        """Find a VM by vmid or name"""
        vms = self.get_vms()
        # Try as vmid first
        try:
            vmid = int(identifier)
            for vm in vms:
                if vm.get('vmid') == vmid:
                    return vm
        except ValueError:
            pass
        # Try as name
        for vm in vms:
            if vm.get('name') == identifier:
                return vm
        return None

    def find_container_by_name(self, name: str) -> Optional[Dict]:
        """Find a container by name"""
        for ct in self.get_containers():
            if ct.get('name') == name:
                return ct
        return None

    def wait_for_task(self, node: str, upid: str, timeout: int = 300) -> bool:
        """Wait for a task to complete"""
        import time
        elapsed = 0
        interval = 2

        while elapsed < timeout:
            status = self.get_task_status(node, upid)
            if status.get('status') == 'stopped':
                return status.get('exitstatus') == 'OK'
            time.sleep(interval)
            elapsed += interval

        return False


def get_client() -> ProxmoxClient:
    """Factory function to create a ProxmoxClient instance"""
    return ProxmoxClient()

#!/usr/bin/env python3
"""
Script to populate Prover.toml from inputs.json
"""

import json
import os

def format_array(arr):
    """Format an array as a TOML array string"""
    return '[' + ', '.join(f'"{item}"' for item in arr) + ']'

def format_nested_section(data, indent=0):
    """Format a nested section like body or header"""
    lines = []
    prefix = '  ' * indent
    
    if 'len' in data:
        lines.append(f'{prefix}len = "{data["len"]}"')
    if 'storage' in data:
        storage_str = format_array(data['storage'])
        lines.append(f'{prefix}storage = {storage_str}')
    if 'index' in data:
        lines.append(f'{prefix}index = "{data["index"]}"')
    if 'length' in data:
        lines.append(f'{prefix}length = "{data["length"]}"')
    
    return lines

def generate_prover_toml(input_data, output_path):
    """Generate Prover.toml from parsed input data"""
    
    lines = []
    
    # Top-level simple fields
    lines.append(f'body_hash_index = "{input_data["body_hash_index"]}"')
    lines.append(f'command = {format_array(input_data["command"])}')
    lines.append(f'partial_body_hash = {format_array(input_data["partial_body_hash"])}')
    lines.append(f'partial_body_real_length = "{input_data["partial_body_real_length"]}"')
    lines.append(f'prover_address = {format_array(input_data["prover_address"])}')
    
    # Sender domain fields
    lines.append(f'sender_domain_capture_group_1_id = {format_array(input_data["sender_domain_capture_group_1_id"])}')
    lines.append(f'sender_domain_capture_group_1_start = {format_array(input_data["sender_domain_capture_group_1_start"])}')
    lines.append(f'sender_domain_capture_group_start_indices = {format_array(input_data["sender_domain_capture_group_start_indices"])}')
    lines.append(f'sender_domain_current_states = {format_array(input_data["sender_domain_current_states"])}')
    lines.append(f'sender_domain_match_length = "{input_data["sender_domain_match_length"]}"')
    lines.append(f'sender_domain_match_start = "{input_data["sender_domain_match_start"]}"')
    lines.append(f'sender_domain_next_states = {format_array(input_data["sender_domain_next_states"])}')
    
    # Signature
    lines.append(f'signature = {format_array(input_data["signature"])}')
    
    # X handle fields
    lines.append(f'x_handle_capture_group_1_id = {format_array(input_data["x_handle_capture_group_1_id"])}')
    lines.append(f'x_handle_capture_group_1_start = {format_array(input_data["x_handle_capture_group_1_start"])}')
    lines.append(f'x_handle_capture_group_start_indices = {format_array(input_data["x_handle_capture_group_start_indices"])}')
    lines.append(f'x_handle_current_states = {format_array(input_data["x_handle_current_states"])}')
    lines.append(f'x_handle_match_length = "{input_data["x_handle_match_length"]}"')
    lines.append(f'x_handle_match_start = "{input_data["x_handle_match_start"]}"')
    lines.append(f'x_handle_next_states = {format_array(input_data["x_handle_next_states"])}')
    
    # Body section
    lines.append('')
    lines.append('[body]')
    lines.extend(format_nested_section(input_data['body']))
    
    # Decoded body section
    lines.append('')
    lines.append('[decoded_body]')
    lines.extend(format_nested_section(input_data['decoded_body']))
    
    # DKIM header sequence section
    lines.append('')
    lines.append('[dkim_header_sequence]')
    lines.extend(format_nested_section(input_data['dkim_header_sequence']))
    
    # Header section
    lines.append('')
    lines.append('[header]')
    lines.extend(format_nested_section(input_data['header']))
    
    # Pubkey section
    lines.append('')
    lines.append('[pubkey]')
    lines.append(f'modulus = {format_array(input_data["pubkey"]["modulus"])}')
    lines.append(f'redc = {format_array(input_data["pubkey"]["redc"])}')
    
    # Write to file
    with open(output_path, 'w') as f:
        f.write('\n'.join(lines) + '\n')
    
    print(f"✓ Successfully generated {output_path}")

def main():
    # Get the directory where this script is located
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Paths relative to script location
    inputs_path = os.path.join(script_dir, 'inputs.json')
    output_path = os.path.join(script_dir, 'Prover.toml')
    
    # Load the inputs.json file
    print(f"Reading from {inputs_path}...")
    with open(inputs_path, 'r') as f:
        data = json.load(f)
    
    # Parse the nested JSON string in the "input" field
    input_data = json.loads(data['input'])
    
    # Generate the Prover.toml file
    print(f"Generating {output_path}...")
    generate_prover_toml(input_data, output_path)

if __name__ == '__main__':
    main()


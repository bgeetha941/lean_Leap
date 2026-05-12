import os
import json
import shutil
import urllib.parse
from pathlib import Path

# Paths
history_dir = Path(os.path.expanduser('~')) / 'AppData' / 'Roaming' / 'Code' / 'User' / 'History'
target_base_dir = Path(r'C:\Users\HP\one\frontend')

# Ensure target exists
os.makedirs(target_base_dir / 'lib', exist_ok=True)

recovered_files = {}

if history_dir.exists():
    for dirpath, dirnames, filenames in os.walk(history_dir):
        if 'entries.json' in filenames:
            entries_path = Path(dirpath) / 'entries.json'
            try:
                with open(entries_path, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                
                resource = data.get('resource', '')
                # Unquote the URL-encoded path
                unquoted_resource = urllib.parse.unquote(resource)
                
                # Check if it belongs to our missing frontend folder
                if 'one/frontend' in unquoted_resource or 'one\\frontend' in unquoted_resource:
                    entries = data.get('entries', [])
                    if not entries:
                        continue
                    
                    # Sort by timestamp descending
                    entries.sort(key=lambda x: x.get('timestamp', 0), reverse=True)
                    latest_entry = entries[0]
                    file_id = latest_entry.get('id')
                    
                    source_file = Path(dirpath) / file_id
                    
                    if source_file.exists():
                        # Extract the relative path after 'frontend/'
                        try:
                            # Normalize path separators
                            normalized_res = unquoted_resource.replace('\\', '/')
                            parts = normalized_res.split('one/frontend/')
                            if len(parts) > 1:
                                rel_path = parts[1]
                                
                                # Sometimes files have file:/// prefix or similar
                                if rel_path.startswith('/'):
                                    rel_path = rel_path[1:]
                                
                                dest_file = target_base_dir / rel_path
                                
                                # We only want the most recent version of each file across all history entries
                                timestamp = latest_entry.get('timestamp', 0)
                                if rel_path not in recovered_files or recovered_files[rel_path]['timestamp'] < timestamp:
                                    recovered_files[rel_path] = {
                                        'source': source_file,
                                        'dest': dest_file,
                                        'timestamp': timestamp
                                    }
                        except Exception as e:
                            print(f"Error parsing path {unquoted_resource}: {e}")
            except Exception as e:
                pass

print(f"Found {len(recovered_files)} files to recover!")

for rel_path, info in recovered_files.items():
    dest = info['dest']
    os.makedirs(dest.parent, exist_ok=True)
    shutil.copy2(info['source'], dest)
    print(f"Recovered: {rel_path}")

# Run flutter create if pubspec.yaml wasn't recovered
if not (target_base_dir / 'pubspec.yaml').exists():
    print("\npubspec.yaml not found in history. Initializing flutter project structure to make lib/ run...")
    os.system(f"cd {target_base_dir} && flutter create . --org com.leanleap.app")

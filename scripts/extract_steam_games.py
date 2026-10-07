#!/usr/bin/env python3
import os
import re
import json
import sys

def get_steam_games():
    steam_roots = [
        os.path.expanduser("~/.steam/steam"),
        os.path.expanduser("~/.local/share/Steam"),
        os.path.expanduser("~/.var/app/com.valvesoftware.Steam/data/Steam")
    ]
    
    # Extract additional library folders from libraryfolders.vdf
    additional_roots = set()
    for root in steam_roots:
        vdf_path = os.path.join(root, "steamapps", "libraryfolders.vdf")
        if os.path.isfile(vdf_path):
            try:
                with open(vdf_path, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()
                    matches = re.findall(r'"path"\s+"([^"]+)"', content)
                    for match in matches:
                        additional_roots.add(match)
            except Exception as e:
                print(f"Error parsing {vdf_path}: {e}", file=sys.stderr)
                
    for r in additional_roots:
        if r not in steam_roots:
            steam_roots.append(r)
            
    # Gather all possible librarycache paths (banners are usually kept in main installation folders)
    cache_dirs = []
    for root in steam_roots:
        cache_path = os.path.join(root, "appcache", "librarycache")
        if os.path.isdir(cache_path):
            cache_dirs.append(cache_path)
    
    apps = []
    seen_ids = set()
    
    for root in steam_roots:
        steamapps = os.path.join(root, "steamapps")
        librarycache = os.path.join(root, "appcache", "librarycache")
        
        if not os.path.isdir(steamapps):
            continue
            
        for file in os.listdir(steamapps):
            if file.startswith("appmanifest_") and file.endswith(".acf"):
                filepath = os.path.join(steamapps, file)
                try:
                    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                        content = f.read()
                        
                        appid_match = re.search(r'"appid"\s+"(\d+)"', content)
                        name_match = re.search(r'"name"\s+"([^"]+)"', content)
                        
                        if appid_match and name_match:
                            appid = appid_match.group(1)
                            name = name_match.group(1)
                            
                            # Skip common redistributables and duplicates
                            if appid == "228980" or appid in seen_ids:
                                continue
                                
                            seen_ids.add(appid)
                            banner_path = ""
                            for librarycache in cache_dirs:
                                if banner_path:
                                    break
                                # Steam uses subdirectories named after the appid for caching now
                                app_cache_dir = os.path.join(librarycache, appid)
                                
                                # Typical vertical banners (600x900)
                                if os.path.isdir(app_cache_dir):
                                    best_banner = ""
                                    for root_dir, _, files in os.walk(app_cache_dir):
                                        for f in files:
                                            if "600x900" in f or "capsule" in f:
                                                best_banner = os.path.join(root_dir, f)
                                                break
                                    
                                    if best_banner:
                                        banner_path = best_banner
                                else:
                                    # Fallback to old flat structure just in case
                                    variants = [
                                        os.path.join(librarycache, f"{appid}_library_600x900.jpg"),
                                        os.path.join(librarycache, f"{appid}_library_600x900.png"),
                                        os.path.join(librarycache, f"{appid}p.jpg"),
                                        os.path.join(librarycache, f"{appid}p.png")
                                    ]
                                    for bp in variants:
                                        if os.path.exists(bp):
                                            banner_path = bp
                                            break
                            
                            apps.append({
                                "id": appid,
                                "name": name,
                                "banner": banner_path,
                                "command": f"hyprctl dispatch exec '[workspace unset] steam -silent -applaunch {appid}'"
                            })
                except Exception as e:
                    print(f"Error parsing {file}: {e}", file=sys.stderr)
                    pass
                    
    # Sort alphabetically by name
    apps.sort(key=lambda x: x["name"].lower())
    
    out_dir = os.path.expanduser("~/.cache/quickshell")
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, "steam_games.json")
    
    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump(apps, f, indent=4)
        
    print(f"Extracted {len(apps)} steam games to {out_path}")

if __name__ == "__main__":
    get_steam_games()

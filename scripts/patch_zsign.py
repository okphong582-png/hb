import os

pkg_file = os.path.join("Zsign", "Package.swift")
if os.path.exists(pkg_file):
    with open(pkg_file, "r", encoding="utf-8") as f:
        content = f.read()
    
    # Ensure Zsign library product includes both Zsign and ZsignC
    if 'targets: ["Zsign"]' in content:
        content = content.replace('targets: ["Zsign"]', 'targets: ["Zsign", "ZsignC"]')
        with open(pkg_file, "w", encoding="utf-8") as f:
            f.write(content)
        print("Patched Zsign/Package.swift successfully.")
    else:
        print("targets: [\"Zsign\"] not found or already patched.")

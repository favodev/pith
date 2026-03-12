import urllib.request
import re

url = "https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ7Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpaCiVodG1sXzNlY2YxMjM1YjcwMTQxYzBiODFmOTI0ZDZiZmVlMzc2EgsSBxC5otad2gcYAZIBIwoKcHJvamVjdF9pZBIVQhM4ODMwOTcwODEwNzA1OTIwNDI0&filename=&opi=89354086"
req = urllib.request.Request(url)
with urllib.request.urlopen(req) as response:
    html = response.read().decode('utf-8')
    
    # Extract structural style colors
    colors = re.findall(r'color:\s*([^;]+);|background(?:-color)?:\s*([^;]+);|border(?:-color)?:\s*([^;]+);', html)
    
    unique_colors = set()
    for match in colors:
        for c in match:
            if c:
                # Basic cleanup
                clean_c = c.strip().lower()
                if "rgb" in clean_c or "#" in clean_c:
                    unique_colors.add(clean_c)
                    
    print("Found colors in Stitch HTML:")
    for c in sorted(unique_colors):
        print(c)

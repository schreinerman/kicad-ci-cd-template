# kicad-ci-cd-template

CI/CD Pipeline Template for running KiCAD build processes

Run build.sh to...
```
./build.sh prepare      - Prepare for build
./build.sh schematic    - Build schematic artifacts only
./build.sh bom          - Build bill of materials artifacts only
./build.sh gerber       - Build gerber artifacts only
./build.sh cad          - Build 3D files only
./build.sh housing      - Build housing files only 
./build.sh docker       - build all using docker
./build.sh              - build all
```

Run Docker Compose...
```
docker compose up
```

# License
Created by Manuel Schreiner

Copyright © 2025 io-expert.com. All rights reserved.

Redistributions of source code must retain the above copyright notice, this condition and the following disclaimer.
This software is provided by the copyright holder and contributors "AS IS" and any warranties related to this software are DISCLAIMED. The copyright owner or contributors be NOT LIABLE for any damages caused by use of this software.
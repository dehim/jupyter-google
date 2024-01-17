Ubuntu-noVNC
-------------------------------
```
docker run -d -p 80:80 \
    -v /var/shareVolumes/Ubuntu-noVNC:/shareVolume \
    --name Ubuntu-noVNC \
    --restart=always \
    dehim/ubuntu-noVNC:tagname
```

### `mv /shareVolume_demo/* /shareVolume/`, then restart container, enjoy it!
### default password: 1234, `x11vnc -storepasswd 1234 /root/.vnc/passwd` to reset noVNC password.
### Jupyter: http://127.0.0.1:8888, `jupyter notebook list` to get token, and set`jupyter notebook password` to reset password.

- 3.10.12.6
  - 将vnpy一些依赖库前置到noVNC，用于独立在jupyter调试

- 3.10.12.5
  - add xlrd

- 3.10.12.4
  - add openpyxl

- 3.10.12.1
  - add selenium, chromium-browser, chromium-chromedriver

- 3.7.12
  - PYTHON_VERSION='3.7.12'

- 3.10.2.6
  - ln -s /usr/share/zoneinfo/Asia/Shanghai localtime

- 3.10.2.7
  - update pip 

- 3.8.10.1
  - add apt-utils dialog
  - update pip 

- 3.8.10.2
  - add python3-dev

- 3.8.10.3
  - add ta-lib

- 3.8.10.5
  - add cmake 

- 3.10.7.0
  - PYTHON_VERSION='3.10.7'
  - xterm-372 -> xterm-373

- 3.10.8.0
  - PYTHON_VERSION='3.10.8'

- 3.10.6.x
  - FROM ubuntu:22.04
  
  
- 2021.06.08
  - update pandas
  - supervisorctl '4.2.1' -> '4.2.2' 

- 2021.06.12
  - make fluxbox init & menu better

- 2021.07.03
  - add hdparm lshw dmidecode 
  - numpy '1.20.1' -> '1.20.3'

- 2021.07.07
  - add Consolas.ttf

- 2021.08.12
  - add thunar-4.16


- 2021.08.13
  - add mousepad

- 2021.10.01
  - from ubuntu 20.04
  - SQLITE_VERSION='3.35.0' -> '3.36.0';

- 2021.10.27
  - PYTHON_VERSION='3.7.9' -> '3.7.12';

- 2021.11.01
  - add dmidecode

- 2021.11.28
  - add sg3_utils

- 2022.01.18
  - add udev

- 2022.01.23
  - add samba-4.15.4

- 2022.02.28
  - PYTHON_VERSION='3.7.12' -> '3.10.2';

- 2022.03.01
  - CURL_VERSION='7.78.0'



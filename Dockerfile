FROM ubuntu:22.04

LABEL maintainer="dehim"

#避免安装过程弹出框
ENV DEBIAN_FRONTEND='noninteractive' 

RUN \
    NGINX_VERSION='1.24.0'; \
    NGX_CACHE_PURGE_VERSION='2.3'; \
    XRAY_VERSION='1.8.7'; \
    if [ "$(uname -m)" = "aarch64" ]; then export ARCH=arm64 && X_ARCH=arm64-v8a && BUILDTYPE=aarch64; fi \
    && if [ "$(uname -m)" = "x86_64" ]; then export ARCH=amd64 && X_ARCH=64 && BUILDTYPE=x86_64; fi \
    && apt-get update \
    && apt-get install -y \
        pkg-config \
        # 添加apt-key时需要
        gnupg2 \
        # 装中文包后，locale -a才有zh_cn.utf8
        locales language-pack-zh-hans \
        # Python.h: No such file or directory
        libpython3.10-dev \
        # libxcb-render-util.so.0: 无法打开共享对象文件: 没有那个文件或目录
        libxcb-render-util0-dev \
        # libxcb-keysyms.so.1: 无法打开共享对象文件: 没有那个文件或目录
        libxcb-keysyms1-dev \
        # libxcb-image.so.0: 无法打开共享对象文件: 没有那个文件或目录
        libxcb-image0-dev \
        # libxcb-icccm.so.4: 无法打开共享对象文件: 没有那个文件或目录
        libxcb-icccm4-dev \
        # libxkbcommon-x11.so.0: 无法打开共享对象文件: 没有那个文件或目录
        libxkbcommon-x11-dev \
        # libQt6Pdf.so.6: 无法打开共享对象文件: 没有那个文件或目录)
        libqt6pdf6 \
        # vnpy 3.7.0开始需要依赖 libxcb-randr0-dev
        libxcb-randr0-dev \
        # nginx 需要
        libpcre3 libpcre3-dev libxml2-dev libxslt-dev libgd-dev libgeoip-dev gettext-base \
        git x11vnc xvfb vim tzdata sudo dmidecode libsqlite3-dev libssl-dev unzip \
        apt-utils fluxbox dialog iputils-ping wget build-essential supervisor curl \

        # chromium-browser chromium-chromedriver \
        # 镜像jupyter需要依赖,但不必装z3 ocaml，装了没用，依然是Could NOT find OCaml
        # cmake ninja-build \

    # 开发图形界面需要，目前不支持ARM
    # selenium 模拟打开网页，依赖 chromium-browser chromium-chromedriver，arm64有部分包缺失
    #  && if [ "$(uname -m)" = "x86_64" ]; then apt-get install -y libmfx-dev chromium-browser chromium-chromedriver; fi \
     && if [ "$(uname -m)" = "x86_64" ]; then \
        apt-get install -y \
        libmfx-dev && \
        # cd /usr/src && \
        # wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
        # apt install -y ./google-chrome-stable_current_amd64.deb && \
        rm -rf /usr/src/* ; \
        fi \

                          
    # && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 871920D1991BC93C \

    && cd /usr/bin \
    && rm -f python \
    && ln -s python3.10 python \   

    
    && groupadd -g 1000 www \
    && useradd -g 1000 -m -s /bin/bash www \
    && echo 'www:www' |chpasswd \
    && echo 'root:root' |chpasswd \
    && echo "www ALL=(ALL:ALL) ALL \nwww ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/default \
    && chmod 440 /etc/sudoers.d/default \
    # localtime 与 timezone 所在时区要保持一致，否则 tzlocal.utils.ZoneInfoNotFoundError: 'Multiple conflicting time zone configurations found
    # 原指向：localtime -> /usr/share/zoneinfo/Etc/UTC
    # 必须要先删除，再重建软连接，否则直接覆盖都无效
    # && cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && rm -f /etc/localtime \
    && cd /etc \
    && ln -s /usr/share/zoneinfo/Asia/Shanghai localtime \
    && echo "Asia/Shanghai" > /etc/timezone \   

    
    && chmod 777 -R /usr/src \


    # install nginx begin(直接apt install安装的nginx守护进程总有问题)
# download ngx_cache_purge module
    && cd /usr/src \
    && wget http://labs.frickle.com/files/ngx_cache_purge-${NGX_CACHE_PURGE_VERSION}.tar.gz \
    && tar -zxvf ngx_cache_purge-${NGX_CACHE_PURGE_VERSION}.tar.gz >/dev/null 2>&1 \
    && git clone https://github.com/openresty/echo-nginx-module.git /usr/src/echo-nginx-module \
    # && NGINX_GPG=B0F4253373F8F6F510D42178520A9993A1C052F8 \
    && CONFIG="\
       --prefix=/etc/nginx \
       --sbin-path=/usr/sbin/nginx \
       --modules-path=/usr/lib/nginx/modules \
       --conf-path=/etc/nginx/nginx.conf \
       --error-log-path=/var/log/nginx/error.log \
       --http-log-path=/var/log/nginx/access.log \
       --pid-path=/var/cache/nginx/nginx.pid \
       --lock-path=/var/cache/nginx/nginx.lock \
       --http-client-body-temp-path=/var/cache/nginx/client_temp \
       --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
       --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
       --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
       --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
       --user=www \
       --group=www \
       --with-http_ssl_module \
       --with-http_realip_module \
       --with-http_addition_module \
       --with-http_sub_module \
       --with-http_dav_module \
       --with-http_flv_module \
       --with-http_mp4_module \
       --with-http_gunzip_module \
       --with-http_gzip_static_module \
       --with-http_random_index_module \
       --with-http_secure_link_module \
       --with-http_stub_status_module \
       --with-http_auth_request_module \
       --with-http_xslt_module=dynamic \
       --with-http_image_filter_module=dynamic \
       --with-http_geoip_module=dynamic \
       --with-threads \
       --with-stream \
       --with-stream_ssl_module \
       --with-stream_ssl_preread_module \
       --with-stream_realip_module \
       --with-stream_geoip_module=dynamic \
       --with-http_slice_module \
       --with-mail \
       --with-mail_ssl_module \
       --with-compat \
       --with-file-aio \
       --with-http_v2_module \
       --add-module=/usr/src/ngx_cache_purge-${NGX_CACHE_PURGE_VERSION} \
       --add-module=/usr/src/echo-nginx-module \
    	" \
    && mkdir -p /data \
    && cd /usr/src \
    && wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
    # && wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz.asc \
    # && gpg --keyserver pool.sks-keyservers.net --recv-keys "$NGINX_GPG" \
	# && gpg --batch --verify nginx-${NGINX_VERSION}.tar.gz.asc nginx-${NGINX_VERSION}.tar.gz \
    && tar xzf nginx-${NGINX_VERSION}.tar.gz >/dev/null 2>&1 \
    && cd /usr/src/nginx-${NGINX_VERSION} \
    && ./configure $CONFIG --with-debug \
	&& make -j$(getconf _NPROCESSORS_ONLN) \
	&& mv objs/nginx objs/nginx-debug \
	&& mv objs/ngx_http_xslt_filter_module.so objs/ngx_http_xslt_filter_module-debug.so \
	&& mv objs/ngx_http_image_filter_module.so objs/ngx_http_image_filter_module-debug.so \
	&& mv objs/ngx_http_geoip_module.so objs/ngx_http_geoip_module-debug.so \
	&& mv objs/ngx_stream_geoip_module.so objs/ngx_stream_geoip_module-debug.so \
	&& ./configure $CONFIG \
	# && make -j$(getconf _NPROCESSORS_ONLN) \
	&& make >/dev/null 2>&1 \
	&& make install \
    && rm -rf /etc/nginx/html/ \
	&& mkdir -p /etc/nginx/conf.d/ \
	&& mkdir -p /usr/share/nginx/html/ \
	&& install -m644 html/index.html /usr/share/nginx/html/ \
	&& install -m644 html/50x.html /usr/share/nginx/html/ \
	&& install -m755 objs/nginx-debug /usr/sbin/nginx-debug \
	&& install -m755 objs/ngx_http_xslt_filter_module-debug.so /usr/lib/nginx/modules/ngx_http_xslt_filter_module-debug.so \
	&& install -m755 objs/ngx_http_image_filter_module-debug.so /usr/lib/nginx/modules/ngx_http_image_filter_module-debug.so \
	&& install -m755 objs/ngx_http_geoip_module-debug.so /usr/lib/nginx/modules/ngx_http_geoip_module-debug.so \
	&& install -m755 objs/ngx_stream_geoip_module-debug.so /usr/lib/nginx/modules/ngx_stream_geoip_module-debug.so \
	&& ln -s ../../usr/lib/nginx/modules /etc/nginx/modules \
	&& ln -s /usr/share/nginx/html /etc/nginx/html \
	&& strip /usr/sbin/nginx* \
	&& strip /usr/lib/nginx/modules/*.so \
    && cd /usr/src \
	&& mv /usr/bin/envsubst /tmp/ \
	\
	&& runDeps="$( \
	   scanelf --needed --nobanner --format '%n#p' /usr/sbin/nginx /usr/lib/nginx/modules/*.so /tmp/envsubst \
		   | tr ',' '\n' \
   	   | sort -u \
		   | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)" \
	&& mv /tmp/envsubst /usr/bin/ \
	\
	# 没必要：forward request and error logs to docker log collector
	# && ln -sf /dev/stdout /var/log/nginx/access.log \
	# && ln -sf /dev/stderr /var/log/nginx/error.log \
    && rm -rf /usr/src/* \
# install nginx end



# for xray
    && mkdir -p /etc/ssl/certs/ \
    && cd /etc/ssl/certs/ \
    && wget http://curl.haxx.se/ca/cacert.pem \
    && mv cacert.pem ca-certificates.crt \
    # 解决：curl 77 错误，error setting certificate verify locations
    && mkdir -p /etc/pki/tls/certs \
    && cd /etc/pki/tls/certs \
    && ln -s /etc/ssl/certs/ca-certificates.crt ./ca-bundle.crt \
    && cd /tmp \
    && wget https://github.com/XTLS/Xray-core/releases/download/v${XRAY_VERSION}/Xray-linux-${X_ARCH}.zip \
    && unzip Xray-linux-${X_ARCH}.zip -d /xray \
    && mkdir /etc/xray \
    && mkdir /usr/local/share/xray \
    && chmod +x /xray/xray \
    && ln -sf /xray/xray /usr/local/bin/xray \
    && ln -sf /xray/geoip.dat /usr/local/share/xray/geoip.dat \
    && ln -sf /xray/geosite.dat /usr/local/share/xray/geosite.dat \
    && echo '{}' > /etc/xray/config.json \



# for x11nvc
    && mkdir -p /shareVolume/config/vnc/ \
    && x11vnc -storepasswd 1234 /shareVolume/config/vnc/passwd \
    && ln -s /shareVolume/config/vnc ~/.vnc \


    # && dpkg-reconfigure -f noninteractive tzdata \
    # && mv /bin/sh /bin/sh_bak \
    # && ln -s /bin/bash /bin/sh \
    && mkdir -p /etc/supervisor/conf.d/ \
    && mkdir -p /var/log/supervisor/ \
    && mkdir -p /shareVolume/config/ssh/ \
    && ssh-keygen -t dsa -f /shareVolume/config/ssh/id_dsa -N "" \
    && ssh-keygen -t rsa -f /shareVolume/config/ssh/id_rsa -N "" \
    && ssh-keygen -t ecdsa -f /shareVolume/config/ssh/id_ecdsa -N "" \
    && ssh-keygen -t ed25519 -f /shareVolume/config/ssh/id_ed25519 -N "" \
   
	# 解决 sudo -i 映射不了 X11 问题
    && touch /home/www/.Xauthority \
    && chown www:www /home/www/.Xauthority \
	&& ln -s /home/www/.Xauthority /root/.Xauthority \
    && sed -ri 's/^#   StrictHostKeyChecking\s+.*/    StrictHostKeyChecking no/' /etc/ssh/ssh_config \
    && cp -f /etc/ssh/ssh_config /etc/ssh/ssh_config_demo \
    && sed -i 's@#   IdentityFile ~/.ssh/id_rsa@   IdentityFile \/shareVolume\/config\/ssh\/id_rsa@' /etc/ssh/ssh_config \
    && sed -i 's@#   IdentityFile ~/.ssh/id_dsa@   IdentityFile \/shareVolume\/config\/ssh\/id_dsa@' /etc/ssh/ssh_config \
    && sed -i 's@#   IdentityFile ~/.ssh/id_ecdsa@   IdentityFile \/shareVolume\/config\/ssh\/id_ecdsa@' /etc/ssh/ssh_config \
    && sed -i 's@#   IdentityFile ~/.ssh/id_ed25519@   IdentityFile \/shareVolume\/config\/ssh\/id_ed25519@' /etc/ssh/ssh_config \


  
  
    && cd /usr/src/ \
    && wget https://nchc.dl.sourceforge.net/project/ta-lib/ta-lib/0.4.0/ta-lib-0.4.0-src.tar.gz \
    && tar -xf ta-lib-0.4.0-src.tar.gz \
    && cd ta-lib \
    # 需要加入--build参数，否则在arm64里报错：cannot guess build type; you must specify one
    && ./configure --prefix=/usr --build=${BUILDTYPE}-unknown-linux-gnu --libdir=/usr/lib/${BUILDTYPE}-linux-gnu \
    # If you build TA-Lib using make -jX it will fail but that's OK! Simply rerun make -jX followed by [sudo] make install.
    # && make -j$(getconf _NPROCESSORS_ONLN) \
    && make \
    && make install \
    && rm -rf /usr/src/* \
    # install ta-lib end

# install novnc begin
    && cd / \
    && git clone https://github.com/novnc/noVNC.git /noVNC \
# install novnc end

# install PIP begin
    && cd /usr/src/ \
    && curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
    && python get-pip.py \
    && rm -rf /usr/src/* \
# install PIP end

    # && python -m pip install --upgrade pip \
    # && python -m pip install --upgrade pip==20.3.3 \
    && python -m pip install --upgrade \
        joblib \
        #  runipy \
        Cython \
        # 提供 加密方法：from Crypto.Cipher import AES
        pycryptodome \

        six \
        websockify \
        # traitlets需要提前指定版本为5.9.0，不然jupyter会自动安装最新版5.10.0,会引起报错
        traitlets==5.9.0 \
        # 必须在jupyter之前装，版本不能大于6.5.5，不然报错：ModuleNotFoundError: No module named 'notebook.base'
        notebook==6.5.5  \
        #  notebook \
        jupyter \
        # 6.5.1
        # 6.4.12 ->6.5.2
        # 3.4.8 > 3.5.2
        # 4.0.6会引起报错：ModuleNotFoundError: No module named 'jupyter_server.contents'
        #  jupyterlab==4.0.4 \
        #  jupyterthemes \
        # 以下两个一直更新太慢，耽误进度，停用它
        jupyter_contrib_nbextensions \
        jupyter_nbextensions_configurator \
        #  模拟打开网页
        #  selenium \
        # 读取“.xls”文件：df_total = pd.read_excel(excel_sh_rzrq, sheet_name='汇总信息', engine='xlrd')
        # 读取“.xlsx”文件：df_details = pd.read_excel(excel_sh_rzrq, sheet_name='明细信息', engine='openpyxl')
        openpyxl \
        xlrd \


        tzlocal==4.2 \
        
        plotly==5.10.0 \
        retrying \
        ta-lib==0.4.24 \

        pandas==1.5.0 \
        # 用来在jupyter里画K线
        mplfinance \
        # 用于生成图片 import plotly.io as pio; pio.write_image(fig, f"/tmp/{contract}.png")
        kaleido \
        # 强大的统计分析库,包含假设检验、回归分析、时间序列分析等功能,能够很好的和Numpy和Pandas等库结合起来,提高工作效率
        statsmodels \
        requests \
        dataclasses \
        peewee \
        pymysql \
        exchange-calendars \
        # 多处理和任务分配系统
        ipyparallel \
        #  six \
        #  wheel \
        pytz \
        
        # ta-lib==0.4.24 \
        #  Seaborn是基于matplotlib开发的图形可视化python包
        matplotlib==3.5.3 \
        seaborn==0.11.2 \
        # 好像现在不需要用 PyCryptodome
    #  PyCryptodome==3.9.9 \
        importlib-metadata==4.12.0 \
        
    #  pyzmq==23.2.1 \
        pyzmq==24.0.1 \

    && cd / \
    && mkdir -p /shareVolume/config/jupyter/ \
    && ln -s /shareVolume/config/jupyter ~/.jupyter \
    # && mkdir -p ~/.local/share/jupyter/ \
    # && mv ~/.local/share/jupyter /shareVolume/config/jupyter/share \
    # && ln -s /shareVolume/config/jupyter/share ~/.local/share/jupyter \
    && jupyter notebook --generate-config --allow-root \
    
    && echo "c.NotebookApp.token = ''" >> /shareVolume/config/jupyter/jupyter_notebook_config.py \
    && echo "c.NotebookApp.password=''" >> /shareVolume/config/jupyter/jupyter_notebook_config.py \
    && echo "c.NotebookApp.password_required=False" >> /shareVolume/config/jupyter/jupyter_notebook_config.py \

    # && echo "c.NotebookApp.password='sha1:d12a2dd64552:86359144939d58019e6e5b37e373a50426ad7b2b' ">> /shareVolume/config/jupyter/jupyter_notebook_config.py

    # 查看可用jupyter主题 jt -l
    # 应用主题
    # 设置密码： jupyter notebook password
    # 深色
    # && jt -t chesterish -f inconsolata -fs 10 -cellw 90% -ofs 11 -dfs 10 -T \
    # 浅色
    # && jt -t grade3 -f inconsolata -fs 10 -cellw 90% -ofs 11 -dfs 10 -T \
    # 暂时屏蔽contrib
    && jupyter contrib nbextension install --user \
    # 设置默认IP
    && echo "\n" >> /shareVolume/config/jupyter/jupyter_notebook_config.py \
    && echo "c.ServerApp.allow_root = True" >> /shareVolume/config/jupyter/jupyter_notebook_config.py \
    && echo "c.ServerApp.open_browser = False" >> /shareVolume/config/jupyter/jupyter_notebook_config.py \
    && echo "c.ServerApp.ip = '0.0.0.0'" >> /shareVolume/config/jupyter/jupyter_notebook_config.py \
    && echo "c.ServerApp.port = 8888" >> /shareVolume/config/jupyter/jupyter_notebook_config.py \


    # 都用supervisor来启动，不需要写入~/.xinitrc
    # && echo "exec startfluxbox" >> ~/.xinitrc \

    && mkdir -p ~/.fluxbox/ \
    && echo "*Font:Microsoft YaHei-10" >> /usr/share/fluxbox/styles/Artwiz \
    && echo "*Font:Microsoft YaHei-10" >> /usr/share/fluxbox/styles/Makro \
    && echo "*Font:Microsoft YaHei-10" >> /usr/share/fluxbox/styles/MerleyKay \
    && echo "\ntoolbar.workspace.textColor:rgb:1a/04/08" \
	        "\ntoolbar.iconbar.focused.color:rgb:f6/df/93" \
	        "\ntoolbar.iconbar.focused.colorTo:rgb:ee/b9/6b" \
	        "\ntoolbar.iconbar.focused.textColor:rgb:1a/04/08" \
	        "\ntoolbar.iconbar.unfocused.color:rgb:dd/dd/dd" \
	        "\ntoolbar.iconbar.unfocused.colorTo:rgb:c0/c0/c0" \
	        "\ntoolbar.iconbar.unfocused.textColor:rgb:5a/5a/5a" \
	        "\n" \
	        >> /usr/share/fluxbox/styles/LemonSpace \
# 替换原背景
# background: flat
# background.color: rgb:db/bc/83
    && sed -ri 's/^background:\s+.*/background:             fullscreen/' /usr/share/fluxbox/styles/LemonSpace \
    && sed -ri 's/^background.color:\s+.*/background.pixmap:      \/root\/.fluxbox\/wallpaper\/bg.jpg/' /usr/share/fluxbox/styles/LemonSpace \


    # && sed -ri 's/^session.styleFile: \s+.*/session.styleFile: \/usr\/share\/fluxbox\/styles\/LemonSpace/' ~/.fluxbox/init \
    # && echo "toolbar.workspace.textColor:rgb:1a/04/08" >> /usr/share/fluxbox/styles/LemonSpace \
    # && echo "toolbar.iconbar.focused.color:rgb:f6/df/93" >> /usr/share/fluxbox/styles/LemonSpace \
    # && echo "toolbar.iconbar.focused.colorTo:rgb:ee/b9/6b" >> /usr/share/fluxbox/styles/LemonSpace \
    # && echo "toolbar.iconbar.focused.textColor:rgb:1a/04/08" >> /usr/share/fluxbox/styles/LemonSpace \
    # && echo "toolbar.iconbar.unfocused.color:rgb:dd/dd/dd" >> /usr/share/fluxbox/styles/LemonSpace \
    # && echo "toolbar.iconbar.unfocused.colorTo:rgb:c0/c0/c0" >> /usr/share/fluxbox/styles/LemonSpace \
    # && echo "toolbar.iconbar.unfocused.textColor:rgb:5a/5a/5a" >> /usr/share/fluxbox/styles/LemonSpace \
    && mv /root/.fluxbox /shareVolume/config/fluxbox \
    && ln -s /shareVolume/config/fluxbox ~/.fluxbox \


    # && mv /usr/bin/lsb_release.bak /usr/bin/lsb_release \

    # 设置Xterm默认配置
    && echo "xterm*faceName: DejaVu" > ~/.Xdefaults \
    && echo "xterm*faceNameDoublesize: Microsoft YaHei" >> ~/.Xdefaults \
    && echo "xterm*faceSize: 12" >> ~/.Xdefaults \
    && echo "xterm*allowBoldFonts: false" >> ~/.Xdefaults \
    && echo "xterm*background: darkblue" >> ~/.Xdefaults \
    && echo "xterm*foreground: white" >> ~/.Xdefaults \
    && echo "xterm*locale: true" >> ~/.Xdefaults \
    && echo "xterm.utf8: true" >> ~/.Xdefaults \
    && echo "xterm.utf8Title: true" >> ~/.Xdefaults \
    && echo "xterm*fontMenu*fontdefault*Label: Default" >> ~/.Xdefaults \
    && echo "xterm*xftAutialias: true" >> ~/.Xdefaults \
    && echo "xterm*cjkWidth: false" >> ~/.Xdefaults \
    && echo "xterm*geometry: 80x24" >> ~/.Xdefaults \
    && echo "xterm*scrollBar: false" >> ~/.Xdefaults \
    && echo "xterm*rightScrollBar: true" >> ~/.Xdefaults \

    # 
    && echo "alias rm='rm -i'" >> ~/.bashrc \
    && echo "alias cp='cp -i'" >> ~/.bashrc \
    && echo "set mouse=c" > ~/.vimrc \
    && echo "if test -f .bashrc; then \nsource .bashrc \nfi " > ~/.bash_profile \
    # 解决无法使用Tab补全
    && echo "export SHELL=`which bash` \n[ -z \"\$BASH_VERSION\" ] && exec \"\$SHELL\" -l" >> ~/.profile \
    && rm -f /home/www/.vimrc /home/www/.bashrc \
    && cp -rf ~/.vimrc /home/www/.vimrc \
    && cp -rf ~/.bashrc /home/www/.bashrc \
    && chown www:www /home/www/.vimrc \
    && chown www:www /home/www/.bashrc \
    && chown -R www:www /shareVolume/config/ssh \
    && chmod 600 /shareVolume/config/ssh/* \
    && chmod 644 /shareVolume/config/ssh/*.pub \
    && mv /etc/ssh/*_demo /shareVolume/config/ssh/ \
    && cp -rf ~/.bashrc /.bashrc \
    && cp -rf ~/.bash_profile /.bash_profile \

    && apt-get clean 

COPY files /

VOLUME ["/shareVolume"]

# EXPOSE 80 8888

CMD ["supervisord", "-n", "-c",  "/etc/supervisord.conf"]

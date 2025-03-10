export HOME=/
# Dockerfile - Ubuntu Bionic
# https://github.com/openresty/docker-openresty

export RESTY_IMAGE_BASE="ubuntu"
export RESTY_IMAGE_TAG="bionic"

# FROM ${RESTY_IMAGE_BASE}:${RESTY_IMAGE_TAG}

export maintainer="Evan Wies <evan@neomantra.net>"

# Docker Build Arguments
export RESTY_IMAGE_BASE="ubuntu"
export RESTY_IMAGE_TAG="bionic"
export RESTY_VERSION="_RESTY_VERSION"
export RESTY_LUAROCKS_VERSION="3.3.1"
export RESTY_OPENSSL_VERSION="1.1.1g"
export RESTY_OPENSSL_PATCH_VERSION="1.1.1f"
export RESTY_OPENSSL_URL_BASE="https://www.openssl.org/source"
export RESTY_PCRE_VERSION="8.44"

export RESTY_LUAROCKS_VERSION="3.9.0"
export RESTY_OPENSSL_VERSION="1.1.1q"
export RESTY_PCRE_VERSION="8.45"

export RESTY_J="1"
export RESTY_J=$(nproc)
export RESTY_CONFIG_OPTIONS="\
    --with-compat \
    --with-file-aio \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_geoip_module=dynamic \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_image_filter_module=dynamic \
    --with-http_mp4_module \
    --with-http_random_index_module \
    --with-http_realip_module \
    --with-http_secure_link_module \
    --with-http_slice_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_sub_module \
    --with-http_v2_module \
    --with-http_xslt_module=dynamic \
    --with-ipv6 \
    --with-mail \
    --with-mail_ssl_module \
    --with-md5-asm \
    --with-pcre-jit \
    --with-sha1-asm \
    --with-stream \
    --with-stream_ssl_module \
    --with-threads \
    "
export RESTY_CONFIG_OPTIONS_MORE=""
export RESTY_LUAJIT_OPTIONS="--with-luajit-xcflags='-DLUAJIT_NUMMODE=2 -DLUAJIT_ENABLE_LUA52COMPAT'"

export RESTY_ADD_PACKAGE_BUILDDEPS=""
export RESTY_ADD_PACKAGE_RUNDEPS=""
export RESTY_EVAL_PRE_CONFIGURE=""
export RESTY_EVAL_POST_MAKE=""

# These are not intended to be user-specified
export _RESTY_CONFIG_DEPS="--with-pcre \
    --with-cc-opt='-DNGX_LUA_ABORT_AT_PANIC -I/root/.asdf/installs/ffmpeg/snapshot/include -I/usr/local/openresty/pcre/include -I/usr/local/openresty/openssl/include -O2 -DTCP_FASTOPEN=23' \
    --with-ld-opt='-L/root/.asdf/installs/ffmpeg/snapshot/lib -L/usr/local/openresty/pcre/lib -L/usr/local/openresty/openssl/lib -Wl,-rpath,/usr/local/openresty/pcre/lib:/usr/local/openresty/openssl/lib' \
    "

export resty_image_base="${RESTY_IMAGE_BASE}"
export resty_image_tag="${RESTY_IMAGE_TAG}"
export resty_version="${RESTY_VERSION}"
export resty_luarocks_version="${RESTY_LUAROCKS_VERSION}"
export resty_openssl_version="${RESTY_OPENSSL_VERSION}"
export resty_openssl_patch_version="${RESTY_OPENSSL_PATCH_VERSION}"
export resty_openssl_url_base="${RESTY_OPENSSL_URL_BASE}"
export resty_pcre_version="${RESTY_PCRE_VERSION}"
export resty_config_options="${RESTY_CONFIG_OPTIONS}"
export resty_config_options_more="${RESTY_CONFIG_OPTIONS_MORE}"
export resty_config_deps="${_RESTY_CONFIG_DEPS}"
export resty_add_package_builddeps="${RESTY_ADD_PACKAGE_BUILDDEPS}"
export resty_add_package_rundeps="${RESTY_ADD_PACKAGE_RUNDEPS}"
export resty_eval_pre_configure="${RESTY_EVAL_PRE_CONFIGURE}"
export resty_eval_post_make="${RESTY_EVAL_POST_MAKE}"

_init() {
	echo RUN
	DEBIAN_FRONTEND=noninteractive apt-get update &&
		DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
			build-essential \
			ca-certificates \
			curl \
			gettext-base \
			libgd-dev \
			libgeoip-dev \
			libncurses5-dev \
			libperl-dev \
			libreadline-dev \
			libxslt1-dev \
			make \
			perl \
			unzip \
			zlib1g-dev \
			${RESTY_ADD_PACKAGE_BUILDDEPS} \
			${RESTY_ADD_PACKAGE_RUNDEPS} &&
		cd /tmp &&
		if [ -n "${RESTY_EVAL_PRE_CONFIGURE}" ]; then eval $(echo ${RESTY_EVAL_PRE_CONFIGURE}); fi &&
		curl -kfSL "${RESTY_OPENSSL_URL_BASE}/openssl-${RESTY_OPENSSL_VERSION}.tar.gz" -o openssl-${RESTY_OPENSSL_VERSION}.tar.gz &&
		tar xzf openssl-${RESTY_OPENSSL_VERSION}.tar.gz &&
		cd openssl-${RESTY_OPENSSL_VERSION} &&
		if [ $(echo ${RESTY_OPENSSL_VERSION} | cut -c 1-5) = "1.1.1" ]; then
			echo 'patching OpenSSL 1.1.1 for OpenResty' &&
				curl -s https://raw.githubusercontent.com/openresty/openresty/master/patches/openssl-${RESTY_OPENSSL_PATCH_VERSION}-sess_set_get_cb_yield.patch | patch -p1
		fi &&
		if [ $(echo ${RESTY_OPENSSL_VERSION} | cut -c 1-5) = "1.1.0" ]; then
			echo 'patching OpenSSL 1.1.0 for OpenResty' &&
				curl -s https://raw.githubusercontent.com/openresty/openresty/ed328977028c3ec3033bc25873ee360056e247cd/patches/openssl-1.1.0j-parallel_build_fix.patch | patch -p1 &&
				curl -s https://raw.githubusercontent.com/openresty/openresty/master/patches/openssl-${RESTY_OPENSSL_PATCH_VERSION}-sess_set_get_cb_yield.patch | patch -p1
		fi &&
		./config \
			no-threads shared zlib -g \
			enable-ssl3 enable-ssl3-method \
			--libdir=lib &&
		make -j${RESTY_J} &&
		make -j${RESTY_J} install_sw &&
		cd /tmp &&
		curl -fSL https://downloads.sourceforge.net/project/pcre/pcre/${RESTY_PCRE_VERSION}/pcre-${RESTY_PCRE_VERSION}.tar.gz -o pcre-${RESTY_PCRE_VERSION}.tar.gz &&
		#		curl -kfSL https://ftp.pcre.org/pub/pcre/pcre-${RESTY_PCRE_VERSION}.tar.gz -o pcre-${RESTY_PCRE_VERSION}.tar.gz &&
		tar xzf pcre-${RESTY_PCRE_VERSION}.tar.gz &&
		cd /tmp/pcre-${RESTY_PCRE_VERSION} &&
		./configure \
			--disable-cpp \
			--enable-jit \
			--enable-utf \
			--enable-unicode-properties &&
		make -j${RESTY_J} &&
		make -j${RESTY_J} install &&
		cd /tmp &&
		curl -kfSL https://openresty.org/download/openresty-${RESTY_VERSION}.tar.gz -o openresty-${RESTY_VERSION}.tar.gz &&
		tar xzf openresty-${RESTY_VERSION}.tar.gz
}
_openresty() {
	dir=$1
	prefix=$2
	shift 2
	cd /tmp/openresty-${RESTY_VERSION} &&
		bash -x $dir/modules.sh /tmp/openresty-${RESTY_VERSION} $prefix $@ -j${RESTY_J} ${_RESTY_CONFIG_DEPS} ${RESTY_CONFIG_OPTIONS} ${RESTY_CONFIG_OPTIONS_MORE} ${RESTY_LUAJIT_OPTIONS} &&
		make -j${RESTY_J} &&
		make -j${RESTY_J} install
}
_clean() {
	cd /tmp &&
		rm -rf \
			openssl-${RESTY_OPENSSL_VERSION}.tar.gz openssl-${RESTY_OPENSSL_VERSION} \
			pcre-${RESTY_PCRE_VERSION}.tar.gz pcre-${RESTY_PCRE_VERSION} \
			openresty-${RESTY_VERSION}.tar.gz openresty-${RESTY_VERSION} &&
		curl -kfSL https://luarocks.github.io/luarocks/releases/luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz -o luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz &&
		tar xzf luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz &&
		cd luarocks-${RESTY_LUAROCKS_VERSION} &&
		./configure \
			--prefix=/usr/local/openresty/luajit \
			--with-lua=/usr/local/openresty/luajit \
			--lua-suffix=jit-2.1.0-beta3 \
			--with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1 &&
		make build &&
		make install &&
		cd /tmp &&
		if [ -n "${RESTY_EVAL_POST_MAKE}" ]; then eval $(echo ${RESTY_EVAL_POST_MAKE}); fi &&
		rm -rf luarocks-${RESTY_LUAROCKS_VERSION} luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz &&
		if [ -n "${RESTY_ADD_PACKAGE_BUILDDEPS}" ]; then DEBIAN_FRONTEND=noninteractive apt-get remove -y --purge ${RESTY_ADD_PACKAGE_BUILDDEPS}; fi &&
		DEBIAN_FRONTEND=noninteractive apt-get autoremove -y &&
		mkdir -p /var/run/openresty &&
		echo ln -sf /dev/stdout /usr/local/openresty/nginx/logs/access.log &&
		echo ln -sf /dev/stderr /usr/local/openresty/nginx/logs/error.log

	# Add additional binaries into PATH for convenience
	export PATH=$PATH:/usr/local/openresty/luajit/bin:/usr/local/openresty/nginx/sbin:/usr/local/openresty/bin

	# Add LuaRocks paths
	# If OpenResty changes, these may need updating:
	#    /usr/local/openresty/bin/resty -e 'print(package.path)'
	#    /usr/local/openresty/bin/resty -e 'print(package.cpath)'
	export LUA_PATH="/usr/local/openresty/site/lualib/?.ljbc;/usr/local/openresty/site/lualib/?/init.ljbc;/usr/local/openresty/lualib/?.ljbc;/usr/local/openresty/lualib/?/init.ljbc;/usr/local/openresty/site/lualib/?.lua;/usr/local/openresty/site/lualib/?/init.lua;/usr/local/openresty/lualib/?.lua;/usr/local/openresty/lualib/?/init.lua;./?.lua;/usr/local/openresty/luajit/share/luajit-2.1.0-beta3/?.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua;/usr/local/openresty/luajit/share/lua/5.1/?.lua;/usr/local/openresty/luajit/share/lua/5.1/?/init.lua"

	export LUA_CPATH="/usr/local/openresty/site/lualib/?.so;/usr/local/openresty/lualib/?.so;./?.so;/usr/local/lib/lua/5.1/?.so;/usr/local/openresty/luajit/lib/lua/5.1/?.so;/usr/local/lib/lua/5.1/loadall.so;/usr/local/openresty/luajit/lib/lua/5.1/?.so"

	# Copy nginx configuration files
	cd $HOME
	cp nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
	cd $HOME
	cp nginx.vh.default.conf /etc/nginx/conf.d/default.conf

	#CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]

	# Use SIGQUIT instead of default SIGTERM to cleanly drain requests
	# See https://github.com/openresty/docker-openresty/blob/master/README.md#tips--pitfalls
	#STOPSIGNAL SIGQUIT
}
if [ $# -eq 0 ]; then
	_init
	_openresty _DIR _PREFIX _MODULE
else
	$@
fi

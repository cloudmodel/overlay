# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5
PYTHON_DEPEND="2:2.6"
RESTRICT_PYTHON_ABIS="3.* *-jython"

inherit distutils eutils python user systemd

DESCRIPTION="A modern, Nagios compatible monitoring tool, written in Python"
HOMEPAGE="http://shinken-monitoring.org/"
SRC_URI="https://github.com/naparuba/shinken/archive/${PV}.tar.gz"

LICENSE="AGPLv3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="livestat +arbiter broker poller reactionner receiver scheduler"

RDEPEND="
	dev-python/pyro
  dev-python/pycurl
  dev-python/paramiko
	livestat? ( dev-python/simplejson )
	poller? ( net-analyzer/nagios-plugins )
	"
DEPEND="${RDEPEND}
	!net-analyzer/nagios"

SHINKENMODULES="arbiter broker poller reactionner receiver scheduler"

src_unpack() {
	unpack ${A}
	cd ${S}
	find . -name '.gitignore' -exec rm -f {} \\\;
	find . -name 'void_for_git' -exec rm -f {} \\\;
#	epatch "${FILESDIR}/${P}.patch"
}

src_configure() {
	local -i modnum=0

	for mod in ${SHINKENMODULES}; do
	  if use $mod; then
	    let modnum++
		fi
	done
	if [[ "${modnum}" -lt 1 ]]; then
		eerror
		eerror "No shinken module selected, aborting...."
		ewarn "Supported databases are ${SHINKENMODULES}"
		eerror
	fi
}

pkg_setup() {
	ebegin "Creating shinken user and group"
	enewgroup shinken
	enewuser shinken -1 -1 -1 "shinken,nagios"
	eend $?
	
	python_set_active_version 2
	python_pkg_setup
}

src_prepare() {
	# remove unneded doubletts
	rm bin/*.py
}

src_install() {
	distutils_src_install
	# remove windows-specific configs
	rm -rf ${D}$(python_get_sitedir)/skonf

	keepdir /var/lib/${PN}
	fowners shinken:shinken "/var/lib/${PN}"
	fperms 750 "/var/lib/${PN}"
	keepdir "/var/run/${PN}"
	fowners shinken:shinken "/var/run/${PN}"
  echo "D /var/run/shinken 0755 shinken shinken" > /etc/tmpfile.d/shinken.conf
	keepdir "/var/log/${PN}"
	fowners shinken:shinken "/var/log/${PN}"
	fperms 750 "/var/log/${PN}"

	insinto "/usr/lib/nagios/plugins"
	doins libexec/*.py
	dobin bin/nagios

	for mod in ${SHINKENMODULES}; do
		if ! use $mod; then
			rm -f ${D}/etc/${PN}/${mod}d.ini
		fi
	done

	manpages="discovery"
	for mod in ${SHINKENMODULES}; do
		if use $mod; then
			manpages="${manpages} $mod"
		fi
	done

	for mod in $manpages; do
		newman for_fedora/man/shinken-${mod}.8 shinken-${mod}.8
	done

	#newconfd ${FILESDIR}/${PN}.confd ${PN}
	#newinitd ${FILESDIR}/${PN}.initd ${PN}

	for mod in ${SHINKENMODULES}; do
		if use $mod; then
			systemd_newunit for_fedora/systemd/shinken-${mod}.service ${PN}-${mod}.service
    
      sed -i s,ExecStart=/usr/sbin/,ExecStart=/usr/bin/python2\ /usr/bin/, "${D}/usr/lib/systemd/system/${PN}-${mod}.service"
		fi
	done
  
  # Use python2 shebang for binaries instead of just python
  for bin in ${D}/usr/bin/*; do
    sed -i s,\#\!/usr/bin/env\ python,\#\!/usr/bin/env\ python2, $bin
  done
  
}

# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5
PYTHON_COMPAT=(python2_{6,7})

inherit distutils-r1 mercurial

DESCRIPTION="Mozilla Sync Server"
HOMEPAGE="https://hg.mozilla.org/services/server-full"

EHG_REPO_URI="https://hg.mozilla.org/services/server-full"

case ${PV} in
9999)
	EHG_REVISION="default"
	;;
*)
	inherit versionator
	MY_PV=$(replace_version_separator 2 '-' "${PV}")
	MY_P="${PN}-${MY_PV}"
	EHG_QUIET="OFF"
	EHG_REVISION="rpm-${MY_PV}"
	S="${WORKDIR}/${PN}"
	;;
esac

LICENSE="MPL-1.1"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="ldap memcached mysql postgres sqlite +wsgi"

REQUIRED_USE="|| ( ldap memcached mysql postgres sqlite )"

RDEPEND="www-misc/mozilla-sync-server-reg[${PYTHON_USEDEP}]
		 www-misc/mozilla-sync-server-storage[${PYTHON_USEDEP},ldap?,mysql?,postgres?,sqlite?]
		 wsgi? (
		 	|| ( www-apache/mod_wsgi www-servers/uwsgi[python] )
		 )"
DEPEND="${RDEPEND}
		dev-python/setuptools[${PYTHON_USEDEP}]"

src_prepare() {
	sed -i 's_file:%(here)s/etc/_file:%(here)s/_' *.ini
}

src_install() {
	distutils-r1_src_install

	keepdir /etc/mozilla-sync-server
	insinto /etc/mozilla-sync-server
	use ldap && (
		doins etc/ldap.conf
		newins tests_ldap.ini ldap.ini

		use memcached && (
			doins etc/memcachedldap.conf
			newins tests_memcachedldap.ini memcached_ldap.ini
		)
	)
	use memcached && (
		doins etc/memcached.conf
		newins tests_memcached.ini memcached.ini
	)
	use mysql && (
		doins etc/mysql.conf
		newins tests_mysql.ini mysql.ini
	)
	use postgres && (
        sed -e 's/mysql/postgresql/g;s/3306/5432/g' etc/mysql.conf >  etc/postgres.conf
        sed -e 's/mysql.conf/postrges.conf/g' tests_mysql.ini > postgres.ini
		doins etc/postgres.conf
		doins postgres.ini
	)
	use sqlite && (
		newins /etc/sync.conf sqlite.conf
		newins development.ini sqlite.ini
	)
	use wsgi && newins sync.wsgi server.wsgi
}

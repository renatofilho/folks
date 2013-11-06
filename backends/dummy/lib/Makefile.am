BACKEND_NAME = "dummy"

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	-I$(top_srcdir)/folks \
	-include $(CONFIG_HEADER) \
	-include folks/redeclare-internal-api.h \
	-DPACKAGE_DATADIR=\"$(pkgdatadir)\" \
	-DBACKEND_NAME=\"$(BACKEND_NAME)\" \
	-DG_LOG_DOMAIN=\"$(BACKEND_NAME)\" \
	$(NULL)

VAPIGENFLAGS += \
	--vapidir=. \
	--vapidir=$(top_srcdir)/folks \
	$(NULL)

folks_dummydir = $(libdir)
folks_dummy_LTLIBRARIES = libfolks-dummy.la

##################################################################
# Support library
##################################################################

pkgconfig_in = folks-dummy.pc.in
pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = $(pkgconfig_in:.in=)

libfolks_dummy_la_SOURCES = \
	dummy-backend.vala \
	dummy-persona.vala \
	dummy-persona-store.vala \
	dummy-fat-persona.vala \
	$(NULL)

libfolks_dummy_la_VALAFLAGS = \
	$(AM_VALAFLAGS) \
	$(ERROR_VALAFLAGS) \
	--vapidir=. \
	--vapidir=$(top_srcdir)/folks \
	--pkg folks \
	--pkg folks-internal \
	--pkg gee-0.8 \
	--pkg gio-2.0 \
	--pkg gobject-2.0 \
	--includedir folks \
	--gir FolksDummy-$(API_VERSION_DOT).gir \
	--library folks-dummy \
	--vapi folks-dummy.vapi \
	-H folks/folks-dummy.h \
	$(NULL)

libfolks_dummy_la_CPPFLAGS = \
	$(AM_CPPFLAGS) \
	-include $(top_srcdir)/folks/warnings.h \
	$(NULL)

libfolks_dummy_la_CFLAGS = \
	$(AM_CFLAGS) \
	$(ERROR_CFLAGS) \
	$(CODE_COVERAGE_CFLAGS) \
	$(GIO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	$(NULL)

libfolks_dummy_la_LIBADD = \
	$(AM_LIBADD) \
	$(top_builddir)/folks/libfolks.la \
	$(top_builddir)/folks/libfolks-internal.la \
	$(GIO_LIBS) \
	$(GLIB_LIBS) \
	$(GEE_LIBS) \
	$(NULL)

# The quoting here is unnecessary but harmless, and has the useful side-effect
# that vim quickfix mode (:make) doesn't interpret the libtool --mode=link
# command as an error message in a bizarrely named file
libfolks_dummy_la_LDFLAGS = \
	$(AM_LDFLAGS) \
	$(CODE_COVERAGE_LDFLAGS) \
	-version-info "$(LT_CURRENT)":"$(LT_REVISION)":"$(LT_AGE)" \
	-export-symbols-regex "^(FOLKS_DUMMY|folks_dummy)_.*|" \
	$(NULL)

folks_dummy_includedir = $(includedir)/folks
folks_dummy_include_HEADERS = \
	folks/folks-dummy.h \
	$(NULL)

vapidir = $(datadir)/vala/vapi
dist_vapi_DATA = \
	folks-dummy.vapi \
	folks-dummy.deps \
	$(NULL)

##################################################################
# General
##################################################################

CLEANFILES =
MAINTAINERCLEANFILES =
EXTRA_DIST = \
	$(pkgconfig_in) \
	$(MAINTAINERCLEANFILES) \
	$(NULL)

##################################################################
# Introspection
##################################################################

-include $(INTROSPECTION_MAKEFILE)
INTROSPECTION_SCANNER_ARGS = \
	$(ERROR_INTROSPECTION_SCANNER_ARGS) \
	--add-include-path=$(srcdir) \
	--add-include-path=$(abs_top_builddir)/folks \
	--warn-all \
	$(NULL)

# Set PKG_CONFIG_PATH so we can find the backend's uninstalled pkg-config file.
INTROSPECTION_SCANNER_ENV = \
	PKG_CONFIG_PATH=$(top_builddir)/folks:$${PKG_CONFIG_PATH}

INTROSPECTION_COMPILER_ARGS = \
	--includedir=$(srcdir) \
	--includedir=$(abs_top_builddir)/folks \
	$(NULL)

if HAVE_INTROSPECTION
FolksDummy-$(API_VERSION_DOT).gir: libfolks-dummy.la
GIRS = FolksDummy-$(API_VERSION_DOT).gir

girdir = $(datadir)/gir-1.0
dist_gir_DATA = $(GIRS)

MAINTAINERCLEANFILES += $(dist_gir_DATA)

typelibdir = $(libdir)/girepository-1.0
nodist_typelib_DATA = $(GIRS:.gir=.typelib)

CLEANFILES += $(nodist_typelib_DATA)
endif

##################################################################
# Common
##################################################################

-include $(top_srcdir)/git.mk

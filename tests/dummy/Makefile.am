AM_CFLAGS = \
	$(ERROR_CFLAGS) \
	$(NULL)

AM_CPPFLAGS = \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	-I$(top_srcdir) \
	-I$(top_srcdir)/folks \
	-I$(top_srcdir)/backends/dummy/lib \
	-I$(top_srcdir)/tests/lib \
	-I$(top_srcdir)/tests/lib/dummy \
	-include $(CONFIG_HEADER) \
	-include $(top_srcdir)/folks/warnings.h \
	$(NULL)

LDADD = \
	$(top_builddir)/tests/lib/dummy/libdummy-test.la \
	$(top_builddir)/tests/lib/libfolks-test.la \
	$(top_builddir)/backends/dummy/lib/libfolks-dummy.la \
	$(top_builddir)/folks/libfolks.la \
	$(GLIB_LIBS) \
	$(GEE_LIBS) \
	-L$(top_srcdir)/backends/dummy/lib \
	$(NULL)

AM_VALAFLAGS += \
	$(ERROR_VALAFLAGS) \
	--vapidir=. \
	--vapidir=$(top_srcdir)/folks \
	--vapidir=$(top_srcdir)/backends/dummy/lib \
	--vapidir=$(top_srcdir)/tests/lib \
	--vapidir=$(top_srcdir)/tests/lib/dummy \
	--pkg gobject-2.0 \
	--pkg gio-2.0 \
	--pkg gee-0.8 \
	--pkg folks \
	--pkg folks-dummy \
	--pkg folks-test \
	--pkg dummy-test \
	-g \
	$(NULL)

# in order from least to most complex
TESTS = \
	individual-retrieval \
	add-persona \
	$(NULL)

noinst_PROGRAMS = $(TESTS)

individual_retrieval_SOURCES = \
	individual-retrieval.vala \
	$(NULL)

add_persona_SOURCES = \
	add-persona.vala \
	$(NULL)

-include $(top_srcdir)/git.mk
-include $(top_srcdir)/valgrind.mk
-include $(top_srcdir)/check.mk

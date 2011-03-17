AM_CPPFLAGS = \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	$(TRACKER_SPARQL_CFLAGS) \
	-I$(top_srcdir)/folks \
	-I$(top_srcdir)/backends/tracker/lib \
	-I$(top_srcdir)/tests/lib \
	-I$(top_srcdir)/tests/lib/tracker \
	-include $(CONFIG_HEADER) \
	$(NULL)

LDADD = \
	$(top_builddir)/tests/lib/libfolks-test.la \
	$(top_builddir)/tests/lib/tracker/libtracker-test.la \
	$(top_builddir)/backends/tracker/lib/libfolks-tracker.la \
	$(top_builddir)/folks/libfolks.la \
	$(GLIB_LIBS) \
	$(GEE_LIBS) \
	$(TRACKER_SPARQL_LIBS) \
	-L$(top_srcdir)/backends/tracker/lib \
	$(NULL)

RUN_WITH_PRIVATE_BUS = $(top_srcdir)/tests/tools/with-session-bus-tracker.sh

AM_VALAFLAGS = \
	--vapidir=. \
	--vapidir=$(top_srcdir)/folks \
	--vapidir=$(top_srcdir)/backends/tracker/lib \
	--vapidir=$(top_srcdir)/tests/lib \
	--vapidir=$(top_srcdir)/tests/lib/tracker \
	--pkg gobject-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg folks \
	--pkg folks-test \
	--pkg folks-tracker \
	--pkg tracker-sparql-0.10 \
	--pkg tracker-test \
	$(NULL)

# in order from least to most complex
noinst_PROGRAMS = \
	individual-retrieval \
	name-details-interface \
	avatar-details-interface \
	im-details-interface \
	phone-details-interface \
	email-details-interface \
	url-details-interface \
	favourite-details-interface \
	fullname-updates \
	add-contact \
	default-contact \
	remove-contact \
	nickname-updates \
	family-name-updates \
	given-name-updates \
	additional-names-updates \
	prefix-name-updates \
	suffix-name-updates \
	website-updates \
	favourite-updates \
	emails-updates \
	phones-updates \
	imaddresses-updates \
	role-details-interface \
	birthday-details-interface \
	birthday-updates \
	note-details-interface  \
	gender-details-interface  \
	postal-address-details-interface  \
	avatar-updates  \
	$(NULL)

backend_store_key_file=$(srcdir)/data/backend-tracker-only.ini
avatar_file=$(srcdir)/data/avatar-01.jpg
TESTS_ENVIRONMENT = \
	GCONF_DEFAULT_SOURCE_PATH=@abs_top_srcdir@/tests/data/gconf.path \
	FOLKS_BACKEND_PATH=$(BACKEND_UNINST_PATH) \
	FOLKS_BACKEND_STORE_KEY_FILE_PATH=$(backend_store_key_file) \
	AVATAR_FILE_PATH=$(avatar_file) \
	$(RUN_WITH_PRIVATE_BUS) \
	--session \
	--
TESTS = $(noinst_PROGRAMS)

individual_retrieval_SOURCES = \
	individual-retrieval.vala \
	$(NULL)

name_details_interface_SOURCES = \
	name-details-interface.vala \
	$(NULL)

avatar_details_interface_SOURCES = \
	avatar-details-interface.vala \
	$(NULL)

im_details_interface_SOURCES = \
	im-details-interface.vala \
	$(NULL)

phone_details_interface_SOURCES = \
	phone-details-interface.vala \
	$(NULL)

email_details_interface_SOURCES = \
	email-details-interface.vala \
	$(NULL)

url_details_interface_SOURCES = \
	url-details-interface.vala \
	$(NULL)

favourite_details_interface_SOURCES = \
	favourite-details-interface.vala \
	$(NULL)

fullname_updates_SOURCES = \
	fullname-updates.vala \
	$(NULL)

add_contact_SOURCES = \
	add-contact.vala \
	$(NULL)

default_contact_SOURCES = \
	default-contact.vala \
	$(NULL)

remove_contact_SOURCES = \
	remove-contact.vala \
	$(NULL)

nickname_updates_SOURCES = \
	nickname-updates.vala \
	$(NULL)

family_name_updates_SOURCES = \
	family-name-updates.vala \
	$(NULL)

given_name_updates_SOURCES = \
	given-name-updates.vala \
	$(NULL)

additional_names_updates_SOURCES = \
	additional-names-updates.vala \
	$(NULL)

prefix_name_updates_SOURCES = \
	prefix-name-updates.vala \
	$(NULL)

suffix_name_updates_SOURCES = \
	suffix-name-updates.vala \
	$(NULL)

website_updates_SOURCES = \
	website-updates.vala \
	$(NULL)

favourite_updates_SOURCES = \
	favourite-updates.vala \
	$(NULL)

emails_updates_SOURCES = \
	emails-updates.vala \
	$(NULL)

phones_updates_SOURCES = \
	phones-updates.vala \
	$(NULL)

imaddresses_updates_SOURCES = \
	imaddresses-updates.vala \
	$(NULL)

role_details_interface_SOURCES = \
	role-details-interface.vala \
	$(NULL)

birthday_details_interface_SOURCES = \
	birthday-details-interface.vala \
	$(NULL)

birthday_updates_SOURCES = \
	birthday-updates.vala \
	$(NULL)

note_details_interface_SOURCES = \
	note-details-interface.vala \
	$(NULL)

gender_details_interface_SOURCES = \
	gender-details-interface.vala \
	$(NULL)

postal_address_details_interface_SOURCES = \
	postal-address-details-interface.vala \
	$(NULL)

avatar_updates_SOURCES = \
	avatar-updates.vala \
	$(NULL)

CLEANFILES = \
        *.pid \
        *.address \
        $(TESTS) \
        $(NULL)

MAINTAINERCLEANFILES = \
        $(addsuffix .c,$(noinst_PROGRAMS)) \
        individual_retrieval_vala.stamp \
        name_details_interface_vala.stamp \
        avatar_details_interface_vala.stamp \
        im_details_interface_vala.stamp \
        phone_details_interface_vala.stamp \
        email_details_interface_vala.stamp \
        url_details_interface_vala.stamp \
        favourite_details_interface_vala.stamp \
        fullname_updates_vala.stamp \
        add_contact_vala.stamp \
        default_contact_vala.stamp \
        remove_contact_vala.stamp \
        nickname_updates_vala.stamp \
        family_name_updates_vala.stamp \
        given_name_updates_vala.stamp \
        additional_names_updates_vala.stamp \
        prefix_name_updates_vala.stamp \
        suffix_name_updates_vala.stamp \
        website_updates_vala.stamp \
        favourite_updates_vala.stamp \
        emails_updates_vala.stamp \
        phones_updates_vala.stamp \
        imaddresses_updates_vala.stamp \
        role_details_interface_vala.stamp \
        birthday_details_interface_vala.stamp \
        birthday_updates_vala.stamp \
        note_details_interface_vala.stamp \
        gender_details_interface_vala.stamp \
        postal_address_details_interface_vala.stamp \
        avatar_updates_vala.stamp \
        $(NULL)

EXTRA_DIST = \
	$(MAINTAINERCLEANFILES) \
	$(backend_store_key_file) \
	$(srcdir)/data/avatar-01.jpg \
	$(NULL)

-include $(top_srcdir)/git.mk
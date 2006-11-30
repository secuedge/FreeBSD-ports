#-*- mode: makefile; tab-width: 4; -*-
# ex:ts=4
#
# $FreeBSD$
#
# bsd.lua.mk - Support for Lua based ports.
#
# Created by: Alejandro Pulver <alepulver@FreeBSD.org>
#
# Please view me with 4 column tabs!
#
# The following variables can be defined in a port that uses the Lua library,
# tolua, Ruby bindings or related components like .lua modules (with run
# and/or build dependencies). It can be used after and/or before
# bsd.port.pre.mk, but Ruby components will only work if Ruby variables (e.g.
# USE_RUBY) are defined before it (this is a bsd.ruby.mk limitation), at least
# it is manually included.
# USE_LUA		- Set to the list of Lua versions that can be used by the
#				  port. The syntax allows the following elements:
#				  - Single version (e.g. "4.0").
#				  - Range of versions (e.g. "5.0-5.1"). Must be ascending.
#				  - Partial range: single version and upper (e.g. "5.0+").
#				  - Partial range: single version and lower (e.g. "5.1-").
#				  Multiple elements can be specified separated by spaces.
# USE_LUA_NOT	- Set to the list of Lua versions that can't be used by the
#				  port. In other words, it removes some versions from USE_LUA.
#				  If the latter is not defined, it will have the value of all
#				  the possible versions. The syntax is like USE_LUA.
# LUA_COMPS		- Set to the list of Lua components the port uses. Several
#				  components can be specified separated by spaces. By default
#				  it will have the value of "lua". Suffixes in the form ":xxx"
#				  may be added to the components to determine the dependency
#				  type.
#				  The available components are:
#				  lua			- The Lua library.
#				  tolua			- The tolua library (vers 4.0-5.0).
#				  ruby			- The Ruby bindings for Lua (vers 4.0-5.0).
#				  app, compat51, dfui, filename, gettext, posix, pty and
#				  socket		- Modules for Lua 5.0.
#				  The available dependency types are:
#				  build			- Requires component for building.
#				  lib			- Requires component for building and running.
#				  run			- Requires component for running.
#				  If no suffix is present then "lib" will be used for "lua"
#				  4.0-5.0 and "ruby", "build" for lua 5.1 and "tolua" (they
#				  are static), all others default to "run".
# LUA_PREMK		- Define to determine version and define variables after
#				  <bsd.port.pre.mk> (in case the port needs to manually run
#				  the Lua program or the like).
# WANT_LUA		- Set to "yes" or a valid single version (no ranges, etc).
#				  In both cases it will detect the installed Lua components
#				  and add them to the variable HAVE_LUA. If a version is
#				  selected, HAVE_LUA will contain a list of components in the
#				  other case it will contain a list of "component-version"
#				  pairs (e.g. lua-4.0, tolua-5.1, etc).
#				  It has to be used before bsd.port.pre.mk.
# WANT_LUA_VER	- Set to the prefered Lua version for the port. It must be
#				  present in USE_LUA or missing in USE_LUA_NOT. This is
#				  overriden by the user variable WITH_LUA_VER if set. It can
#				  contain multiple versions in order of preference (last ones
#				  are tried first).
#
# The following variables are intended for the user and can be defined in
# make.conf.
# WITH_LUA_VER	- Define to the list of prefered versions in reverse order.
#
# The following variables are defined by this file, to be read from the port.
# HAVE_LUA		- The list of Lua components installed, if WANT_LUA was
#				  defined. The components will have version suffix if it was
#				  set to "yes".
# LUA_VER		- The Lua version that is going to be used (e.g. "5.1").
# LUA_VER_SH	- The Lua shared library major version (e.g. "1").
# LUA_VER_STR	- The Lua version without the dots (e.g. "51").
# LUA_PREFIX	- The prefix where Lua (and components) is installed.
# LUA_SUBDIR	- The directory under bin/share/lib where Lua is installed.
# LUA_INCDIR	- The directory where Lua and tolua header files are installed.
# LUA_LIBDIR	- The directory where Lua and tolua libraries are installed.
# LUA_MODLIBDIR	- The directory where Lua module libraries (.so) are installed.
# LUA_MODSHAREDIR
#				- The directory where Lua modules (.lua) are installed.
# LUA_PKGNAMEPREFIX
#				- The package name prefix used by Lua modules.
# LUA_CMD		- The path to the Lua interpreter.
# LUAC_CMD		- The path to the Lua compiler.
# TOLUA_CMD		- The path to the tolua program.
#
# Examples:
# - A port that needs Lua 4.0 and tolua (also 4.0) libraries (lua for building
#	and running and tolua for building).
#	USE_LUA=	4.0
#	LUA_COMPS=	lua tolua
# - A port that needs Ruby bindings for Lua 5.0 for building and running.
#	USE_LUA=	5.0
#	LUA_COMPS=	ruby
# - A port that needs tolua 5.0 or 5.1 for building.
#	USE_LUA=	5.0 5.1
#	LUA_COMPS=	tolua
# - A port that needs Lua version 5.0 or higher for building and running.
#	USE_LUA=	5.0+
# - A port that needs Lua of any version other than 5.1 for building and
#	running.
#	USE_LUA_NOT=5.1
#

LUA_Include_MAINTAINER=	alepulver@FreeBSD.org

#
# Global definitions.
#

.if !defined(_LUA_Definitions_Done)
_LUA_Definitions_Done=	yes

# Common variables:
# _LUA_COMPS_ALL		- List of valid components.
# _LUA_DEP_TYPES_ALL	- List of valid dependency types.
# _LUA_VERS_ALL			- List of available Lua versions.
# _LUA_VERS_LISTS=		- Reverse lists preference order.
# _LUA_PLIST_ALL		- List of variables to be added to PLIST_SUB.
# _LUA_PLIST_DIR_ALL	- List of path variables (relative to ${LUA_PREFIX})
#						  to be added to PLIST_SUB.
#

_LUA_COMPS_ALL=			lua tolua ruby \
						app compat51 dfui filename gettext posix pty socket
_LUA_DEP_TYPES_ALL=		build lib run
_LUA_VERS_ALL=			4.0 5.0 5.1
_LUA_PLIST_ALL=			LUA_VER LUA_VER_SH LUA_VER_STR LUA_PREFIX LUA_SUBDIR
_LUA_PLIST_DIR_ALL=		LUA_BINDIR LUA_INCDIR LUA_LIBDIR \
						LUA_MODLIBDIR LUA_MODSHAREDIR
_LUA_VERS_LISTS=		WANT_LUA_VER WITH_LUA_VER

#
# Variables used to determine what is needed.
# _LUA_PORT_comp_ver	- Port directory.
# _LUA_LIB_comp_ver		- Name of the shared library (optional).
# _LUA_SHVER_comp_ver	- Shared library version (optional).
# _LUA_FILE_comp_ver	- File installed by that component.
# _LUA_DEPTYPE_comp_ver	- Default dependency type.
#

_LUA_PORT_lua_4.0=		lang/lua4
_LUA_DEPTYPE_lua_4.0=	lib
_LUA_PORT_tolua_4.0=	lang/tolua4
_LUA_PORT_ruby_4.0=		lang/ruby-lua4

_LUA_PORT_lua_5.0=		lang/lua50
_LUA_DEPTYPE_lua_5.0=	lib
_LUA_PORT_tolua_5.0=	lang/tolua
_LUA_PORT_ruby_5.0=		lang/ruby-lua

_LUA_PORT_app_5.0=		devel/lua50-app
_LUA_PORT_compat51_5.0=	devel/lua50-compat51
_LUA_FILE_compat51_5.0=	${LUA_MODSHAREDIR}/compat-5.1.lua
_LUA_PORT_dfui_5.0=		devel/lua50-dfui
_LUA_PORT_filename_5.0=	devel/lua50-filename
_LUA_PORT_gettext_5.0=	devel/lua50-gettext
_LUA_PORT_posix_5.0=	devel/lua50-posix
_LUA_PORT_pty_5.0=		devel/lua50-pty
_LUA_PORT_socket_5.0=	net/luasocket

_LUA_PORT_lua_5.1=		lang/lua
_LUA_DEPTYPE_lua_5.1=	build

_LUA_PORT_filename_5.1= devel/lua-filename
_LUA_PORT_gettext_5.1=  devel/lua-gettext
_LUA_PORT_posix_5.1=    devel/lua-posix

.for comp in ${_LUA_COMPS_ALL}
_LUA_COMP=				${comp}
.	for ver in ${_LUA_VERS_ALL}
.		if ${_LUA_COMP} == "lua"
_LUA_LIB_${comp}_${ver}=	lua-${LUA_VER}.${LUA_VER_SH}
_LUA_SHVER_${comp}_${ver}=	${LUA_VER_SH}
_LUA_FILE_${comp}_${ver}=	${LUA_LIBDIR}/liblua.a
.		elif ${_LUA_COMP} == "tolua"
_LUA_FILE_${comp}_${ver}=	${LUA_LIBDIR}/libtolua.a
_LUA_DEPTYPE_${comp}_${ver}=build
.		elif ${_LUA_COMP} == "ruby"
_LUA_FILE_${comp}_${ver}=	${RUBY_SITEARCHLIBDIR}/lua-${LUA_VER}.so
_LUA_DEPTYPE_${comp}_${ver}=lib
.		else
.			if !defined(_LUA_FILE_${comp}_${ver})
_LUA_FILE_${comp}_${ver}=	${LUA_MODSHAREDIR}/${comp}.lua
.			endif
_LUA_DEPTYPE_${comp}_${ver}=run
.		endif
.	endfor
.endfor

.endif

#
# Check for present components.
#

.if defined(WANT_LUA) && defined(BEFOREPORTMK)
.	for __WANT_LUA in ${WANT_LUA}
# Check if WANT_LUA contains more than one word.
.		if defined(HAVE_LUA)
IGNORE?=				selected multiple values for WANT_LUA: ${WANT_LUA}
.		endif
HAVE_LUA=				#
# Check for all versions.
.		if ${WANT_LUA:L} == "yes"
.			for comp in ${_LUA_COMPS_ALL}
.				for ver in ${_LUA_VERS_ALL}
_LUA_COMP=				_LUA_FILE_${comp}_${ver}
.					if defined(${_LUA_COMP}) && exists(${${_LUA_COMP}})
HAVE_LUA+=				${comp}-${ver}
.					endif
.				endfor
.			endfor
# Check for a specific version.
.		elif ${_LUA_VERS_ALL:M${__WANT_LUA}} != ""
.			for comp in ${_LUA_COMPS_ALL}
.				if exists(${_LUA_FILE_${comp}_${__WANT_LUA}})
HAVE_LUA+=				${comp}
.				endif
.			endfor
.		else
IGNORE?=				selected an invalid value for WANT_LUA: ${__WANT_LUA}
.		endif
.	endfor
.endif		# WANT_LUA && BEFOREPORTMK

#
# Select Lua version.
#

.if !defined(_LUA_Version_Done) && (defined(_POSTMKINCLUDED) || \
    (defined(LUA_PREMK) && defined(BEFOREPORTMK) && \
    (defined(USE_LUA) || defined(USE_LUA_NOT))))
_LUA_Version_Done=		yes

# Set defaults (if one isn't present).

USE_LUA?=				${_LUA_VERS_ALL}
USE_LUA_NOT?=			#

#
# Make lists of valid and invalid versions.
#
# The following variables are used:
# _LUA_VER_CHECK		- If the version is a single one, express in a range.
# _LUA_VER_MIN			- Lower version of the range.
# _LUA_VER_MAX			- Higher version of the range.
# _LUA_VER_LIST			- List of requested versions.
# _LUA_VER_NOT_LIST		- List of disallowed versions.
# _LUA_VER_FINAL		- List of requested version without disallowed ones.
#

.for list in VER VER_NOT
_LUA_${list}_LIST=		#
.	for ver in ${USE_LUA${list:C/VER//}}
_LUA_VER_CHECK:=		${ver:C/^([[:digit:]]+(\.[[:digit:]]+)*)$/\1-\1/}
_LUA_VER_MIN:=			${_LUA_VER_CHECK:C/([[:digit:]]+(\.[[:digit:]]+)*)[-+].*/\1/}
_LUA_VER_MAX:=			${_LUA_VER_CHECK:C/.*-([[:digit:]]+(\.[[:digit:]]+)*)/\1/}
# Minimum version not specified.
.		if ${_LUA_VER_MIN} == ${_LUA_VER_CHECK}
.			undef _LUA_VER_MIN
.			for v in ${_LUA_VERS_ALL}
_LUA_VER_MIN?=			${v}
.			endfor
.		endif
# Maximum version not specified.
.		if ${_LUA_VER_MAX} == ${_LUA_VER_CHECK}
.			for v in ${_LUA_VERS_ALL}
_LUA_VER_MAX=			${v}
.			endfor
.		endif
# Expand versions and add valid ones to each list.
.		for v in ${_LUA_VERS_ALL}
.			if ${_LUA_VER_MIN} <= ${v} && ${_LUA_VER_MAX} >= ${v} && \
			   ${_LUA_${list}_LIST:M${v}} == ""
_LUA_${list}_LIST+=		${v}
.			endif
.		endfor
.	endfor
.endfor

# Merge the lists into a single list of valid versions.

_LUA_VER_FINAL=			#
.for ver in ${_LUA_VER_LIST}
.	if ${_LUA_VER_NOT_LIST:M${ver}} == ""
_LUA_VER_FINAL+=		${ver}
.	endif
.endfor

# Check for a null version.

.if empty(_LUA_VER_FINAL)
IGNORE?=				selected a null or invalid Lua version
.endif

#
# Choose final version.
#

#
# Check for the following (in order):
# 1) WITH_LUA_VER		- User preference.
# 2) WANT_LUA_VER		- Port preference.
# 3) _LUA_VER_FINAL		- Available versions.
#

.for list in _LUA_VER_FINAL ${_LUA_LISTS_ORDER}
.	if defined(${list})
.		for ver in ${${list}}
.			if ${_LUA_VER_FINAL:M${ver}} != ""
_LUA_VER=				${ver}
.			endif
.		endfor
.	endif
.endfor

#
# Set variables.
#

# Version.
LUA_VER?=				${_LUA_VER}
LUA_VER_SH?=			${LUA_VER:C/[[:digit:]]\.([[:digit:]])/\1/}
LUA_VER_STR?=			${LUA_VER:S/.//g}

# Paths.
LUA_PREFIX?=			${LOCALBASE}
LUA_SUBDIR?=			lua${LUA_VER_STR}
LUA_BINDIR?=			${LUA_PREFIX}/bin/${LUA_SUBDIR}
LUA_INCDIR?=			${LUA_PREFIX}/include/${LUA_SUBDIR}
LUA_LIBDIR?=			${LUA_PREFIX}/lib/${LUA_SUBDIR}
LUA_MODLIBDIR?=			${LUA_PREFIX}/lib/lua/${LUA_VER}
LUA_MODSHAREDIR?=		${LUA_PREFIX}/share/lua/${LUA_VER}

# Package name.
LUA_PKGNAMEPREFIX?=		lua${LUA_VER_STR}-

# Programs.
LUA_CMD?=				${LUA_PREFIX}/bin/lua-${LUA_VER}
LUAC_CMD?=				${LUA_PREFIX}/bin/luac-${LUA_VER}
TOLUA_CMD?=				${LUA_PREFIX}/bin/tolua-${LUA_VER}

.endif		# !_LUA_Version_Done && (_POSTMKINCLUDED || \
#			(LUA_PREMK && BEFOREPORTMK && (USE_LUA || USE_LUA_NOT)))

#
# Process components list and add dependencies, variables, etc.
#

.if defined(_POSTMKINCLUDED)

#
# Component parsing.
#
# The variables used are:
# _LUA_COMP				- Component part.
# _LUA_DEP_TYPE			- Dependency type part.
# _LUA_COMP_NEW			- Component + dependency type.
# _LUA_COMPS_FINAL		- Final list of components with dependency types.
#

# Default components.

LUA_COMPS?=				lua

# Detect invalid and duplicated components.

_LUA_COMPS_FINAL=		#
.for comp in ${LUA_COMPS}
_LUA_COMP=				${comp:C/:([[:alpha:]]+)$//}
.	if ${_LUA_COMP} == ${comp}
_LUA_DEP_TYPE=			${_LUA_DEPTYPE_${comp}_${_LUA_VER}}
.	else
_LUA_DEP_TYPE=			${comp:C/.+:([[:alpha:]]+)$/\1/}
.	endif
_LUA_COMP_NEW=			${_LUA_COMP}_${_LUA_DEP_TYPE}
.	for __LUA_COMP in ${_LUA_COMP}
.		if ${_LUA_COMPS_ALL:M${__LUA_COMP}} == ""
IGNORE?=				selected an invalid Lua component: ${__LUA_COMP}
.		endif
.	endfor
.	for __LUA_DEP_TYPE in ${_LUA_DEP_TYPE}
.		if ${_LUA_DEP_TYPES_ALL:M${__LUA_DEP_TYPE}} == ""
IGNORE?=				selected an invalid Lua dependency type: ${__LUA_DEP_TYPE}
.		endif
.	endfor
.	if !defined(_LUA_PORT_${_LUA_COMP}_${_LUA_VER})
IGNORE?=				selected a Lua component (${_LUA_COMP}) which is not available for the selected version (${_LUA_VER})
.	endif
.	for newcomp in ${_LUA_COMP_NEW}
.		if ${_LUA_COMPS_FINAL:M${newcomp}} == ""
_LUA_COMPS_FINAL+=		${newcomp}
.		endif
.	endfor
.endfor

# Add dependencies.
#
# The variable used are:
# _LUA_COMP		-		- Component part.
# _LUA_DEP_TYPE			- Dependency type part.

.for comp in ${_LUA_COMPS_FINAL}
_LUA_DEP_TYPE=			${comp:C/.+_([[:alpha:]]+)$/\1/}
_LUA_COMP=				${comp:C/_([[:alpha:]]+)$//}
# XXX Need a .for loop here so the variable is expanded before the assignment.
.	for comp_part in ${_LUA_COMP}
.		if ${_LUA_DEP_TYPE} == "lib"
.			if defined(_LUA_LIB_${comp_part}_${_LUA_VER})
LIB_DEPENDS+=			${_LUA_LIB_${comp_part}_${_LUA_VER}}:${PORTSDIR}/${_LUA_PORT_${comp_part}_${_LUA_VER}}
.			else
BUILD_DEPENDS+=			${_LUA_FILE_${comp_part}_${_LUA_VER}}:${PORTSDIR}/${_LUA_PORT_${comp_part}_${_LUA_VER}}
RUN_DEPENDS+=			${_LUA_FILE_${comp_part}_${_LUA_VER}}:${PORTSDIR}/${_LUA_PORT_${comp_part}_${_LUA_VER}}
.			endif
.		else
${_LUA_DEP_TYPE:U}_DEPENDS+=	${_LUA_FILE_${comp_part}_${_LUA_VER}}:${PORTSDIR}/${_LUA_PORT_${comp_part}_${_LUA_VER}}
.		endif
.	endfor
.endfor

# Packaging list variables.
.for var in ${_LUA_PLIST_ALL}
PLIST_SUB+=				${var}="${${var}}"
.endfor
.for var in ${_LUA_PLIST_DIR_ALL}
PLIST_SUB+=				${var}="${${var}:S/${LUA_PREFIX}\///}"
.endfor
.for var in ${_LUA_PLIST_ALL} ${_LUA_PLIST_DIR_ALL}
MAKE_ENV+=				${var}="${${var}}"
.endfor

.endif		# _POSTMKINCLUDED

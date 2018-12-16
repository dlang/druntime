/**
 * Support code for fibers and multithreading.
 *
 * Copyright: Copyright Mikola Lysenko 2005 - 2012.
 * License: Distributed under the
 *      $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE)
 * Authors:   Mikola Lysenko
 * Source:    $(DRUNTIMESRC core/internal/threadasm/_common.S)
 */

#if (__linux__ || __FreeBSD__ || __NetBSD__ || __DragonFly__) && __ELF__
/*
 * Mark the resulting object file as not requiring execution permissions on
 * stack memory. The absence of this section would mark the whole resulting
 * library as requiring an executable stack, making it impossible to
 * dynamically load druntime on several Linux platforms where this is
 * forbidden due to security policies.
 */
.section .note.GNU-stack,"",%progbits
#endif

/* Let preprocessor tell us if C symbols have a prefix: __USER_LABEL_PREFIX__ */
#ifdef __USER_LABEL_PREFIX__
#define GLUE2(a, b) a ## b
#define GLUE(a, b) GLUE2(a, b)
#define CSYM(name) GLUE(__USER_LABEL_PREFIX__, name)
#else
#define CSYM(name) name
#endif


// This file contains defines allowing targeting byond versions newer than the supported

//Update this whenever you need to take advantage of more recent byond features
#define MIN_COMPILER_VERSION 515
#define MIN_COMPILER_BUILD 1609
#if (DM_VERSION < MIN_COMPILER_VERSION || DM_BUILD < MIN_COMPILER_BUILD) && !defined(SPACEMAN_DMM) && !defined(OPENDREAM)
//Don't forget to update this part
#error Your version of BYOND is too out-of-date to compile this project. Go to https://www.byond.com/download and update.
#error You need version 515.1609 or higher
#endif

// So we want to have compile time guarantees these methods exist on local type, unfortunately 515 killed the .proc/procname and .verb/verbname syntax so we have to use nameof()
// For the record: GLOBAL_VERB_REF would be useless as verbs can't be global.

/// Call by name proc references, checks if the proc exists on either this type or as a global proc.
#define PROC_REF(X) (.proc/##X)
/// Call by name verb references, checks if the verb exists on either this type or as a global verb.
#define VERB_REF(X) (.verb/##X)

/// Call by name proc reference, checks if the proc exists on either the given type or as a global proc
#define TYPE_PROC_REF(TYPE, X) (##TYPE.proc/##X)
/// Call by name verb reference, checks if the verb exists on either the given type or as a global verb
#define TYPE_VERB_REF(TYPE, X) (##TYPE.verb/##X)

/// Call by name proc reference, checks if the proc is an existing global proc
#define GLOBAL_PROC_REF(X) (/proc/##X)

/// fcopy will crash on 515 linux if given a non-existant file, instead of returning 0 like on 514 linux or 515 windows
/// var case matches documentation for fcopy.
/world/proc/__fcopy(Src, Dst)
	if (istext(Src) && !fexists(Src))
		return 0
	return fcopy(Src, Dst)

#define fcopy(Src, Dst) world.__fcopy(Src, Dst)


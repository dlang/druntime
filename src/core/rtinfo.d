/**
    The purpose of this module is to be replaced by the user. This file
    does nothing, providing a simple default if the user doesn't care.

    If you do care, you copy this file into your own project and add whatever
    you want here: data or checks. When compiling your project, be sure to
    include your custom module with all the files of your project.
*/
module core.rtinfo;

/// The only member of this file is this mixin template. It is passed
/// all types in the program. You may perform static asserts or add
/// static constructors to build runtime lists.
///
/// While it isn't an error to add data, it is also useless because
/// there is no way to retrieve it.
mixin template ProjectRTInfo(T) {}

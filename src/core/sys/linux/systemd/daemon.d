/**
 * A module to interface with the systemd's daemon control system.
 *
 * License : $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Authors  : Nemanja Boric
 */
module core.sys.linux.systemd.daemon;

version (linux):

extern (C):
@system:
nothrow:
@nogc:

import core.sys.posix.sys.types: pid_t;

/**

    May be called by a service to notify the service manager about state changes.
    It can be used to send arbitrary information, encoded in an
    environment-block-like string. Most importantly, can be used for start-up
    completion notification.

    Params:
    unset_environment =-if non-zero, this method will unset the $NOTIFY_SOCKET
                        env. variable before returning (regardless of whether
                        the function call itself succeeded or not. Further calls to
                        this method will then fail, but the variable is no longer
                        inherited by child process.
    state = should contain a newline-separated list of variable assignments,
            similar in style to environment block. See `man 3 sd_notify` for
            more details.

    Returns:
        on failure, returns a negative errno-style error code. If $NOTIFY_SOCKET
        was not set and hence no status data could be sent, 0 is returned.
        If succeeded, function will return a positive return value. In order to
        support both, init systems that implement this scheme and those which
        do not, it is generally recommended to ignore the return value of this
        call.

*/

int sd_notify ( int unset_environment,
                scope const char* state );

/**

    May be called by a service to notify the service manager about state changes.
    It can be used to send arbitrary information, encoded in an
    environment-block-like string. Most importantly, can be used for start-up
    completion notification.

    Params:
    unset_environment =-if non-zero, this method will unset the $NOTIFY_SOCKET
                        env. variable before returning (regardless of whether
                        the function call itself succeeded or not. Further calls to
                        this method will then fail, but the variable is no longer
                        inherited by child process.
    format = like state in `sd_notify`, but `printf()`-like format string/arguments

    Returns:
        on failure, returns a negative errno-style error code. If $NOTIFY_SOCKET
        was not set and hence no status data could be sent, 0 is returned.
        If succeeded, function will return a positive return value. In order to
        support both, init systems that implement this scheme and those which
        do not, it is generally recommended to ignore the return value of this
        call.

*/

int sd_notifyf ( int unset_environment,
                 scope const char* format,
                 ... );

/**

    May be called by a service to notify the service manager about state changes.
    It can be used to send arbitrary information, encoded in an
    environment-block-like string. Most importantly, can be used for start-up
    completion notification.

    Params:

    pid = originating PID for the message as first argument. This is
    useful to send notification messages on behalf of other processes, provided
    the appropriate privileges are available. If 0, the process ID to the
    calling process is used, which makes this call fully equivalent to `sd_notify`

    unset_environment =-if non-zero, this method will unset the $NOTIFY_SOCKET
                        env. variable before returning (regardless of whether
                        the function call itself succeeded or not. Further calls to
                        this method will then fail, but the variable is no longer
                        inherited by child process.
    state = should contain a newline-separated list of variable assignments,
            similar in style to environment block. See `man 3 sd_notify` for
            more details.

    Returns:
        on failure, returns a negative errno-style error code. If $NOTIFY_SOCKET
        was not set and hence no status data could be sent, 0 is returned.
        If succeeded, function will return a positive return value. In order to
        support both, init systems that implement this scheme and those which
        do not, it is generally recommended to ignore the return value of this
        call.

*/

int sd_pid_notify ( pid_t pid,
                int unset_environment,
                scope const char* state );

/**

    May be called by a service to notify the service manager about state changes.
    It can be used to send arbitrary information, encoded in an
    environment-block-like string. Most importantly, can be used for start-up
    completion notification.

    Params:

    pid = originating PID for the message as first argument. This is
    useful to send notification messages on behalf of other processes, provided
    the appropriate privileges are available. If 0, the process ID to the
    calling process is used, which makes this call fully equivalent to `sd_notifyf`

    unset_environment =-if non-zero, this method will unset the $NOTIFY_SOCKET
                        env. variable before returning (regardless of whether
                        the function call itself succeeded or not. Further calls to
                        this method will then fail, but the variable is no longer
                        inherited by child process.
    format = like state in `sd_notify`, but `printf()`-like format string/arguments

    Returns:
        on failure, returns a negative errno-style error code. If $NOTIFY_SOCKET
        was not set and hence no status data could be sent, 0 is returned.
        If succeeded, function will return a positive return value. In order to
        support both, init systems that implement this scheme and those which
        do not, it is generally recommended to ignore the return value of this
        call.

*/

int sd_pid_notifyf ( pid_t pid,
                 int unset_environment,
                 scope const char* format,
                 ... );

/**

    May be called by a service to notify the service manager about state changes.
    It can be used to send arbitrary information, encoded in an
    environment-block-like string. Most importantly, can be used for start-up
    completion notification.

    Params:

    pid = originating PID for the message as first argument. This is
    useful to send notification messages on behalf of other processes, provided
    the appropriate privileges are available. If 0, the process ID to the
    calling process is used, which makes this call fully equivalent to `sd_notify`

    unset_environment =-if non-zero, this method will unset the $NOTIFY_SOCKET
                        env. variable before returning (regardless of whether
                        the function call itself succeeded or not. Further calls to
                        this method will then fail, but the variable is no longer
                        inherited by child process.
    state = should contain a newline-separated list of variable assignments,
            similar in style to environment block. See `man 3 sd_notify` for
            more details.

    fds = array of file descriptors that are sent along the notification message
          to the service manager.

    nfds = number of file descriptors contained in fds

    Returns:
        on failure, returns a negative errno-style error code. If $NOTIFY_SOCKET
        was not set and hence no status data could be sent, 0 is returned.
        If succeeded, function will return a positive return value. In order to
        support both, init systems that implement this scheme and those which
        do not, it is generally recommended to ignore the return value of this
        call.

*/

int sd_pid_notify_with_fds ( pid_t pid,
                int unset_environment,
                scope const char* state,
                scope const int* fds,
                uint n_fds );

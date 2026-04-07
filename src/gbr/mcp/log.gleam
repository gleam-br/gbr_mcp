////
//// 🗃️ RFC 5424: Log types and helper functions
////
//// This protocol has been used for the transmission of event
//// notification messages across networks for many years.  While this
//// protocol was originally developed on the University of California
//// Berkeley Software Distribution (BSD) TCP/IP system implementations,
//// its value to operations and management has led it to be ported to
//// many other operating systems as well as being embedded into many
//// other networked devices.
////
//// https://datatracker.ietf.org/doc/html/rfc3164
////

import gleam.{Error as GleamError}

/// Log level type
///
/// https://datatracker.ietf.org/doc/html/rfc3164#section-4.1.1
///
pub type Level {
  Debug
  Info
  Notice
  Warning
  Error
  Critical
  Alert
  Emergency
}

/// Log level from string representation.
///
/// - string: Level log string format.
///
/// https://datatracker.ietf.org/doc/html/rfc3164#section-4.1.1
///
pub fn from_string(string) {
  case string {
    "debug" -> Ok(Debug)
    "info" -> Ok(Info)
    "notice" -> Ok(Notice)
    "warning" -> Ok(Warning)
    "error" -> Ok(Error)
    "critical" -> Ok(Critical)
    "alert" -> Ok(Alert)
    "emergency" -> Ok(Emergency)
    _ -> GleamError(Nil)
  }
}

/// Log level to string representation.
///
/// - level: Level log type
///
/// https://datatracker.ietf.org/doc/html/rfc3164#section-4.1.1
///
pub fn to_string(level) {
  case level {
    Debug -> "debug"
    Info -> "info"
    Notice -> "notice"
    Warning -> "warning"
    Error -> "error"
    Critical -> "critical"
    Alert -> "alert"
    Emergency -> "emergency"
  }
}

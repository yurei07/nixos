pragma Singleton

import Quickshell
import qs.Commons

Singleton {
  id: root

  function _formatMessage(...args) {
    var t = Time.getFormattedTimestamp()
    if (args.length > 1) {
      const maxLength = 14
      var module = args.shift().substring(0, maxLength).padStart(maxLength, " ")
      return `\x1b[36m[${t}]\x1b[0m \x1b[35m${module}\x1b[0m ` + args.join(" ")
    } else {
      return `[\x1b[36m[${t}]\x1b[0m ` + args.join(" ")
    }
  }

  function log(...args) {
    var msg = _formatMessage(...args)
    console.log(msg)
  }

  function warn(...args) {
    var msg = _formatMessage(...args)
    console.warn(msg)
  }

  function error(...args) {
    var msg = _formatMessage(...args)
    console.error(msg)
  }
}

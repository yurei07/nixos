import QtQuick
import Quickshell
import qs.Commons

import "../../Helpers/AdvancedMath.js" as AdvancedMath

QtObject {
  id: calculator

  // Function to evaluate mathematical expressions
  function evaluate(expression) {
    if (!expression || expression.trim() === "") {
      return {
        "isValid": false,
        "result": "",
        "displayResult": "",
        "error": "Empty expression"
      }
    }

    try {
      // Try advanced math first
      if (typeof AdvancedMath !== 'undefined') {
        const result = AdvancedMath.evaluate(expression.trim())
        const displayResult = AdvancedMath.formatResult(result)

        return {
          "isValid": true,
          "result": result,
          "displayResult": displayResult,
          "expression": expression,
          "error": ""
        }
      } else {
        // Fallback to basic evaluation
        Logger.warn("Calculator", "AdvancedMath not available, using basic eval")

        // Basic preprocessing for common functions
        var processed = expression.trim(
              ).replace(/\bpi\b/gi,
                        Math.PI).replace(/\be\b/gi,
                                         Math.E).replace(/\bsqrt\s*\(/g,
                                                         'Math.sqrt(').replace(/\bsin\s*\(/g,
                                                                               'Math.sin(').replace(/\bcos\s*\(/g,
                                                                                                    'Math.cos(').replace(/\btan\s*\(/g, 'Math.tan(').replace(/\blog\s*\(/g, 'Math.log10(').replace(/\bln\s*\(/g, 'Math.log(').replace(/\bexp\s*\(/g, 'Math.exp(').replace(/\bpow\s*\(/g, 'Math.pow(').replace(/\babs\s*\(/g, 'Math.abs(')

        // Sanitize and evaluate
        if (!/^[0-9+\-*/().\s\w,]+$/.test(processed)) {
          throw new Error("Invalid characters in expression")
        }

        const result = eval(processed)

        if (!isFinite(result) || isNaN(result)) {
          throw new Error("Invalid result")
        }

        const displayResult = Number.isInteger(result) ? result.toString() : result.toFixed(6).replace(/\.?0+$/, '')

        return {
          "isValid": true,
          "result": result,
          "displayResult": displayResult,
          "expression": expression,
          "error": ""
        }
      }
    } catch (error) {
      return {
        "isValid": false,
        "result": "",
        "displayResult": "",
        "error": error.message || error.toString()
      }
    }
  }

  // Generate calculator entry for display
  function createEntry(expression, searchContext = "") {
    const evaluation = evaluate(expression)

    if (!evaluation.isValid) {
      return {
        "isCalculator": true,
        "name": "Invalid expression",
        "content": evaluation.error,
        "icon": "error",
        "execute": function () {// Do nothing for invalid expressions
        }
      }
    }

    const displayName = searchContext
                      === "calc" ? `${expression} = ${evaluation.displayResult}` : `${expression} = ${evaluation.displayResult}`

    return {
      "isCalculator": true,
      "name": displayName,
      "result": evaluation.result,
      "expr": expression,
      "displayResult": evaluation.displayResult,
      "icon": "calculate",
      "execute": function () {
        Quickshell.clipboardText = evaluation.displayResult
        // Also copy using shell command for better compatibility
        Quickshell.execDetached(
              ["sh", "-lc", `printf %s ${evaluation.displayResult} | wl-copy -t text/plain;charset=utf-8`])
        Quickshell.execDetached(
              ["notify-send", "Calculator", `${expression} = ${evaluation.displayResult} (copied to clipboard)`])
      }
    }
  }

  // Create placeholder entry for empty calculator mode
  function createPlaceholderEntry() {
    return {
      "isCalculator": true,
      "name": "Calculator",
      "content": "Try: sqrt(16), sin(1), cos(0), pi*2, exp(1), pow(2,8), abs(-5)",
      "icon": "calculate",
      "execute": function () {// Do nothing for placeholder
      }
    }
  }

  // Process calculator queries
  function processQuery(query, searchContext = "") {
    const results = []

    if (searchContext === "calc") {
      // Handle ">calc" mode
      const expr = query.slice(5).trim()
      if (expr && expr !== "") {
        results.push(createEntry(expr, "calc"))
      } else {
        results.push(createPlaceholderEntry())
      }
    } else if (query.startsWith(">") && query.length > 1 && !query.startsWith(">clip") && !query.startsWith(">calc")) {
      // Handle direct math expressions after ">"
      const mathExpr = query.slice(1).trim()
      const evaluation = evaluate(mathExpr)

      if (evaluation.isValid) {
        results.push(createEntry(mathExpr, "direct"))
      }
      // If invalid, don't add anything - let it fall through to regular search
    }

    return results
  }
}

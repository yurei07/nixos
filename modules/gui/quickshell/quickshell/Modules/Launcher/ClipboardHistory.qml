import QtQuick
import Quickshell
import qs.Commons
import qs.Services

QtObject {
  id: clipboardHistory

  function parseImageMeta(preview) {
    const re = /\[\[\s*binary data\s+([\d\.]+\s*(?:KiB|MiB|GiB|B))\s+(\w+)\s+(\d+)x(\d+)\s*\]\]/i
    const m = (preview || "").match(re)
    if (!m) return null
    return { size: m[1], fmt: (m[2] || "").toUpperCase(), w: Number(m[3]), h: Number(m[4]) }
  }

  function formatTextPreview(preview) {
    const normalized = (preview || "").replace(/\s+/g, ' ').trim()
    const lines = normalized.split(/\n+/)
    const title = (lines[0] || "Text").slice(0, 60)
    let subtitle = ""
    if (lines.length > 1) {
      subtitle = lines[1].slice(0, 80)
    } else {
      subtitle = `${normalized.length} chars`
    }
    return { title, subtitle }
  }

  function createClipboardEntry(item) {
    if (item.isImage) {
      const meta = parseImageMeta(item.preview)
      const title = meta ? `Image ${meta.w}×${meta.h}` : "Image"
      const subtitle = meta ? `${meta.size} · ${meta.fmt}` : (item.preview || "")
      return {
        "isClipboard": true,
        "name": title,
        "content": subtitle,
        "icon": "image",
        "type": 'image',
        "id": item.id,
        "mime": item.mime
      }
    } else {
      const parts = formatTextPreview(item.preview)
      return {
        "isClipboard": true,
        "name": parts.title,
        "content": parts.subtitle,
        "icon": "content_paste",
        "type": 'text',
        "id": item.id
      }
    }
  }

  function createEmptyEntry() {
    return {
      "isClipboard": true,
      "name": "No clipboard history",
      "content": "No matching clipboard entries found",
      "icon": "content_paste_off",
      "execute": function () {}
    }
  }

  function processQuery(query, items) {
    const results = []
    if (!query.startsWith(">clip")) {
      return results
    }

    const searchTerm = query.slice(5).trim().toLowerCase()

    // Dependency hook without side effects
    const _rev = CliphistService.revision
    const source = items || CliphistService.items

    source.forEach(function (item) {
      const hay = (item.preview || "").toLowerCase()
      if (!searchTerm || hay.indexOf(searchTerm) !== -1) {
        const entry = createClipboardEntry(item)
        // Attach execute at this level to avoid duplicating functions
        entry.execute = function () {
          CliphistService.copyToClipboard(item.id)
        }
        results.push(entry)
      }
    })

    if (results.length === 0) {
      results.push(createEmptyEntry())
    }

    return results
  }

  function refresh() {
    CliphistService.list(100)
  }

  function clearAll() {
    CliphistService.wipeAll()
  }
}

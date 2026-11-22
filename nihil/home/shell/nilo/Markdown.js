.pragma library

// Quotes too: an address with one in it would end href="…" and add attributes of its own (a second href).
function escape(text) {
    return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;").replace(/'/g, "&#39;");
}

// The host a link goes to, shown while the pointer is on it.
function host(link) {
    const m = /^https?:\/\/([^\/?#]+)/i.exec(String(link ?? ""));
    return m ? m[1] : "";
}

function fence(line) {
    const m = /^(\s*)```/.exec(line);
    return m ? m[1].length : -1;
}

function language(line) {
    const m = /^\s*```\s*([\w+#.-]+)/.exec(line);
    return m ? m[1] : "";
}

function dedent(line, indent) {
    let i = 0;
    while (i < indent && i < line.length && (line[i] === " " || line[i] === "\t"))
        i++;
    return line.slice(i);
}

// An address, with the parentheses it has in pairs: …/wiki/Nix_(package_manager) whole.
const ADDRESS = "https?:\\/\\/(?:[^\\s<()]|\\([^\\s<()]*\\))+";

function emphasis(text) {
    return text.replace(/\*\*([^*\n]+)\*\*/g, "<b>$1</b>")
        .replace(/~~([^~\n]+)~~/g, "<s>$1</s>")
        .replace(/(^|[^*\w])\*([^*\s][^*\n]*?)\*(?![*\w])/g, "$1<i>$2</i>")
        .replace(/(^|[^\w])_([^_\s][^_\n]*?)_(?!\w)/g, "$1<i>$2</i>");
}

// Code and links are set aside before the emphasis, so an address's _ or * stay as they are.
function inline(text, s) {
    const codes = [];
    const links = [];
    const aside = (list, mark, value) => { list.push(value); return mark + (list.length - 1) + mark; };
    const link = (url, label) => aside(links, "\u0002", `<a href="${url}" style="color:${s.ink};">${label}</a>`);
    let out = text.replace(/`([^`\n]+)`/g, (m, code) => aside(codes, "\u0001", code));
    out = out.replace(new RegExp("\\[([^\\]\\n]+)\\]\\((" + ADDRESS + ")\\)", "g"),
        (m, label, url) => link(url, emphasis(label)));
    out = out.replace(new RegExp("(^|[\\s(])(" + ADDRESS + ")", "g"), (m, before, url) => {
        const end = /[.,;:!?»”]+$/.exec(url);      // what ends the sentence, not the address
        const bare = end ? url.slice(0, -end[0].length) : url;
        return before + link(bare, bare) + (end ? end[0] : "");
    });
    out = emphasis(out).replace(/\u0002(\d+)\u0002/g, (m, i) => links[+i]);
    return out.replace(/\u0001(\d+)\u0001/g,
        (m, i) => `<span style="font-family:'${s.mono}'; font-size:13px; color:${s.code};">${codes[+i]}</span>`);
}

// A task's mark, open or done: with s.tasks, a link to tick it, task:<its line>.
function task(done, line, s) {
    const mark = `<span style="font-family:'${s.icons}'; color:${done ? s.ink : s.dim};">${done ? "&#xF0133;" : "&#xF0130;"}</span>`;
    return s.tasks ? `<a href="task:${line}" style="text-decoration:none;">${mark}</a>` : mark;
}

// s: the colours and fonts (ink, dim, code, surface, mono, icons); with s.breaks, a line's end
// is one in what shows too, as in a note, rather than a space.
function html(text, s) {
    const lines = escape(String(text ?? "")).split("\n");
    const out = [];
    let para = [];
    let quote = [];
    let list = null;
    let code = null;
    let indent = 0;
    const p = "margin-top:0px; margin-bottom:10px;";
    const joined = parts => parts.join(s.breaks ? "<br>" : " ");

    function flushPara() {
        if (para.length) out.push(`<p style="${p}">${inline(joined(para), s)}</p>`);
        para = [];
        if (quote.length) out.push(`<p style="${p} margin-left:12px; color:${s.dim};">${inline(joined(quote), s)}</p>`);
        quote = [];
    }
    function flushList() {
        if (list) {
            out.push(`<${list.tag} style="margin-top:0px; margin-bottom:10px; margin-left:-18px;">`
                + list.items.map(item => `<li style="margin-bottom:4px;">${inline(item, s)}</li>`).join("")
                + `</${list.tag}>`);
        }
        list = null;
    }
    function flushCode() {
        out.push(`<table width="100%" cellpadding="12" cellspacing="0" style="margin-bottom:10px;" bgcolor="${s.surface}">`
            + `<tr><td><pre style="font-family:'${s.mono}'; font-size:12px; color:${s.code};">${code.join("\n")}</pre></td></tr></table>`);
        code = null;
    }

    for (let at = 0; at < lines.length; at++) {
        const line = lines[at];
        if (code !== null) {
            if (fence(line) >= 0) flushCode();
            else code.push(dedent(line, indent));
            continue;
        }
        if (fence(line) >= 0) {
            flushPara();
            flushList();
            code = [];
            indent = fence(line);
            continue;
        }
        const heading = line.match(/^(#{1,4})\s+(.+)$/);
        if (heading) {
            flushPara();
            flushList();
            const size = [20, 18, 16, 15][heading[1].length - 1];
            out.push(`<p style="${p} font-size:${size}px;"><b>${inline(heading[2], s)}</b></p>`);
            continue;
        }
        const todo = line.match(/^\s*[-*]\s+\[([ xX])\]\s+(.*)$/);
        if (todo) {
            flushPara();
            flushList();
            out.push(`<p style="margin-top:0px; margin-bottom:4px;">${task(todo[1] !== " ", at, s)}&nbsp; ${inline(todo[2], s)}</p>`);
            continue;
        }
        const said = line.match(/^\s*&gt;\s?(.*)$/);
        if (said) {
            if (para.length) flushPara();
            flushList();
            quote.push(said[1].trim());
            continue;
        }
        const bullet = line.match(/^\s*[-*•]\s+(.*)$/);
        const number = line.match(/^\s*\d+[.)]\s+(.*)$/);
        if (bullet || number) {
            flushPara();
            const tag = bullet ? "ul" : "ol";
            if (!list || list.tag !== tag) {
                flushList();
                list = { tag: tag, items: [] };
            }
            list.items.push((bullet ?? number)[1]);
            continue;
        }
        if (!line.trim()) {
            flushPara();
            flushList();
            continue;
        }
        if (list && /^\s{2,}\S/.test(line)) {
            list.items[list.items.length - 1] += " " + line.trim();
            continue;
        }
        flushList();
        if (quote.length) flushPara();
        para.push(line.trim());
    }
    if (code !== null) flushCode();
    flushPara();
    flushList();
    return out.join("");
}

function segments(text) {
    const found = [];
    let prose = [];
    let code = null;
    let indent = 0;
    let lang = "";
    function flushProse() {
        if (prose.join("").trim() !== "")
            found.push({ kind: "text", text: prose.join("\n") });
        prose = [];
    }
    for (const line of String(text ?? "").split("\n")) {
        const at = fence(line);
        if (code !== null) {
            if (at >= 0) {
                found.push({ kind: "code", text: code.join("\n"), language: lang, open: false });
                code = null;
            } else {
                code.push(dedent(line, indent));
            }
        } else if (at >= 0) {
            flushProse();
            code = [];
            indent = at;
            lang = language(line);
        } else {
            prose.push(line);
        }
    }
    if (code !== null)
        found.push({ kind: "code", text: code.join("\n"), language: lang, open: true });
    flushProse();
    return found;
}

// The text with the task on a line ticked, or unticked: what a task's mark, task:<line>, does.
function toggled(text, line) {
    const lines = String(text ?? "").split("\n");
    const m = line >= 0 && line < lines.length ? /^(\s*[-*]\s+\[)([ xX])(\].*)$/.exec(lines[line]) : null;
    if (m === null)
        return String(text ?? "");
    lines[line] = m[1] + (m[2] === " " ? "x" : " ") + m[3];
    return lines.join("\n");
}
